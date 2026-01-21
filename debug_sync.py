import sys
import logging
from withings_sync.sync import main, ARGS

# Set up logging to see what's happening
logging.basicConfig(level=logging.DEBUG, format='%(name)s - %(levelname)s - %(message)s')

print(f"Python version: {sys.version}")
print(f"ARGS.config_folder: {ARGS.config_folder}")
print(f"ARGS.verbose: {ARGS.verbose}")
print(f"ARGS.fromdate: {ARGS.fromdate}")
print(f"ARGS.garmin_username: {ARGS.garmin_username}")

# Try to call main
try:
    result = main()
    print(f"Main returned: {result}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
