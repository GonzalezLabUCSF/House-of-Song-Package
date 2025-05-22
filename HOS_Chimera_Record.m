% Clear previous session data and initialize PushBullet notification
clc               % Clear command window
clf               % Clear figure window
clear             % Remove variables from workspace

PushBullet = pbNotify('o.0Yzyja3vaXct6GNCk73Lcx9tpixvlmNb'); % Initialize PushBullet for notifications

% Detect available audio devices
Aduio_Info = audiodevinfo; %Audio inputs and outputs, tells you what audio devices are connected.

% Select audio input device (Script originally for Scarlett 18i20 3rd gen)
% - typically ID 1
ScarletteDev=audiodevinfo(1,1); %Read Audio_Info variable values, to find out what ID your audio and recording TTL pulse belongs to.
% Set default folder paths
Recording_Folder_Destination = ""; % Folder to store all recordings
Backup_Destionation = ""; % Optional: location to copy backup data
NPY_Drive=""; %Location where raw frames will be stored. I suggest a SSD drive, 2 TB at least.
Image_Height=""; %How Tall, in pixels, each raw frame is. Can see in pylon viewer.
Backup_Destination=""; %Where all information in the Recording folder is copied to, in a backup memory drive.

% Audio recording parameters. Update based on rig.
Fs = 44100;       % Sampling rate in Hz
nBits = 24;       % Bit depth
nChannels = 8;    % Number of audio input channels
Buffer_size = 256; % Buffer size

% Ask user to specify recording type.

%Enter an input based on wether your recording birds interacting, letting
%the bird get used to the environment, or your checking your hardware's
%signals.
Recording_Type=input("Is this a Signal[0], Social [1], or Habituation[2] recording? \n");

% === Configure settings based on recording type ===
if Recording_Type==1
    % Social interaction: record for 15 min
    Python_Input_1=1; %Set cameras to record 15 min
    Rec_Time=60*15; %Set audiodevice to record 15 min
    FID=input("What is the ID of the bird, in chamber F, ID? \n","s");
    M1ID=input("What is the ID of the bird, in chamber M1, ID? \n","s");
    M2ID=input("What is the ID of the bird, in chamber M2, ID? \n","s");
    Num_Loops=1; %Number of times the setup will record
    Social_Group="-F_"+FID+"_M1_"+M1ID+"_M2_"+M2ID;

elseif Recording_Type==2
    % Habituation: 4 repetitions of 15-min recordings
    Python_Input_1=1; %Set cameras to record 15 min
    Rec_Time=60*15; %Set audiodevice to record 15 min
    if input("Male [0] or Female [1] habituation? \n")
        FID=input("What is the F ID? \n","s");
        M1ID="";
        M2ID="";
        Social_Group="-F_"+FID+"_M1__M2_";
    else
        FID="M_Habituation";
        M1ID=input("What is the M1 ID? \n","s");
        M2ID=input("What is the M2 ID? \n","s");
        Social_Group="-F__M1_"+M1ID+"_M2_"+M2ID;
    end
    Num_Loops=4; %Number of times the setup will record

elseif Recording_Type==0
    % Signal testing: record for 15 seconds
    Python_Input_1=0;%Set cameras to record 15 sec
    Rec_Time=15;%Set audiodevice to record 15 sec
    FID="Test";
    M1ID="";
    M2ID="";
    Num_Loops=1; %Number of times the setup will record
    Social_Group="-Test";
end

% List of Python camera scripts to launch (one per basler camera,named after their serial number)
Cam_Script_List=["40410877_Script_V11.py","40410878_Script_V11.py","40410888_Script_V11.py"];

% Initialize multi-channel microphone (Scarlett ASIO device)
Microphone = audioDeviceReader(Driver='ASIO', SampleRate=48000,Device="Focusrite USB ASIO",NumChannels=8,BitDepth='24-bit integer');

