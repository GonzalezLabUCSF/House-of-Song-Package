% Clear previous session data and initialize PushBullet notification
clc               % Clear command window
clf               % Clear figure window
clear             % Remove variables from workspace
% Cam M1 is 877
% Cam M2 is 878
% Cam F is 888

PushBullet = pbNotify('o.0Yzyja3vaXct6GNCk73Lcx9tpixvlmNb'); % Initialize PushBullet for notifications

% Detect available audio devices
Aduio_Info = audiodevinfo; %Audio inputs and outputs, tells you what audio devices are connected.

% Select audio input device (Script originally for Scarlett 18i20 3rd gen) - typically ID 1
ScarletteDev=audiodevinfo(1,1); %Read Audio_Info variable values, to find out what ID your audio and recording TTL pulse belongs to.
% Set default folder paths
Recording_Folder_Destination = "D:"; % Folder to store all recordings
Backup_Destination = "\\Gerriklabcomp\a"; % Optional: location to copy backup data
NPY_Drive="E:\";
Image_Height="2178";
% Recorder Scarlette 18i20 object info
Fs = 44100;    %Sampling rate
nBits = 24;     %Bits per sample
nChannels = 8;  %Number of input channels
Buffer_size=256; %Size of buffer sent by scarlette
%73.8000 is how long it takes to fully rec and rez a observation
%6.5 recs can be done a day, so 2 experimental and 4 habituation.
% Input IDS
Backup_Data_Address="C:\Users\Gerrik\Lab Dropbox\Shared_Gerrik\HOS_Recordings\"; %Update to where you want backup the raw files.
if ~isempty(dir("E:\*.npy"))
    error("Npy drive isn't empty. Check it before deleting or recording.")
end

Recording_Type=input("Is this a Signal[0], Social [1], or Habituation[2] recording? \n");
%Enter an input based on wether your recording birds interacting, letting the bird get used to the environment, or your checking your hardware's signals.
if Recording_Type==1
    Python_Input_1=1;%Set cameras to record 15 min
    Rec_Time=60*15;%Set audiodevice to record 15 min
    FID=input("What is the ID of the bird, in chamber F? \n","s");
    M1ID=input("What is the ID of the bird, in chamber M1, histology side? \n","s");
    M2ID=input("What is the ID of the bird, in chamber M2, confocal side? \n","s");
    Num_Loops=1;
    Social_Group="-F_"+FID+"_M1_"+M1ID+"_M2_"+M2ID;
elseif Recording_Type==2
    Python_Input_1=1;%Set cameras to record 15 min
    Rec_Time=60*15;%Set audiodevice to record 15 min
    if input("Male [0] or Female [1] habituation? \n")
        FID=input("What is the F ID? \n","s");
        M1ID="";
        M2ID="";
        Social_Group="-F_"+FID+"_M1__M2_";
    else
        FID="M_Habituation";
        M1ID=input("What is the M1 ID, histology side? \n","s");
        M2ID=input("What is the M2 ID, confocal side? \n","s");
        Social_Group="-F__M1_"+M1ID+"_M2_"+M2ID;
    end
    Num_Loops=4;
elseif Recording_Type==0
    Python_Input_1=0;%Set cameras to record 15 sec
    Rec_Time=15;%Set audiodevice to record 15 sec
    FID="Test";
    M1ID="";
    M2ID="";
    Num_Loops=1;
    Social_Group="-Test";
end


