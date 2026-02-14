#!/usr/bin/env python
import os
import platform
import time
import random
import traceback
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.firefox import GeckoDriverManager

class CodeLearnBot:
    """
    Bot automatizado para realizar tareas en CodeLearn.
    """
    LOGIN_URL = 'https://fun.codelearn.es'
    AUSTINS_URL = 'https://fun.codelearn.es/austins_powers/18220'
    TYPING_URL = 'https://fun.codelearn.es/typing_race'
    
    # Constantes de configuración
    TYPING_ROUNDS = 10
    
    def __init__(self):
        self.user = os.environ.get('BOT_USER')
        self.password = os.environ.get('BOT_PASSWORD')
        self.cycles = int(os.environ.get('BOT_CYCLES', 4))
        self.headless = os.environ.get('BOT_HEADLESS', 'true').lower() == 'true'
        self.driver = None

        if not self.user or not self.password:
            raise ValueError("ERROR: BOT_USER y BOT_PASSWORD deben estar definidos en las variables de entorno.")

    def _is_docker(self):
        return os.path.exists('/.dockerenv') or os.path.exists('/run/.containerenv')

    def setup_driver(self):
        """Configura e inicia el driver de Firefox."""
        options = Options()
        system_os = platform.system()
        in_docker = self._is_docker()

        print(f"Sistema detectado: {system_os} ({'Docker' if in_docker else 'Nativo'})")

        if self.headless:
            print("Modo headless ACTIVADO.")
            options.add_argument("--headless")
        else:
            if system_os == "Linux" and not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
                 print("ADVERTENCIA: No se detectó DISPLAY. Forzando headless para evitar errores.")
                 options.add_argument("--headless")
            else:
                 print("Modo headless DESACTIVADO. Intentando GUI.")

        # Argumentos para estabilidad en contenedores
        if in_docker or system_os == "Linux":
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
        
        try:
            service = FirefoxService(GeckoDriverManager().install())
            self.driver = webdriver.Firefox(service=service, options=options)
            print("Navegador iniciado correctamente.")
        except Exception as e:
            print(f"Error crítico iniciando Firefox: {e}")
            raise

    def login(self):
        """Realiza el inicio de sesión en CodeLearn."""
        if not self.driver:
            self.setup_driver()

        print(f"Iniciando sesión como: {self.user}")
        self.driver.get(self.LOGIN_URL)
        wait = WebDriverWait(self.driver, 15)

        try:
            username = wait.until(EC.presence_of_element_located((By.ID, "pc_email")))
            password = self.driver.find_element(By.ID, "pc_password")
            
            username.clear()
            username.send_keys(self.user)
            password.clear()
            password.send_keys(self.password)
            
            self.driver.find_element(By.TAG_NAME, "button").click()
            
            # Verificar que el login fue exitoso esperando a que desaparezca el formulario
            wait.until(EC.staleness_of(username))
            print("Login completado.")
            
        except Exception as e:
            print(f"Error durante el login: {e}")
            raise

    def _get_number_from_row(self, row_class):
        """Extrae el número de una fila en el juego Austins Powers."""
        try:
            row = self.driver.find_element(By.CLASS_NAME, row_class)
            digits = row.find_elements(By.TAG_NAME, "div")
            # Filtramos solo los divs que contienen dígitos
            text_num = "".join([d.text.strip() for d in digits if d.text.strip().isdigit()])
            return int(text_num) if text_num else None
        except:
            return None

    def run_austins(self):
        """Ejecuta el juego Austins Powers."""
        print("--- Iniciando Austins Powers ---")
        self.driver.get(self.AUSTINS_URL)
        wait = WebDriverWait(self.driver, 15)

        try:
            wait.until(EC.element_to_be_clickable((By.ID, "start_btn"))).click()
            
            iterations = random.randint(16, 24)
            print(f"Realizando {iterations} iteraciones.")

            for i in range(iterations):
                # Esperar a que el cursor esté presente (indica que el juego está listo)
                wait.until(EC.presence_of_element_located((By.CLASS_NAME, "cursor_here")))
                
                # Pausa humana pequeña
                time.sleep(random.uniform(0.4, 0.8))

                num1 = self._get_number_from_row("first_row")
                num2 = self._get_number_from_row("second_row")

                if num1 is None or num2 is None:
                    print(f"[{i+1}] No se pudieron leer los números, saltando...")
                    continue

                total = num1 + num2
                print(f"[{i+1}/{iterations}] Calculando: {num1} + {num2} = {total}")

                cursor = self.driver.find_element(By.CLASS_NAME, "cursor_here")
                cursor.click()
                
                active = self.driver.switch_to.active_element
                # Limpiar entrada anterior (por seguridad)
                active.send_keys(Keys.BACKSPACE * 8) 
                
                # Introducir el resultado invertido (mecánica del juego antigua?)
                # El código original usaba reversed(str(suma)). Asumimos que es correcto.
                for digit in reversed(str(total)):
                     active.send_keys(digit)
                     time.sleep(random.uniform(0.1, 0.25)) # Typing speed
                
                active.send_keys(Keys.ENTER)
                
                # Pequeña espera entre rondas
                time.sleep(random.uniform(0.5, 1.0))
                
        except Exception as e:
            print(f"Error en Austins: {e}")

    def run_typing_race(self):
        """Ejecuta el juego Typing Race."""
        print("--- Iniciando Typing Race ---")
        self.driver.get(self.TYPING_URL)
        wait = WebDriverWait(self.driver, 20)
        
        try:
            # Configuración del juego
            print("Seleccionando modo máquina...")
            # Usamos presence + execute_script que es más robusto que element_to_be_clickable + click
            modo_maquina = wait.until(EC.presence_of_element_located((By.XPATH, '//input[@value="1"]')))
            self.driver.execute_script("arguments[0].click();", modo_maquina)
            
            # Número de textos (10)
            print(f"Seleccionando {self.TYPING_ROUNDS} textos...")
            select_elem = self.driver.find_element(By.ID, "num-text")
            Select(select_elem).select_by_value(str(self.TYPING_ROUNDS))
            
            # Dificultad Easy
            print("Seleccionando dificultad Easy...")
            diff_easy = self.driver.find_element(By.XPATH, '//input[@value="easy"]')
            self.driver.execute_script("arguments[0].click();", diff_easy)
            
            # Botón Start
            print("Iniciando partida...")
            start_btn = wait.until(EC.presence_of_element_located((By.XPATH, '//a[contains(@onclick, "goToGame")]')))
            self.driver.execute_script("arguments[0].click();", start_btn)
            
            # Bucle de juego
            for t in range(self.TYPING_ROUNDS):
                print(f"Ronda {t+1}...")
                
                # Esperar a que aparezca el texto
                text_span_selector = (By.CSS_SELECTOR, "#typing-text #text span")
                wait.until(EC.presence_of_all_elements_located(text_span_selector))
                
                # Tiempo humano para "leer" el texto
                time.sleep(random.uniform(0.8, 1.5))

                chars = self.driver.find_elements(*text_span_selector)
                word = "".join([c.text for c in chars])
                
                if not word:
                    print("Texto vacío detectado.")
                    continue

                textarea = wait.until(EC.element_to_be_clickable((By.ID, "player-typed-text")))
                
                for char in word:
                    textarea.send_keys(char)
                    # Velocidad de escritura humana variable
                    time.sleep(random.uniform(0.08, 0.2))
                
                # Esperar un poco al terminar la palabra
                time.sleep(1.5)
                
        except Exception as e:
            print(f"Error en Typing Race: {e}")
            try:
                self.driver.save_screenshot("error_typing_race.png")
                print("Captura de error guardada en 'error_typing_race.png'")
            except:
                pass
            raise # Re-lanzar para que se vea el error en el log general si es necesario

    def run(self):
        """Ejecuta el ciclo principal del bot."""
        print(f"--- BOTIFLER INICIADO ({self.cycles} ciclos) ---")
        try:
            self.login()
            
            for i in range(self.cycles):
                print(f"\n>>> CICLO GLOBAL {i+1}/{self.cycles} <<<")
                
                self.run_austins()
                
                # Cooldown entre juegos (necesario por lógica del sitio o seguridad)
                delay = 90
                print(f"Descanso de seguridad ({delay}s) antes de Typing Race...")
                time.sleep(delay)
                
                self.run_typing_race()
                
                if i < self.cycles - 1:
                    pause = random.randint(5, 12)
                    print(f"Pausa aleatoria entre ciclos: {pause}s")
                    time.sleep(pause)
                    
            print("\n--- PROCESO FINALIZADO CON ÉXITO ---")
            
        except Exception as e:
            print(f"\n!!! ERROR CRÍTICO EN EJECUCIÓN: {e} !!!")
            traceback.print_exc()
        finally:
            if self.driver:
                print("Cerrando navegador...")
                self.driver.quit()
                print("Sesión cerrada.")

if __name__ == "__main__":
    try:
        bot = CodeLearnBot()
        bot.run()
    except Exception as e:
        print(f"Error de inicialización: {e}")