% === Start recording loop ===
for Loop_Num=1:Num_Loops
    Start_Lights = 1; % Track light control
    Time_Of_Rec = Cur_Date_Time(); % Timestamp recording
    disp("Recording at " + Time_Of_Rec)

    % Create aggregate analysis folder for the focal bird if needed
    if all([isempty(ls(fullfile("D:","F_"+FID,"F_"+FID+"-Aggregate_Analysis"))),FID~="M_Habituation",FID~="Test"])

        %Creates folder, where results from analysing across the bird's recordings will be stored.
        mkdir(fullfile(Recording_Folder_Destination,"F_"+FID,"F_"+FID+"-Aggregate_Analysis"))
    end

    % Define folder for this recording
    File_Prefix = Time_Of_Rec + Social_Group;
    if FID ~= "M_Habituation" && FID ~= "Test"
        Rec_Folder = fullfile(Recording_Folder_Destination, "F_" + FID, File_Prefix);
    else
        Rec_Folder = fullfile(Recording_Folder_Destination, FID, File_Prefix);
    end
    mkdir(fullfile(Rec_Folder, "Analysis")); % Folder for individual analysis


    Start_Camera = true;
    setup(Microphone) %Init microphone
    % === Define audio file output paths ===
    AM1 = Rec_Folder + "/" + File_Prefix + "-Mic-M1.wav";
    AM2 = Rec_Folder + "/" + File_Prefix + "-Mic-M2.wav";
    AF  = Rec_Folder + "/" + File_Prefix + "-Mic-F.wav";
    SF  = Rec_Folder + "/" + File_Prefix + "-Stamp.wav";
    VM1 = Rec_Folder + "/" + File_Prefix + "-Cam-M1.wav";
    VM2 = Rec_Folder + "/" + File_Prefix + "-Cam-M2.wav";
    VF  = Rec_Folder + "/" + File_Prefix + "-Cam-F.wav";

    % Initialize audio writers for each channel
    Mic_M1 = dsp.AudioFileWriter(AM1, SampleRate=Fs, FileFormat="WAV", DataType='int32');
    Mic_M2 = dsp.AudioFileWriter(AM2, SampleRate=Fs, FileFormat="WAV", DataType='int32');
    Mic_F  = dsp.AudioFileWriter(AF,  SampleRate=Fs, FileFormat="WAV", DataType='int32');
    Stamp_file = dsp.AudioFileWriter(SF, SampleRate=Fs, FileFormat="WAV", DataType='int32');
    CamM1 = dsp.AudioFileWriter(VM1, SampleRate=Fs, FileFormat="WAV", DataType='int32');
    CamM2 = dsp.AudioFileWriter(VM2, SampleRate=Fs, FileFormat="WAV", DataType='int32');
    CamF  = dsp.AudioFileWriter(VF,  SampleRate=Fs, FileFormat="WAV", DataType='int32');

    End_Light_Time = Rec_Time - 3; % Lights off 3 seconds before end
    tic
    END_LIGHT = 1;

    while toc < Rec_Time
        AUD_data = Microphone(); % Capture audio frame
        Mic_M1(AUD_data(:,1));   % Write M1 mic channel
        Mic_M2(AUD_data(:,2));   % Write M2 mic channel
        Mic_F(AUD_data(:,3));    % Write F mic channel
        Stamp_file(AUD_data(:,5)); % Write timestamp TTL channel
        CamM1(AUD_data(:,6));    % Camera M1 audio TTL
        CamF(AUD_data(:,7));     % Camera F audio TTL
        CamM2(AUD_data(:,8));    % Camera M2 audio TTL

        % Turn off lights near end of session
        if toc>End_Light_Time && END_LIGHT
            system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 0");
            END_LIGHT=0;

            % Turn on lights 4 seconds after recording begins
        elseif toc>4 && Start_Lights
            system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 1"); %Turn on the lights in the room.
            Start_Lights=0;
        end

        % Start camera recordings by launching Python scripts
        if Start_Camera
            for Camera_Script = Cam_Script_List
                system("start C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+" "+Camera_Script+" "+Python_Input_1+" "+NPY_Drive)%Starts running a python instance for each script that is used to record frames.
            end
            Start_Camera = false;
        end
    end

    % Stop all audio writers
    release(Mic_M1); release(Mic_M2); release(Mic_F);
    release(Stamp_file); release(CamM1); release(CamM2); release(CamF);

    % Notify recording completion
    if Python_Input_1==1
        PushBullet.notify('HOS done recording');
    end

    % Restore light for habituation recordings
    if Recording_Type==2
        system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 1")
    end

    % Convert .wav to .mp4 using external script
    system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"PY_2_MP4_V13.py "+Rec_Folder+" "+File_Prefix+" "+NPY_Drive+" "+Image_Height); %Begin transforming the raw files to mp4.

    % === Backup audio files to Dropbox ===
    if Backup_Destination~=""
        if FID~="M_Habituation" && FID~="Test"
            Copy_Destination=fullfile(Backup_Destination,"F_"+FID,File_Prefix);
        else
            Copy_Destination=fullfile(Backup_Destination,FID,File_Prefix);
        end
        mkdir(Copy_Destination)
        copyfile(AM1,Copy_Destination);
        copyfile(AM2,Copy_Destination);
        copyfile(AF,Copy_Destination);
        copyfile(SF,Copy_Destination);
        copyfile(VM1,Copy_Destination);
        copyfile(VM2,Copy_Destination);
        copyfile(VF,Copy_Destination);
    end

    % === Backup MP4 files ===
    copyfile(fullfile(Rec_Folder,File_Prefix+"-Cam-F.mp4"),Copy_Destination);
    copyfile(fullfile(Rec_Folder,File_Prefix+"-Cam-M1.mp4"),Copy_Destination);
    copyfile(fullfile(Rec_Folder,File_Prefix+"-Cam-M2.mp4"),Copy_Destination);

    % Clear any temporary files
    delete(NPY_Drive+"\*")
