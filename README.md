# House-of-Song-Package
The finished House of Song Package, to be used in house. Track birds, when males sing, and analyze the data.
Download the full package, and keep it all in a single folder somewhere on you computer that your either recording the data on or processing the recordings.

HOS_Chimera_Record is what you use to record birds in the HOS, which uses Govee_Control_V2, Cur_Date_Time, the .pfs files specific to your cameras, the _Script.py specific to your computer.

Find_Next_Need_Master will go through all your cohort, bird, then recording folders and check that each video is requires less than a 300 pixel shift before DLC processing. If it needs it, it will make a new master view file. If its a side view that needs correction, it will ask you to create rectangles where Bird F or M are perching, to create a new perching filter for the date of recording and all future recordings are less than 300 pixels shifted.

Temporal_Loom will sync all the videos together based on a central TTL pulse, shift correct each video's frame, correct the audio, generate videos for applying deep lab cut to, then generate a video and h5 file of tracking the birds. Then it will clean the data, to find where the birds were, when they perched, and when they sang. Out put is a single h5 file, for analysis.

Chimera_Figure_Dancer takes the H5 files of each individual recording, and creates "figures" to show where the birds flew, when they sang, and their conditions of when they perched or sang. UNDER CONSTRUCTION. Returns another h5 file of histogram and other analysis data.

[Not yet created] take the analysis data of figure dancer, and creates summary figures for each bird, across birds within cohort, and then across cohorts to show patterns across birds... Please choose ornithological name related to a mythos for naming. Or... Gerrik Graphs...
