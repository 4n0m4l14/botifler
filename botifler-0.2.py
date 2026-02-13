#!/usr/bin/env python
import os
from random import randint
from time import sleep

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from webdriver_manager.firefox import GeckoDriverManager

def setupDriver():
    options = Options()
    options.add_argument("--headless") # Modo oculto activado para Docker
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    
    service = FirefoxService(GeckoDriverManager().install())
    driver = webdriver.Firefox(service=service, options=options)
    return driver

def login(driver):
    login_url = 'https://fun.codelearn.es'
    user = os.environ.get('BOT_USER')
    passwd = os.environ.get('BOT_PASSWORD')

    if not user or not passwd:
        raise ValueError("BOT_USER y BOT_PASSWORD deben estar definidos en las variables de entorno.")

    print(f"Iniciando sesión con el usuario: {user}")
    
    driver.get(login_url)
    wait = WebDriverWait(driver, 10)
    
    username = wait.until(EC.presence_of_element_located((By.ID, "pc_email")))
    password = driver.find_element(By.ID, "pc_password")
    
    username.send_keys(user)
    password.send_keys(passwd)
    driver.find_element(By.TAG_NAME, "button").click()

def austins(driver):
    print("Iniciando Austins Powers...")
    driver.get("https://fun.codelearn.es/austins_powers/18220")
    wait = WebDriverWait(driver, 10)
    
    try:
        wait.until(EC.element_to_be_clickable((By.ID, "start_btn"))).click()
        
        # Determine number of iterations randomly between 14 and 21
        iterations = randint(16, 24)
        print(f"Se realizarán {iterations} iteraciones en Austins.")

        for i in range(iterations):
            wait.until(EC.presence_of_element_located((By.CLASS_NAME, "cursor_here")))
            sleep(0.5) 
            def get_number_from_row(row_class):
                try:
                    row = driver.find_element(By.CLASS_NAME, row_class)
                    digits = row.find_elements(By.TAG_NAME, "div")
                    num_str = "".join([d.text.strip() for d in digits if d.text.strip().isdigit()])
                    if not num_str:
                        return None
                    return int(num_str)
                except Exception:
                    return None

            first_number = get_number_from_row("first_row")
            second_number = get_number_from_row("second_row")

            if first_number is None or second_number is None:
                print("Error leyendo números, reintentando...")
                continue

            suma = first_number + second_number
            print(f"Calculando: {first_number} + {second_number} = {suma}")

            cursor = driver.find_element(By.CLASS_NAME, "cursor_here")
            cursor.click()
            active = driver.switch_to.active_element

            for _ in range(8): 
                active.send_keys(Keys.BACKSPACE)

            for digit in reversed(str(suma)):
                active.send_keys(digit)
                sleep(0.3)
            
            active.send_keys(Keys.ENTER)

            sleep(0.5)
    except Exception as e:
        print(f"Error en Austins: {e}")

def typingRace(driver):
    print("Configurando Typing Race...")
    driver.get("https://fun.codelearn.es/typing_race")
    wait = WebDriverWait(driver, 15)

    try:
        modo_maquina = wait.until(EC.presence_of_element_located((By.XPATH, '//input[@value="1"]')))
        driver.execute_script("arguments[0].click();", modo_maquina)

        select_num = Select(driver.find_element(By.ID, "num-text"))
        select_num.select_by_value("10")

        diff_easy = driver.find_element(By.XPATH, '//input[@value="easy"]')
        driver.execute_script("arguments[0].click();", diff_easy)

        start_btn = wait.until(EC.element_to_be_clickable((By.XPATH, '//a[contains(@onclick, "goToGame")]')))
        start_btn.click()
        
        for t in range(10):
            print(f"Esperando texto {t+1}...")
            
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#typing-text #text span")))
            sleep(1.2)

            chars = driver.find_elements(By.CSS_SELECTOR, "#typing-text #text span")
            palabra_completa = "".join([c.text for c in chars])
            
            if not palabra_completa:
                print("Texto vacío, reintentando...")
                sleep(1)
                continue

            textarea = wait.until(EC.element_to_be_clickable((By.ID, "player-typed-text")))
            
            for letra in palabra_completa:
                textarea.send_keys(letra)
                # Reduced sleep slightly for headless efficiency, but kept human-like
                sleep(randint(6, 9) / 60) 
            
            sleep(2) 

    except Exception as e:
        print(f"Error detectado en Typing Race: {e}")
        driver.save_screenshot("debug_typing.png") 

def get_cycles():
    try:
        return int(os.environ.get('BOT_CYCLES', 4))
    except ValueError:
        return 4

# --- EJECUCIÓN ---
if __name__ == "__main__":
    n_ciclos = get_cycles()
    print(f"Configurado para ejecutar {n_ciclos} ciclos.")
    
    driver = None
    try:
        driver = setupDriver()
        login(driver)

        for i in range(n_ciclos):
            print(f"Iniciando ciclo {i+1} de {n_ciclos}")
            austins(driver)
            sleep(90)
            typingRace(driver)
            print(f"Ciclo {i+1} completado.")
            if i < n_ciclos - 1:
                sleep(randint(5, 10))
        
        print("Proceso finalizado con éxito.")
    except Exception as e:
        print(f"Error fatal: {e}")
    finally:
        if driver:
            print("Cerrando navegador...")
            driver.quit()
