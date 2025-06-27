import  os, cv2, sys
from imageio import get_writer
import numpy as NPY
from fnmatch import fnmatch as FN
#cam serial num        #876 #877 878 888
Image_Height=int(sys.argv[4]) #Change based on what image height your using.
NPY_Drive=sys.argv[3]
def create_writer(writer_path):
    # print("Writing to "+writer_path+" "+str(datetime.datetime.now()))
    writer=get_writer(writer_path,format="FFMPEG",mode="I",codec="h264",fps=41,macro_block_size=None)
    return writer

os.chdir("C:/Users/Gerrik/Downloads/ffmpeg-master-latest-win64-gpl/FFmpeg/bin")
Recording_Folder=sys.argv[1]
DIRECTORY=[]

for file in os.listdir(NPY_Drive):
    if FN (file, '*.npy'):
        DIRECTORY.append(file)

for NPY_f in DIRECTORY:
    NPY_array=NPY.load(NPY_Drive+NPY_f,"r")
    mp4_file:str=NPY_f.replace("npy","mp4")
    Final_Path:str=Recording_Folder+"/"+sys.argv[2]+mp4_file
    writer=create_writer(Final_Path)
    y:str=NPY.split(NPY_array,NPY.shape(NPY_array)[0]/Image_Height)
    for array in y:
        array2=cv2.cvtColor(array,cv2.COLOR_BAYER_RG2BGR)
        writer.append_data(array2)
    writer.close()
    print(f"done writing, {Final_Path}")
print("Finished converting NPY to MP4.")