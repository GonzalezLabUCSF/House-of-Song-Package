import requests, sys

url = "https://developer-api.govee.com/v1/devices/control"
API_key="409400c5-0358-435a-b014-f375d1131c7a"
device1="8A:0C:60:74:F4:8F:83:30"
device2="FF:64:60:74:F4:83:E0:C4"
# The 429 error is API request limiting from Govee. They recently introduced new limitations of:
# 10000 requests per day per user
# 10 device requests (polling and controlling) per minute
def control_outlet(api_key, device_id, device_model, command):
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
api_key = "409400c5-0358-435a-b014-f375d1131c7a"
device_model = 'H5082'

for device_ID in [device1,device2]:
# Commands to turn off both outlets
    if sys.argv[1]=="1":
        commands = ['0_1', '1_1']
    elif sys.argv[1]=="0":
        commands = ['0_0', '1_0']
    for command in commands:
        control_outlet(api_key, device_ID, device_model, command)

    # get_device_status(api_key, device_ID, device_model)

