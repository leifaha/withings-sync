import dotenv
import os

result = dotenv.load_dotenv()
print(f'dotenv.load_dotenv() returned: {result}')
print(f'GARMIN_USERNAME: {os.getenv("GARMIN_USERNAME")}')
print(f'GARMIN_PASSWORD: {os.getenv("GARMIN_PASSWORD")}')
print(f'Working dir: {os.getcwd()}')
print(f'.env file exists: {os.path.exists(".env")}')