Cam_Script_List=["40410888_Script_V11.py","40410877_Script_V11.py","40410878_Script_V11.py"];%executable scripts to run basler cams
Microphone = audioDeviceReader(Driver='ASIO', SampleRate=48000,Device="Focusrite USB ASIO",NumChannels=8,BitDepth='24-bit integer');
for Loop_Num=1:Num_Loops
    Start_Lights=1;
    Time_Of_Rec=Cur_Date_Time();
    disp("Recording at " +Time_Of_Rec)
    if all([isempty(ls(fullfile("D:","F_"+FID,"F_"+FID+"-Aggregate_Analysis"))),FID~="M_Habituation",FID~="Test"])
        mkdir(fullfile(Recording_Folder_Destination,"F_"+FID,"F_"+FID+"-Aggregate_Analysis")) %Creates folder, where results from analysing across the bird's recordings will be stored.
    end
    File_Prefix=Time_Of_Rec+Social_Group; %Create file prefix, that contains when and who was recorded.
    if FID~="M_Habituation" && FID~="Test"
        Rec_Folder=fullfile(Recording_Folder_Destination,"F_"+FID,File_Prefix);
        mkdir(fullfile(Rec_Folder,"Analysis"))%Creates recording folder, where all data on the individual recording will be stored. Analysis folder hodls analysis results for individual recording.
    else
        Rec_Folder=fullfile(Recording_Folder_Destination,FID,File_Prefix);
        mkdir(fullfile(Rec_Folder,"Analysis"))
    end

    Start_Camera = true;
    setup(Microphone) %Init microphone
    %% Init Microphone and Signal Recording
    AM1=Rec_Folder+"/"+File_Prefix+"-Mic-M1.wav";
    AM2=Rec_Folder+"/"+File_Prefix+"-Mic-M2.wav";
    AF=Rec_Folder+"/"+File_Prefix+"-Mic-F.wav";
    SF=Rec_Folder+"/"+File_Prefix+"-Stamp.wav";
    VM1=Rec_Folder+"/"+File_Prefix+"-Cam-M1.wav";
    VM2=Rec_Folder+"/"+File_Prefix+"-Cam-M2.wav";
    VF=Rec_Folder+"/"+File_Prefix+"-Cam-F.wav";
    Mic_M1=dsp.AudioFileWriter(AM1,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    Mic_M2=dsp.AudioFileWriter(AM2,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    Mic_F=dsp.AudioFileWriter(AF,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    Stamp_File=dsp.AudioFileWriter(SF,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    CamM1=dsp.AudioFileWriter(VM1,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    CamM2=dsp.AudioFileWriter(VM2,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    CamF=dsp.AudioFileWriter(VF,SampleRate=Fs,FileFormat="WAV",DataType='int32');
    End_Light_Time=Rec_Time-3;
    END_LIGHT=1;
    tic
    while toc < Rec_Time
        if toc>End_Light_Time && END_LIGHT
            system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 0");
            END_LIGHT=0;
        elseif Start_Camera
            for Camera_Script = Cam_Script_List
                system("start C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+" "+Camera_Script+" "+Python_Input_1+" "+NPY_Drive);%Starts running a python instance for each script that is used to record frames.
            end
            Start_Camera = false;
        end
        if Start_Lights && toc>0              %turn on lights, once, 4 seconds after starting camera scripts
            Signal_Pass=0;
            F=0;
            M1=0;
            M2=0;
            while toc<8
                %For the first second, check wether there is singal coming
                %from cameras. If not, then cancel recording.
                AUD_data=Microphone();      %name side
                Mic_M1(AUD_data(:,1));      %mic1 M1
                Mic_M2(AUD_data(:,2));      %mic2 M2
                Mic_F(AUD_data(:,3));       %mic3 F
                Stamp_File(AUD_data(:,5));  %stamp
                M1=cat(1,M1,AUD_data(:,6));
                M2=cat(1,M2,AUD_data(:,7));
                F=cat(1,F,AUD_data(:,8));
                [~,M1_Locs] =findpeaks(M1,'MinPeakProminence',0.9,"MinPeakDistance",30);%GIes location of the peaks
                [~,M2_Locs] =findpeaks(M2,'MinPeakProminence',0.9,"MinPeakDistance",30);%GIes location of the peaks
                [~,F_Locs] =findpeaks(F,'MinPeakProminence',0.9,"MinPeakDistance",30);%GIes location of the peaks
                if all([~isempty(F_Locs),~isempty(M1_Locs),~isempty(M2_Locs)])&&Signal_Pass==0
                    Signal_Pass=1;
                    % CamM1(M1);       %cam 877 M1
                    % CamM2(M2);       %cam 878 M2
                    % CamF(F);       %cam 888 F
                    system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 1");
                    Start_Lights=0;
                    disp(toc+" Good signaling, recording.")
                    break
                end
            end
            if Signal_Pass==0
                disp("Bad signaling, cancelling recording. Run signal recording.")
                PushBullet.notify('Bad signaling, cancelling recording. Run signal recording.')
                break
            end
        end
        AUD_data=Microphone();      %name side
        Mic_M1(AUD_data(:,1));      %mic1 M1
        Mic_M2(AUD_data(:,2));      %mic2 M2
        Mic_F(AUD_data(:,3));       %mic3 F
        Stamp_File(AUD_data(:,5));  %stamp
        CamM1(AUD_data(:,6));       %cam 877 M1
        CamM2(AUD_data(:,7));       %cam 878 M2
        CamF(AUD_data(:,8));       %cam 888 F
    end
    release(Mic_M1);
    release(Mic_M2);
    release(Mic_F);
    release(Stamp_File);
    release(CamM1);
    release(CamM2);
    release(CamF);
    if Python_Input_1==1
        PushBullet.notify('HOS done recording');
    end
    if Recording_Type==2
        system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"GOVEE_CONTROL_V2.py 1")
    end
    system("C:\Users\Gerrik\anaconda3\envs\DLC3\python.exe "+"PY_2_MP4_V13.py "+Rec_Folder+" "+File_Prefix+" "+NPY_Drive+" "+Image_Height); %Begin transforming the raw files to mp4.
    %% Backup all wav files from Recording Folder to gerriklabcomp
    if Backup_Destination~=""
        [M12,FS]=audioread(VM1);
        audiowrite(VM1,cat(1,M1,M12),FS)
        [M22,FS]=audioread(VM2);
        audiowrite(VM2,cat(1,M2,M22),FS)
         [F2,FS]=audioread(VF);
        audiowrite(VF,cat(1,F,F2),FS)
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
        Videos=string(ls(fullfile(Rec_Folder,"*.mp4")));
        for k=1:numel(Videos)
            copyfile(fullfile(Rec_Folder,Videos{k}),Copy_Destination)
        end

    end
    delete(NPY_Drive+"\*.npy")
    Check_Signal_File=Check_Signal_View(File_Prefix,Stamp_File.Filename,Rec_Folder,Videos);
    copyfile(Check_Signal_File,Copy_Destination)
end

% if Recording_Type==0
%     Check_Signal_View()
% end

PushBullet.notify('HOS done rendering');
function Check_Signal_File=Check_Signal_View(File_Prefix,Stamp_File,Obs_Folder,Videos) %Sids project
clf
MMF = memmapfile(Stamp_File, ...
    'Offset', 0, ...
    'Format', 'int32', ...
    'Writable', false);
Master_Data= MMF.Data; %file data
Equipment_Sig=Find_spikes(double(Master_Data(48000*3:48000*5)));
nexttile
plot(Equipment_Sig)
title("Stamp ",File_Prefix)
hold on
[Val,Master_Locs] =findpeaks(Equipment_Sig,'MinPeakProminence',1*10e8,"MinPeakDistance",30);%GIes location of the peaks
scatter(Master_Locs,Val)
disp("#(peaks) on stamp file, should be about 41fps with about 1,968 sample distance between pings. Stamp file avg sample distance difference is:")
disp(mean(diff(Master_Locs)))
subtitle("avg sample dist diff:"+mean(diff(Master_Locs)))
hold off
% Load camera_signal
Signal_Files=Obs_Folder+"/"+string(ls(Obs_Folder+"/*-Cam-*.wav"));
File_List=cell(7,length(Signal_Files));
for III=1:length(Signal_Files) %For each camera signal file, save file name and a data pointer to File List row 1 and 2
    File_Name=Signal_Files(III);
    View=split(Signal_Files(III),"-");
    File_List{1,III}=View(end); %file name
    MMF = memmapfile(File_Name, ...
        'Offset', 0, ...
        'Format', 'int32', ...
        'Writable', false);
    File_List{2,III} = MMF.Data; %file data
    Equipment_Sig=double(MMF.Data(48000*3:48000*5));
    Equipment_Sig=Find_spikes(Equipment_Sig);
    nexttile
    plot(Equipment_Sig)
    title(File_List{1,III})
    hold on
    [Val,loc] =findpeaks(Equipment_Sig,'MinPeakProminence',3*10e7,"MinPeakDistance",40);%GIes location of the peaks
    if isempty(Val)||isempty(loc)
        Bad_Note=fopen(Obs_Folder+"/Bad_ttl_Sig.txt",'w');
        fwrite(Bad_Note,"Bad ttl signaling \n");
        fclose(Bad_Note);
        continue
    end
    scatter(loc,Val)
    subtitle("avg sample dist diff:"+mean(diff(loc)))
    hold off
end

for I = 1:numel(Videos)
    Master_Frames=["Frame_Correction_Master-F.mat","Frame_Correction_Master-M1V3.mat","Frame_Correction_Master-M2V3.mat"];
    Letters=["F","M1","M2"];
    load(Master_Frames(I),'Master_Frame')
    Read_Cam= VideoReader(fullfile(Obs_Folder,Videos(I))); %Read Cam-Letter.mp4
    Frame = read(Read_Cam, 400); % 500th frame of Cam-Letter.mp4
    Frame= imresize(Frame,[1002,1776]); % Resize video frame to whats accepted by Deep Lab Cut
    Frame = rgb2gray(Frame);
    nexttile
    image(Master_Frame)
    title("Master Frame "+Letters(I))

    nexttile
    image(Frame) % Show comparison of images before shift
    title("Unshifted "+Letters(I))

    % saveas(gcf,fullfile(Analysis_Folder,File_Prefix+"-Alignment_Preshift-"+Letter+".svg"),'svg')
    correlation = normxcorr2(Master_Frame, Frame);
    [~, max_index] = max(abs(correlation(:)));
    [ypeak, xpeak] = ind2sub(size(correlation), max_index(1));
    Fy_offset = ypeak - size(Master_Frame, 1);
    Fx_offset = xpeak - size(Master_Frame, 2);
    Frame=imtranslate(Frame, [-Fx_offset, -Fy_offset]);
    nexttile
    image(Frame)  % Show comparison of images after shift
    title("Shifted "+Letters(I))

end
Check_Signal_File=fullfile(Obs_Folder,"Analysis",File_Prefix+"-Alignment_Signal_N_Shift.png");
saveas(gcf,Check_Signal_File,'png')
end