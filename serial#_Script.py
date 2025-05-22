from pypylon import pylon, genicam  # Libraries for interfacing with Basler cameras
import time, datetime               # For timekeeping
from npy_append_array import NpyAppendArray as NAA  # Efficiently appending to .npy files
import sys                          # For accessing command-line arguments

# === Set recording duration based on input argument ===
# If argument is '1' → full experiment (15 minutes), else short test (15 seconds)
if sys.argv[1] == '1':
    Rec_Time = 60 * 15  # 15 minutes
else:
    Rec_Time = 15       # 15 seconds

# === Function to continuously record frames from the camera ===
def record_cam(CAMERA,file_raw,Rec_Time):
    record_time=Rec_Time+time.time()    # Compute end timestamp
    with NAA(file_raw,False) as NPY_File:   # Compute end timestamp
        while time.time()<record_time:
            try:
                grabResult= CAMERA.RetrieveResult(23,pylon.TimeoutHandling_ThrowException)
                if grabResult.GrabSucceeded():  # Frame successfully captured
                     NPY_File.append(grabResult.Array)  # Append frame to file
                     grabResult.Release()  # Free memory for next grab
                     continue
                else:
                     continue
            except:
                continue    # Skip frame if any error occurs

# === Function to locate and initialize a specific camera by serial number ===
def Find_My_Cam():
    info = pylon.DeviceInfo()
    info.SetSerialNumber("") #Change to you basler camera serial number. # Hardcoded serial number of target camera
    camera = pylon.InstantCamera(pylon.TlFactory.GetInstance().CreateFirstDevice(info))
    camera.Open()

    # Load camera settings from persistent configuration file
    camera_name=str(camera.GetDeviceInfo().GetModelName())+"_"+str(camera.GetDeviceInfo().GetSerialNumber())
    nodeFile=f"{camera_name}.pfs" # Camera configuration file name, which will be the model and serial number.
    pylon.FeaturePersistence.Load(nodeFile, camera.GetNodeMap(), True)
    print("Found device "+ camera_name)
    return camera

# === Main script logic ===
Camera = Find_My_Cam()  # Locate and connect to camera
print("Cam Recording")
Camera.StartGrabbing(pylon.GrabStrategy_OneByOne)  # Start frame acquisition

# Construct output filename for raw video data
File_Raw = sys.argv[2] + "-Cam-M1.npy"
print(File_Raw)

# Begin recording for specified duration
record_cam(Camera, File_Raw, Rec_Time)
print("done recording")

# Clean up and close camera
Camera.Close()