end

% Final notification when all rendering is complete
PushBullet.notify('HOS done rendering');


function Check_Signal_View(Date_Prefix,Stamp_File) %Sids project
tiledlayout(2,4)
Letters=["F","M1","M2"];
FileID = fopen(Stamp_File, 'r');
MMF = memmapfile(Stamp_File, ...
    'Offset', 0, ...
    'Format', 'int32', ...
    'Writable', false);
Master_Data= MMF.Data; %file data
fclose(FileID);
%%Plot master data to check.
Equipment_Sig=Find_spikes(double(Master_Data(48000*8:48000*10)));
tiledlayout(3,4)
nexttile
plot(Equipment_Sig)
set(gcf, 'Position', get(0, 'Screensize'))
title("stamp",Date_Prefix)
hold on
[Val,Master_Locs] =findpeaks(Equipment_Sig,'MinPeakProminence',1*10e8,"MinPeakDistance",30);%GIes location of the peaks
scatter(Master_Locs,Val)
disp("#(peaks) on stamp file, should be about 41fps with about 1,968 sample distance between pings. Stamp file avg sample distance difference is:")
disp(mean(diff(Master_Locs)))
subtitle("avg sample dist diff:"+mean(diff(Master_Locs)))
hold off
Equipment_Sig=Find_spikes(double(Master_Data));
[~,Master_Locs] =findpeaks(Equipment_Sig,'MinPeakProminence',1*10e8,"MinPeakDistance",30);%GIes location of the peaks
% Load camera_signal
Signal_Files=Obs_Folder+"/"+string(ls(Obs_Folder+"/*-Cam-*.wav"));
Video_Files=Obs_Folder+"/"+string(ls(Obs_Folder+"/*-Cam-*.mp4"))
File_List=cell(7,length(Signal_Files));
for III=1:length(Signal_Files) %For each camera signal file, save file name and a data pointer to File List row 1 and 2
    File_Name=Signal_Files(III);
    View=split(Signal_Files(III),"/");
    File_List{1,III}=View(2); %file name
    % FileID = fopen(File_Name, 'r');
    MMF = memmapfile(File_Name, ...
        'Offset', 0, ...
        'Format', 'int32', ...
        'Writable', false);
    File_List{2,III} = MMF.Data; %file data
    % fclose(FileID);
    Equipment_Sig=double(MMF.Data(48000*8:48000*12));
    Equipment_Sig=Find_spikes(Equipment_Sig);
    nexttile
    plot(Equipment_Sig)
    title(File_List{1,III})
    hold on
    [Val,loc] =findpeaks(Equipment_Sig,'MinPeakProminence',3*10e7,"MinPeakDistance",40);%GIes location of the peaks
    if isempty(Val)||isempty(loc)
        Bad_Note=fopen(Obs_Folder+"/Note.txt",'w');
        fwrite(Bad_Note,"Bad ttl signaling \n");
        fclose(Bad_Note);
        continue
    end
    scatter(loc,Val)
    subtitle("avg sample dist diff:"+mean(diff(loc)))
    hold off
    nexttile(III+5)
    image()
    Letter=Letters(Letter_Num);
    disp(Letter)
    %Todo: Rename variables in master frame files to Master frame

    load(Master_Frames(Letter_Num),'Master_Frame')
    Audio_Locs = TTL_Global(:,1);
    Audio_Locs = Master_Locs(Audio_Locs);
    Locs_Dev = diff(Audio_Locs);
    disp(['Median audio sample per frame interval is ' mat2str(median(Locs_Dev))])
    Locs_Linear = min(Audio_Locs):max(cumsum(Locs_Dev));
    %memory map original microphone data
    FrameRate=48000/median(diff(Master_Locs(TTL_Global(:,1))));
    Read_Cam= VideoReader(Name_Existance_Table{1}{2,Letter}); %Read Cam-Letter.mp4
    %Todo: Rename variables in master frame files to Master frame
    Frame = read(Read_Cam, 2000); % 500th frame of Cam-Letter.mp4
    Frame= imresize(Frame,[1002,1776]); % Resize video frame to whats accepted by Deep Lab Cut
    Frame = rgb2gray(Frame);
    imshowpair(Master_Frame,Frame,"montage") % Show comparison of images before shift
    Correlation = normxcorr2(Master_Frame, Frame);
    [~, max_index] = max(abs(Correlation(:)));
    [ypeak, xpeak] = ind2sub(size(Correlation), max_index(1));
    Fy_offset = (ypeak - size(Master_Frame, 1))/ size(Master_Frame, 1);
    Fx_offset = (xpeak - size(Master_Frame, 2))/ size(Master_Frame, 2);
end
saveas(gcf,fullfile(Analysis_Folder,File_Prefix+"-Cam_Signal_Alignment.png"))
end
