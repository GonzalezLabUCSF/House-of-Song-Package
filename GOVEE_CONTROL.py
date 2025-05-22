import requests, sys  # requests for HTTP API calls, sys for reading command-line arguments

# Govee API endpoint for controlling devices
url = "https://developer-api.govee.com/v1/devices/control"

# API credentials and device IDs
API_key = ""
device1 = ""  # First outlet/device MAC address


# === NOTE ===
# The 429 error is API request limiting from Govee. They recently introduced new limitations of:
# 10000 requests per day per user
# 10 device requests (polling and controlling) per minute

# === Function to send a control command to a specific device ===
def Control_Outlet(api_key, device_id, device_model, command):
    url = 'https://developer-api.govee.com/v1/devices/control'
    
    headers = {
        'Content-Type': 'application/json',
        'Govee-API-Key': api_key
    }

    data = {
        'device': device_id,
        'model': device_model,
        'cmd': {
            'name': "toggle",
            'value': command
        }
    }
    response = requests.put(url, headers=headers, json=data)
    
# Replace with your actual API key, device ID, and device model
api_key = ""
device_model = ''

for device_ID in [device1]:
# Commands to turn off both outlets
    if sys.argv[1]=="1":
        commands = ['0_1', '1_1']
    elif sys.argv[1]=="0":
        commands = ['0_0', '1_0']
    for command in commands:
        Control_Outlet(api_key, device_ID, device_model, command)

    # get_device_status(api_key, device_ID, device_model)

