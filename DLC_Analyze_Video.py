import deeplabcut, sys
Destination_Folder=sys.argv[1]
if sys.argv[2]!="Empty":
    config_file=r"A:/HOS_Package_V4/F_View_V3-Gerrik-2025-06-06/config.yaml"
    deeplabcut.analyze_videos(config=config_file,videos=[sys.argv[2]],shuffle=3,in_random_order=False,save_as_csv=False,destfolder=Destination_Folder,allow_growth=True)
    if sys.argv[5] == "1":
        deeplabcut.create_labeled_video(config=config_file,videos=[sys.argv[2]],shuffle=3,destfolder=Destination_Folder)

if sys.argv[3]!="Empty":
    config_file=r"A:/HOS_Package_V4/M1_View_V2-Gerrik-2025-03-14/config.yaml"
    deeplabcut.analyze_videos(config=config_file,videos=[sys.argv[3]],shuffle=3,in_random_order=False,save_as_csv=False,destfolder=Destination_Folder,allow_growth=True)
    if sys.argv[5]=="1":
        deeplabcut.create_labeled_video(config=config_file,videos=[sys.argv[3]],shuffle=3,destfolder=Destination_Folder)

if sys.argv[4]!="Empty":
    config_file=r"A:/HOS_Package_V4/M2_View_V2-Gerrik-2025-03-27/config.yaml"
    deeplabcut.analyze_videos(config=config_file,videos=[sys.argv[4]],shuffle=3,in_random_order=False,save_as_csv=False,destfolder=Destination_Folder,allow_growth=True)
    if sys.argv[5]=="1":
        deeplabcut.create_labeled_video(config=config_file,videos=[sys.argv[4]],shuffle=3,destfolder=Destination_Folder)