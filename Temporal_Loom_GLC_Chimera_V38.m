%% Step 1 clear all, init variables and notifier
clear
clc
clf
close all
%buffer size 1024
Cohort_Dir="A:\HOS_Cohorts\Cohort_*";
disp("Step Zero Constants init")
[Letters,Python_Env,Create_Annotated_Videos]=Part_Zero();%Setup init variables.

%Requires the ffmpeg.exe to be on your PATH variable in environment
%variables in windows. Find equivalent in mac.
Cohort_Folders=dir(Cohort_Dir);
for C=2:size(Cohort_Folders,1) %Which cohort we are looking a
    disp(Cohort_Folders(C).name)
    Female_Folders=dir(fullfile(Cohort_Folders(C).folder,Cohort_Folders(C).name,"F*"));
    for I=1:size(Female_Folders,1) %Which female we are looking at
        Exp_Folders=dir(fullfile(Female_Folders(I).folder,Female_Folders(I).name,"20*")); %Discover all folders in the Female folder
        Exp_Folders(~[Exp_Folders(:).isdir])=[];
        disp(Female_Folders(I).name)
        for II=20:size(Exp_Folders,1)
            Obs_Folder= fullfile(Exp_Folders(II).folder,Exp_Folders(II).name); % Current observation folder address.
            Analysis_Folder= fullfile(Obs_Folder,"Analysis");                   % Current observation folder addresses analysis folder
            [File_Prefix,Date_Prefix,File_IDs,Obs_Type]=Breakup_Title_Exp_Folder(Exp_Folders(II).name); %Generate File ID, and determine if current observation is social, habituation, or test.
            disp(File_Prefix)

            %Check and see if all the files exist in the beginning, then create missing files based on return.
            % For F, M1, M2, does Stamp, Cam, Mic, Mic_Montage, or
            % Shift_Montage_Rez, or Montage_Rez_Aud_10x exist?
            % Is there Montage_Rez? Isthere Shift_Montage_Rez? Isthere audio
            % Montage? Check if all the raw files, and post process files
            % exist, and decide to run each step if so.
            disp("Step One Detect existing files")
            [File_Table,Skip_Folder]=Check_Rec_Files(Obs_Folder,File_Prefix,Obs_Type);

            if Skip_Folder %If all files exist, or there is a note in the folder, skip the observation, because the observation is not usable.
                continue
            end
            Stamp_File=File_Table{1}{1,"Extra"};
            [~,Stamp_Rate]=audioread(Stamp_File);
            try
                Signal_Variables=who('-file',File_Table{1}{4,"Extra"});
                Signal_Variables=~all(contains(Signal_Variables,["File_List";"Master_Locs";"TTL_Global"]));
            catch
                Signal_Variables=1;
            end
            set(gcf, 'Position', get(0, 'Screensize'))

            %% Step 2 Create Signal Tracker File
            if ~File_Table{2}{4,"Extra"} && Signal_Variables %if Singal_Tracking.mat doesnt exist, make it. It should contain variables: "File_List","Master_Locs","TTL_Global"
                disp("Step 2 Create Signal Tracker File")
                MMF = memmapfile(Stamp_File, ...
                    'Offset', 0, ...
                    'Format', 'int32', ...
                    'Writable', false);
                Master_Data= MMF.Data;

                %%Plot master data to check for good signaling.
                Equipment_Sig=Find_spikes(double(Master_Data(Stamp_Rate*8:Stamp_Rate*10)));
                tiledlayout(3,3)
                nexttile
                plot(Equipment_Sig)
                title("stamp",File_Prefix)
                hold on
                [Val,Master_Locs] =findpeaks(Equipment_Sig,'MinPeakProminence',1*10e8,"MinPeakDistance",30);%GIes location of the peaks
                scatter(Master_Locs,Val)
                disp("#(peaks) on stamp file, should be about 41fps with about 1,968 sample distance between pings. Stamp file avg sample distance difference is:")
                disp(mean(diff(Master_Locs)))
                subtitle("avg sample dist diff:"+mean(diff(Master_Locs)))
                hold off
                Equipment_Sig=Find_spikes(double(Master_Data));
                [~,Master_Locs] =findpeaks(Equipment_Sig,'MinPeakProminence',1*10e8,"MinPeakDistance",30);%Gives location of the peaks
                Signal_Files=Obs_Folder+"/"+string(ls(Obs_Folder+"/*-Cam-*.wav"));             % Load camera_signal
                File_List=cell(7,length(Signal_Files));
                for III=1:length(Signal_Files) %For each camera signal file, save file name and a data pointer to File List row 1 and 2
                    File_Name=Signal_Files(III);
                    View=split(Signal_Files(III),"-");
                    File_List{1,III}=View(end); %File name
                    MMF = memmapfile(File_Name, ...
                        'Offset', 0, ...
                        'Format', 'int32', ...
                        'Writable', false);
                    File_List{2,III} = MMF.Data; %file data
                end
                for III = 1:size(File_List,2) %for WAV file being looked at, find the sample with TTL signal
                    Equipment_Sig=Find_spikes(double(File_List{2,III}));
                    [~,File_List{3,III}] =findpeaks(Equipment_Sig,'MinPeakProminence',3*10e7,"MinPeakDistance",40);%GIes location of the peaks
                    if isempty(File_List{3,III})
                        disp(["No Camera spikes detected for "; File_List{1,III}; "Replacing with "])
                        Bad_Note=fopen(Obs_Folder+"/Note.txt",'w');
                        fwrite(Bad_Note,"No Camera spikes detected for "+ File_List{1,III});
                        fclose(Bad_Note);
                        if III==1
                            File_List{3,III}=Master_Locs;
                        elseif III==2
                            File_List{3,2}=File_List{3,1};
                        elseif III==3
                            File_List{3,3}=File_List{3,2};
                        end
                        Cam_Locs=File_List{3,III};
                        Diff_Cam_vs_Master_Locs = abs(Cam_Locs-Master_Locs');
                        [~,y] = find(Diff_Cam_vs_Master_Locs==min(Diff_Cam_vs_Master_Locs,[],2));
                        Minimum_Time_Div = min(Diff_Cam_vs_Master_Locs,[],2);
                        File_List{5,III}= Minimum_Time_Div(2:end);
                        File_List{6,III}= y(2:end);
                    else
                        disp("Found signaling from camera "+File_List{1,III})
                        Cam_Locs=File_List{3,III};
                        Diff_Cam_vs_Master_Locs = abs(Cam_Locs-Master_Locs');
                        [~,y] = find(Diff_Cam_vs_Master_Locs==min(Diff_Cam_vs_Master_Locs,[],2));
                        Minimum_Time_Div = min(Diff_Cam_vs_Master_Locs,[],2);
                        File_List{5,III}= Minimum_Time_Div(2:end);
                        File_List{6,III}= y(2:end);
                    end
                end
                disp('Getting video frame counts')
                TTL_Global = unique(cat(1,File_List{6,:}));
                for Letter_Num=1:3
                    Letter=Letters(Letter_Num);
                    if File_Table{2}{2,Letter} %If Cam-Letter.mp4 exists
                        Read_Cam=VideoReader(File_Table{1}{2,Letter});
                        File_List{7,Letter_Num} = Read_Cam.NumFrames;
                        [~,ind] = ismember(TTL_Global(:,1),File_List{6,Letter_Num});
                        TTL_Global(:,Letter_Num+1) = ind;
                    else
                        Bad_Note=fopen(Obs_Folder+"/Note.txt",'w');
                        disp("Missing mp4 Cam-"+Letter+".mp4")
                        fwrite(Bad_Note,"Missing mp4 Cam-"+Letter+".mp4 \n");
                        fclose(Bad_Note);
                        continue
                    end
                end
                for III =2:size(TTL_Global,2)
                    ind = TTL_Global(:,III);
                    idx = diff(TTL_Global(:,III),1,1);
                    idx(idx>2) = 0;
                    idx= find(idx<0);
                    ind(idx+1) = ind(idx);
                    TTL_Global(:,III) = ind;
                end
                save(File_Table{1}{4,"Extra"},"File_List","Master_Locs","TTL_Global",'-mat',"-v7.3")
            else
                load(File_Table{1}{4,"Extra"},"File_List","Master_Locs","TTL_Global")
            end

            Audio_Locs = TTL_Global(:,1);
            Audio_Locs = Master_Locs(Audio_Locs);
            Locs_Dev = diff(Audio_Locs);
            Locs_Linear = min(Audio_Locs):max(cumsum(Locs_Dev));

            % Memory map original microphone data
            FrameRate=Stamp_Rate/median(diff(Master_Locs(TTL_Global(:,1))));
            %Step 3 Check view alignment
            disp("Step 3 Check view alignment")
            for Letter_Num=1:3
                Letter=Letters(Letter_Num);
                disp(Letter)
                Translate_Table=zeros(3,2);
                if File_Table{2}{1,Letter}&&File_Table{2}{2,Letter}
                    DDone=1;
                    while DDone==1
                        try
                            Closest_File = Find_Closest_Frame(Date_Prefix,Letter);
                        catch
                            error("You need to run Find_Next_Need_Master_or_FilterV1 on this bird.")
                        end
                        load(Closest_File,'Master_Frame')
                        Read_Cam= VideoReader(File_Table{1}{2,Letter}); %Read Cam-Letter.mp4
                        Frame = read(Read_Cam, 2000); % 500th frame of Cam-Letter.mp4
                        Frame= imresize(Frame,[1002,1776]); % Resize video frame to whats accepted by Deep Lab Cut
                        Frame = rgb2gray(Frame);
                        Unshifted=Frame;
                        nexttile
                        image(Master_Frame)
                        title("Master Frame")
                        nexttile
                        image(Unshifted) % Show comparison of images before shift
                        title("Unshifted")
                        correlation = normxcorr2(Master_Frame, Frame);
                        [~, max_index] = max(abs(correlation(:)));
                        [ypeak, xpeak] = ind2sub(size(correlation), max_index(1));
                        Fy_offset = ypeak - size(Master_Frame, 1);
                        Fx_offset = xpeak - size(Master_Frame, 2);
                        Frame=imtranslate(Frame, [-Fx_offset, -Fy_offset]);
                        nexttile
                        image(Frame)  % Show comparison of images after shift
                        title("Shifted Frame")
                        DDone=0;
                        if abs(Fy_offset)>300 || abs(Fx_offset)>300
                            Create_Master_Frame(Date_Prefix,Unshifted,Letter)
                            DDone=1;
                        end
                        Translate_Table(Letter_Num,:)=[-Fx_offset, -Fy_offset];
                    end
                end
            end
            set(gcf, 'Position', get(0, 'Screensize'))
            saveas(gca,fullfile(Analysis_Folder,File_Prefix+"-Alignment_Check-"+Letter+".jpg"),'jpg')
            clf

            %% Part 4 Write Shift_Montage_Rez videos
            disp("Part 4 Write Shift_Montage_Rez videos")
            for Letter_Num=1:3
                % Shift means videos have been motion corrected, so in case
                % cameras or HOS get knocked or jittered, image is corrected.
                % Montage means at each TTL pulse a black frame is created, and the closest frame from the same cam
                % view replace that black frame. If theres no close frame, keep it
                % black.

                % Rez means resize the video to specified dimensions, 1002 tall
                % by 1776 wide.
                Letter=Letters(Letter_Num);
                if File_Table{2}{1,Letter}&&File_Table{2}{2,Letter}&&~File_Table{2}{3,Letter}
                    Vid_Writer=VideoWriter(File_Table{1}{3,Letter},'MPEG-4'); %Write Shift_Montage_Rez-Letter.mp4
                    Vid_Writer.FrameRate=FrameRate;
                    Read_Cam= VideoReader(File_Table{1}{2,Letter}); %Read Cam-Letter.mp4
                    open(Vid_Writer)
                    for III=1:size(TTL_Global,1)
                        if TTL_Global(III,Letter_Num+1)==0 || TTL_Global(III,Letter_Num+1)>Read_Cam.NumFrames
                            Cam_Frame=zeros(1002,1776,3,'uint8');
                        else
                            try
                                Cam_Frame=imresize(read(Read_Cam,TTL_Global(III,Letter_Num+1)),[1002,1776]);
                                Cam_Frame=imtranslate(Cam_Frame, Translate_Table(Letter_Num,:));
                            catch
                                Cam_Frame=zeros(1002,1776,3,'uint8');
                            end
                        end
                        writeVideo(Vid_Writer,Cam_Frame);
                    end
                    close(Vid_Writer)
                end
            end
        end
        %% Part 5 Write Montage_Mic audio files.
        % Montage in this instance means that the mic files begin and
        % end at the same time as the first and last TTL pulse. If
        % there is no audio data, pad with zeros.
        if File_Table{2}{5,Letter}&&~File_Table{2}{6,Letter}
            disp("Part 5 Write Montage_Mic audio files.")
            Mic_File_View=split(File_Table{1}{5,Letter},"\");
            Mic_File_View=split(Mic_File_View(end),"-");
            Mic_File_View=split(Mic_File_View(end),".");
            Mic_File_View=Mic_File_View(end);
            disp("Getting audio montage "+ Mic_File_View)
            amf = memmapfile(File_Table{1}{5,Letter}, ...
                'Offset', 0, ...
                'Format', 'int32', ...
                'Writable', false);
            % Get small sample of audio to get accurate FS
            [~,FS] = audioread(File_Table{1}{5,Letter},[1,1]);
            %Fill sample gaps
            Audio_ttl = cat(1,zeros(FS,1,'int32'),amf.Data(Locs_Linear));
            audiowrite(File_Table{1}{6,Letter},Audio_ttl,FS)
        end
        %% Part 6 Write Montage_Rez_Aud_10x
        if ~File_Table{2}{4,Letter}
            disp("Part 6 Write Montage_Rez_Aud_10x.")
            CMD_Input =['ffmpeg -y -i ',Obs_Folder,'/',char(File_Prefix) '-Shift_Montage_Rez-', char(Letter), '.mp4 ',...
                '-i ', Obs_Folder,'/',char(File_Prefix) '-Mic_Montage-', char(Letter), '.wav ',...
                '-filter_complex "[0:v]setpts=0.1*PTS[v];[1:a]atempo=2.0,atempo=2.0,atempo=2.5[a]" -map "[v]" -map "[a]" -c:v h264 -preset fast -y '...
                Obs_Folder,'\',char(File_Prefix) '-Shift_Montage_Rez_Aud_10x-', char(Letter), '.mp4'];
            system(CMD_Input)
        end
    end
    %% Part 7 Create h5 of where birds where in video ~2hrs
    if any([~File_Table{2}{7,"F"},~File_Table{2}{7,"M1"},~File_Table{2}{7,"M2"}])
        disp("Part 7 Create H5 of where birds where in video")
        Video_List=strings(3,1);
        for Letter_Num =1:length(Letters)
            if File_Table{2}{3,Letters(Letter_Num)}&&~File_Table{2}{7,Letters(Letter_Num)}
                Video_List(Letter_Num)=File_Table{1}{3,Letters(Letter_Num)};
            else
                Video_List(Letter_Num)="Empty";
            end
        end
        Video_List=join(Video_List," ");
        CMD_Input = Python_Env+" DLC_Analyze_Video_MS.py "+" "+Analysis_Folder+" "+Video_List+" "+" "+Create_Annotated_Videos;
        disp(CMD_Input)
        CMD_Return=system(CMD_Input);
        for Letter_Num =1:length(Letters)
            Rename_DLC(Letters(Letter_Num),Obs_Folder,File_Prefix);
        end
        [File_Table,~]=Check_Rec_Files(Obs_Folder,File_Prefix,Obs_Type);
    end

    %% Part 8 Create a single filtered bird coord file, with all views synced. ( Approximately 1hr 10 min for 3 15 min videos)
    disp("Part 8 Create filtered coordinates file Symphony, by reading and tying in order top, m1, m2 view.")
    if ~File_Table{2}{7,"Extra"} && (all([File_Table{2}{7,"F"},File_Table{2}{7,"M1"},File_Table{2}{7,"M2"}]))
        tic
        H5_List=[File_Table{1}{7,"F"},File_Table{1}{7,"M1"},File_Table{1}{7,"M2"}];
        [Symphony_Address,N_Frames]=Make_Bird_Coord(File_Prefix,Analysis_Folder,H5_List);
        toc
    else
        disp("Part 8 skipped")
    end
    % rows
    % x,y
    % 1,2    F   top view
    % 3,4    M1  top View
    % 5,6    M2  top view
    % 7,8    F   M1 view
    % 9,10   M1  M1 view
    % 11,12  F   M2 view
    % 13,14  M2  M2 view

    %% Part 9 Showing when birds started and stopped perching.
    disp("Part 9 Showing when birds started and stopped perching, by reading and tying in order top, m1, m2 view.")
    [File_Table,~]=Check_Rec_Files(Obs_Folder,File_Prefix,Obs_Type);
    if File_Table{2}{7,"Extra"} && (Letter=="M1"||Letter=="M2")
        Bird_Perch_File=When_Bird_Perched(File_Prefix,Analysis_Folder,File_Table{1}{5,"Extra"},Date_Prefix);
    else
        disp("Part 9 skipped")
    end
    %% Part 10 Create mat file of when birds sang.
    for Letter_Num=2:3
        Letter=Letters(Letter_Num);
        if ~File_Table{2}{Letter_Num+3,"Extra"}&&(Obs_Type~=0)&&isfile(Find_File_Wild("*Signal_Tracking.mat",Obs_Folder))
            disp("Part 10 "+Letter+" Mic Motif Creation")
            Create_Motif_Coord_File(File_IDs(Letter_Num),File_Table{1}{5,"Extra"},File_Table{1}{6,Letter},File_Table{1}{4,"Extra"},Letter,Analysis_Folder,File_Prefix,Stamp_File);
        end
    end

end


function [Letters,Python_Env,Create_Annotated_Videos]=Part_Zero()
warning('off','MATLAB:table:RowsAddedExistingVars')
Python_Env="C:\ProgramData\anaconda3\envs\DEEPLABCUT\python.exe";
Letters=["F","M1","M2"];
Create_Annotated_Videos=1;
end

function output=Find_spikes(s)
s = movsum(s,[0,10]);
s(s<0)=0;
s = diff(s);
s(s<0)=0;
output=s;
end

function [FilePrefix,DatePrefix,FileIDs,Obs_Type]=Breakup_Title_Exp_Folder(ExpFolder)
%Obs_Type
%0 means test
%1 means social
%2 means female habituation
%3 means male habituation
%File prefix is date and social group of observation
%File IDs are the IDs of Female, Male1, and Male2 in that order.
if ExpFolder==""
    FilePrefix="";
    DatePrefix="";
    FileIDs=strings(3,1);
    Obs_Type=0;
    return
end
FilePrefix=split(string(ExpFolder),"-");
DatePrefix=FilePrefix(1);
BirdIds=split(string(FilePrefix(2)),"_");  %Get the Coord experiment file name
FileIDs=[BirdIds(2),BirdIds(4),BirdIds(6)];
%If there is no female in experiment, skip.
FilePrefix=string(ExpFolder);
if (FileIDs(1)=="") && ((FileIDs(2)=="")&&(FileIDs(3)==""))
    Obs_Type=0;
elseif (FileIDs(1)~="") && ((FileIDs(2)~="")&&(FileIDs(3)~=""))
    Obs_Type=1;
elseif (FileIDs(1)~="") && ((FileIDs(2)=="")&&(FileIDs(3)==""))
    Obs_Type=2;
elseif (FileIDs(1)=="") && ((FileIDs(2)~="")&&(FileIDs(3)~=""))
    Obs_Type=3;
end
end

function [Name_Existance_Table,Skip_Folder]=Check_Rec_Files(Rec_Folder,File_Prefix,Obs_Type)
%Return a 2xtable cell object, where first table is names, second table is existance.
% F,    M1,     M2,     Extra
%1 Camwav                 Stamp
%2 Cammp4                 Social Data
%3 Shift_Montage_Rez      Summary Social.svg
%4 Shift_Montage_Rez_10x  Signal Tracking
%5 Mic                    M1 Motif Coord
%6 Mic_Montage            M2 Motif Coord
%7 Raw coord
%8 filtered coord
Number_Rows=7;
Name_Table=table('Size',[Number_Rows,4],'VariableNames',["F","M1","M2","Extra"],'VariableTypes',["string","string","string","string"]);
Existance_Table=table('Size',[Number_Rows,4],'VariableNames',["F","M1","M2","Extra"],'VariableTypes',["logical","logical","logical","logical"]);
Letters=["F","M1","M2"];
for Letter_num=1:3
    Letter=Letters(Letter_num);
    Name_Table(1,Letter)={fullfile(Rec_Folder,File_Prefix+"-Cam-"+Letter+".wav")}; %Wav file of when camera took pic
    Name_Table(2,Letter)={fullfile(Rec_Folder,File_Prefix+"-Cam-"+Letter+".mp4")}; %Mp4 of what picture camera took
    Name_Table(3,Letter)={fullfile(Rec_Folder,File_Prefix+"-Shift_Montage_Rez-"+Letter+".mp4")}; %Corrected pitcure of mp4 camera took
    Name_Table(4,Letter)={fullfile(Rec_Folder,File_Prefix+"-Shift_Montage_Rez_Aud_10x-"+Letter+".mp4")}; %Corrected pitcure of mp4 camera took
    Name_Table(5,Letter)={fullfile(Rec_Folder,File_Prefix+"-Mic-"+Letter+".wav")}; %Raw mic recording of males
    Name_Table(6,Letter)={fullfile(Rec_Folder,File_Prefix+"-Mic_Montage-"+Letter+".wav")}; %Corrected mic recording of males
    Name_Table(7,Letter)={ls(fullfile(Rec_Folder,"Analysis",File_Prefix+"*"+Letter+".h5"))}; %Does DLC file exist
    Name_Table(7,Letter)={fullfile(Rec_Folder,"Analysis",Name_Table{7,Letter})}; %Does DLC file exist
    for II=1:Number_Rows-1
        Existance_Table(II,Letter)={exist(Name_Table{II,Letter},"file")==2};
    end
end
Name_Table(1,"Extra")={fullfile(Rec_Folder,File_Prefix+"-Stamp.wav")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(2,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Social_Data.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(3,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Summary_Social.svg")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(4,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Signal_Tracking.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
% Name_Table(5,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Motif_Coord-M1.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
% Name_Table(6,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Motif_Coord-M2.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(5,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Symphony.h5")}; %Coordinate Processor data, showing all F view videos have been processed.
for II=1:5
    Existance_Table(II,"Extra")={exist(Name_Table{II,"Extra"},"file")==2};
end

Name_Existance_Table={Name_Table,Existance_Table};
if Obs_Type==1
    Skip_Folder=sum(Existance_Table{:,:},'all')==25;
else
    Skip_Folder=sum(Existance_Table{:,:},'all')==23;
end

end

function Rename_DLC(Letter,Obs_Folder,File_Prefix)
%2025_01_01_13_51-F_Y89_M1__M2_-DLC_F_view_Sep20-Resnet50-Shuffle_1-Snap_300000
DLC_File_Name_Old=string(ls(fullfile(Obs_Folder,"Analysis",File_Prefix+"*"+Letter+"DLC*.h5")));
DLC_File_Name_Old=fullfile(Obs_Folder,"Analysis",DLC_File_Name_Old);
Detail_Part = extractAfter(DLC_File_Name_Old, Letter+"DLC");  % e.g., 'resnet50_F_view_shiftedSep20shuffle1_300000.h5'

% Parse model architecture, view, date, shuffle, snapshot
Tokens = regexp(Detail_Part,"resnet(\d+)_"+Letter+"_View_([A-Za-z]+\d+[A-Za-z]+\d+)shuffle(\d+)_(\d+)\.h5", 'tokens');
if ~isempty(Tokens)
    t = Tokens{1};
    arch = t{1};       % e.g., '50' Resnet type
    dateStr = t{2};    % e.g., 'Sep20'Date and version of DLC project creation
    shuffle = t{3};    % e.g., '1'  Shuffle number
    snap = t{4};       % e.g., '300000' Iteration number

    % Construct new filename 2024_12_06_16_01-F_R119_M1__M2_-DLC_F_view_Sep20-Resnet50-Shuffle_1-Snap_300000
    DLC_File_Name_New = sprintf(['%s-DLC_' char(Letter) '_%s_Resnet%s_Shuffle_%s_Snap_%s-' char(Letter) '.h5'], ...
        File_Prefix, dateStr, arch, shuffle, snap);

    DLC_File_Name_New = fullfile(Obs_Folder,"Analysis", DLC_File_Name_New);

    movefile(DLC_File_Name_Old,DLC_File_Name_New)
end
end

function Create_Motif_Coord_File(Male_ID,Symphony_File,Mic_File,Signal_Tracking_File,Letter,Analysis_Folder,File_Prefix,Stamp_File)
Threshold = 0.55;
if Letter=="M1"
    Row_Num=18;
else
    Row_Num=19;
end
Song_Folders=["D:\Lab Dropbox\BirdSong\BirdData_2024",...
    "\\Miniscope\d\Birdsong_560M",...
    "\\Miniscope\d\Birdsong_581D",...
    "\\Miniscope\d\Birdsong_581E",...
    "\\Miniscope\d\Birdsong_591F",...
    "\\Miniscope\d\Birdsong"];
for I=Song_Folders
    MicTemplate_Address=fullfile(I,Male_ID,"mic_template.mat");
    if exist(MicTemplate_Address,'file')
        disp(MicTemplate_Address)
        break
    end
    if I =="\\Miniscope\d\Birdsong"
        warning("No template for male "+Male_ID)
    end
end
if ~isfile(MicTemplate_Address)
    Template_File=fullfile(Songs_Folders,Male_ID,"fortemplate.wav");
    Template_File_Data = audioread(Template_File);
    Motif_Template = get_mic_template_V3(Template_File_Data);
    save(fullfile(Songs_Folders,Male_ID,"mic_template.mat"),'Motif_Template',"-v7.3");
end
load(MicTemplate_Address,'Motif_Template','FS_TS')
if string(lastwarn)=="Variable 'Motif_Template' not found."
    load(MicTemplate_Address,'mic','FS_TS')
    Motif_Template=mic;
end
[Temp_Spec, ~,~] = zftftb_pretty_sonogram(normalize(Motif_Template,'range'), FS_TS,...
    'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);
Mic_Info = audioinfo(Mic_File);
Chunk_Size=Mic_Info.SampleRate*5;%Convert every ten seconds into a spectorgram.
Num_Chunks=Mic_Info.TotalSamples/Chunk_Size;
minchunks=ceil(Num_Chunks);
Motifs_Anno = cell(minchunks-1,4);
for I=1:minchunks %Load first chunk and next chunk, until there is one chunk left.
    if I==1
        Start_Chunk=1;
    else
        Start_Chunk=(I-1)*Chunk_Size;
    end
    End_Chunk=min((I+1)*Chunk_Size,Mic_Info.TotalSamples);
    HOS_Mic_Chunk=audioread(Mic_File,[Start_Chunk,End_Chunk]);
    [HOS_Mic_Chunk_Spec, ~,Time_Bins] = zftftb_pretty_sonogram(normalize(HOS_Mic_Chunk,'range'), Mic_Info.SampleRate,...
        'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);
    % HOS_Mic_Chunk_Spec1(isnan(HOS_Mic_Chunk_Spec1))=0;
    % Ok. Spectrogram one chunk, then normxcorr2, find peaks, and add the time shift to the
    % results. Then get a new chunk that is half a chunk shifted over, and
    % repeat the process
    if I<25
        nexttile
        imagesc(HOS_Mic_Chunk_Spec)
        hold on
    end

    try
        Match_Score = normxcorr2(Temp_Spec(50:400,:), HOS_Mic_Chunk_Spec(50:400,:)); %normxcorr2(pattern we are looking for in A, A)
    catch
        continue
    end
    [~,Freq_Match] = max(max(Match_Score,[],2));% Where on the frequency axis is the highest match, find peaks on that frequency to find all other matches.
    Match_Score = Match_Score(Freq_Match,:); %True match score
    [~,Motif_Locs] = findpeaks(Match_Score,'MinPeakProminence',Threshold);
    Motif_Locs(Motif_Locs>numel(HOS_Mic_Chunk_Spec)) = [];
    %%%%%%%%%%%% Identify whether wav file has motif ##############
    %move file into song folder or noise
    if ~isempty(Motif_Locs)
        specenv = single(sum(HOS_Mic_Chunk_Spec,1)); %Sums together all the frequency intensities into a single array. Creates a volume magnitude array.
        Motif_Locs = reshape(Motif_Locs,[],1); %Reshapes Motif Locs to be a array along the first dimension, the row dimension. The [] indicates it can be any number of rows, 1 indicates how many columns.
        Start_Stop_Motif_Ind = repmat([-fix(size(Temp_Spec,2)/2),fix(size(Temp_Spec,2)/2)],[numel(Motif_Locs),1])+Motif_Locs; %ok. So take the
        Motif_Locs(Start_Stop_Motif_Ind(:,1)<1,:)=[];
        Motif_Locs(Start_Stop_Motif_Ind(:,2)>numel(specenv),:)=[];
        Start_Stop_Motif_Ind(Start_Stop_Motif_Ind(:,1)<1,:)=[];
        Start_Stop_Motif_Ind(Start_Stop_Motif_Ind(:,2)>numel(specenv),:)=[];
        if ~isempty(Motif_Locs)
            Motif_Coords=[Start_Stop_Motif_Ind(:,1),Motif_Locs,Start_Stop_Motif_Ind(:,2)];
            if ~isempty(Motif_Coords) && I<25
                xline(Motif_Coords(:,1),'-r') %motif starts
                xline(Motif_Coords(:,2),'-k') %motif detected
                xline(Motif_Coords(:,3),'-y') %motif ended
            end
            Motifs_Anno{I} =Time_Bins(Motif_Coords)+(I-1)*5; %When signal was detected, in seconds.
            if I<25
                hold off
            end
        end
    end
end
saveas(gca,fullfile(Analysis_Folder,File_Prefix+"-Motif_Check-"+Letter+".jpg"),'jpg')
Motifs_Anno = Motifs_Anno(~cellfun(@isempty, Motifs_Anno));
Motifs_Anno=round(cell2mat(Motifs_Anno),2);
[~,Unique_Row_Indx]=unique([Motifs_Anno(:,2)]','first');
Motifs_Anno=Motifs_Anno(Unique_Row_Indx,:);
[~,Unique_Row_Indx]=unique([Motifs_Anno(:,1)]','first');
Motifs_Anno=Motifs_Anno(Unique_Row_Indx,:);
[~,Unique_Row_Indx]=unique([Motifs_Anno(:,3)]','first');
Motifs_Anno=Motifs_Anno(Unique_Row_Indx,:);
[~,Stamp_Rate]=audioread(Stamp_File);

Motifs_Sample=Motifs_Anno*Stamp_Rate;
load(Signal_Tracking_File,"Master_Locs")
[~,Motif_Frame_Ind]=min(abs(Motifs_Sample(:,1)-Master_Locs'),[],2);
Motifs_Sample(:,1)=Motif_Frame_Ind;
[~,Motif_Frame_Ind]=min(abs(Motifs_Sample(:,2)-Master_Locs'),[],2);
Motifs_Sample(:,2)=Motif_Frame_Ind;
[~,Motif_Frame_Ind]=min(abs(Motifs_Sample(:,3)-Master_Locs'),[],2);
Motifs_Sample(:,3)=Motif_Frame_Ind;
Motif_Data=cat(1,Motifs_Anno',Motifs_Sample');
try
    h5write(Symphony_File,"/Motif_Coord_"+Letter,Motif_Data,[1,1],[size(Motif_Data)])
catch
    h5create(Symphony_File,"/Motif_Coord_"+Letter,[6 Inf], 'Datatype', 'double', ...
        'ChunkSize', [1 1], 'Deflate', 0)
    h5write(Symphony_File,"/Motif_Coord_"+Letter,Motif_Data,[1,1],[size(Motif_Data)])
end
clf
end

function [Bird_Coord_Name,Nframes]=Make_Bird_Coord(File_Prefix,Analysis_Folder,H5List)

Thresh=0.02;
% There are 5 points per bird from top, 1 point per bird from side. Now, F
% has three sets, the top, side 1, side 2. Males have top and 1 side.
% --- Load datasets ---

H5Data  = h5read(H5List(1),  '/df_with_missing/table');
Nframes = size(H5Data.values_block_0,2);
Bird_Coord_Name = fullfile(Analysis_Folder,File_Prefix+"-Symphony.h5");
dataset = '/Bird_Coord';

% Let's say we want to append rows to a 2D dataset of doubles
% Initial size: [0 x 3] → zero rows, 3 columns
% Maximum size: [Inf x 3] → unlimited rows
try
    h5create(Bird_Coord_Name, dataset, [17 Nframes], 'Datatype', 'double', ...
        'ChunkSize', [17 1], 'Deflate', 0);
    for Letter=["M1","M2"]
        h5create(Symphony_File,"/Motif_Coord_"+Letter,[17 Inf], 'Datatype', 'double', ...
            'ChunkSize', [1 1], 'Deflate', 0)
    end
catch
    disp("Symphony already exists")
end

% --- Round ---
% Round x/y to nearest integer, likelihood to nearest 0.001
Round_Likelihood = @(x) round(x,3);
for H5_File_Num=1:3
    Letter=["F","M1","M2"];
    Letter=Letter(H5_File_Num);
    H5Data  = h5read(H5List(H5_File_Num),  '/df_with_missing/table');
    Nframes = size(H5Data.values_block_0,2);
    H5Data  = H5Data.values_block_0(:,1:Nframes);
    for I = 1:3:size(H5Data,1)  % every 3 rows: x,y,likelihood
        H5Data(I,:)   = single(fix(H5Data(I,:)));     % x
        H5Data(I+1,:) = single(fix(H5Data(I+1,:)));   % y
        H5Data(I+2,:) = Round_Likelihood(H5Data(I+2,:)); % Is datapoint above threshold.
    end

    if Letter=="F"
        F_Top_XMax=1120;
        F_Top_XMin=490;
        F_Top_YMax=1002;
        F_Top_YMin=500;

        F_Bottom_XMax=1770;
        F_Bottom_XMin=5;
        F_Bottom_YMax=500;
        F_Bottom_YMin=5;

        M1_XMax=1770;
        M1_XMin=1325;
        M1_YMax=1000;
        M1_YMin=500;

        M2_XMax=490;
        M2_XMin=5;
        M2_YMax=1000;
        M2_YMin=500;

        Bird_Y_Coord=2;
        disp("Part 7 F Top view")
        for I = 1:Nframes
            Row_Coord=1;
            Body_Part_Data=NaN(2,5);
            for II = 1:3:15 %First 15 rows FTop
                switch II
                    case 1
                        III=1;
                    case 4
                        III=2;
                    case 7
                        III=3;
                    case 10
                        III=4;
                    otherwise
                        III=5;
                end
                %EDIT THIS IF YOU WANT TO FILTER THE COORDS
                %[xBeak,xHead,xBody,xTailBase,xTailTip;
                % yBeak,yHead,yBody,yTailBase,yTailTip]
                X_val=H5Data(II,I);
                Y_val=H5Data(II+1,I);
                P_val=H5Data(II+2,I);

                % TOP
                if Y_val>F_Top_YMin && Y_val<F_Top_YMax

                    if  X_val> F_Top_XMin && X_val<F_Top_XMax&&P_val>Thresh
                        Body_Part_Data(1,III)=X_val;
                        Body_Part_Data(2,III)=Y_val;
                    else
                        Body_Part_Data(1:2,III)=NaN;
                    end
                else

                    if X_val>F_Bottom_XMin && X_val<F_Bottom_XMax && Y_val>F_Bottom_YMin&&Y_val<F_Bottom_YMax&&P_val>Thresh
                        Body_Part_Data(1,III)=X_val;
                        Body_Part_Data(2,III)=Y_val;
                    else
                        Body_Part_Data(1:2,III)=NaN;
                    end
                end
            end
            M_X=mean(Body_Part_Data(1,:),"omitmissing");
            M_Y=mean(Body_Part_Data(2,:),"omitmissing");
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_FF=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_FF=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_FF,[Row_Coord I],[2,1])
            end

            Row_Coord=3;

            for II = 16:3:30 %Next 15 rows M1 bird Top view
                switch II
                    case 16
                        III=1;
                    case 19
                        III=2;
                    case 22
                        III=3;
                    case 25
                        III=4;
                    otherwise
                        III=5;
                end
                X_val=H5Data(II,I);
                Y_val=H5Data(II+1,I);
                P_val=H5Data(II+2,I);
                if X_val>M1_XMin&& X_val<M1_XMax&&Y_val>M1_YMin&&Y_val<M1_YMax&&P_val>Thresh
                    Body_Part_Data(1,III)= X_val;
                    Body_Part_Data(2,III)= Y_val;
                else
                    Body_Part_Data(1:2,III)=NaN;
                end
            end
            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_FM1=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_FM1=[M_X;M_Y];
            else
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_FM1,[Row_Coord I],[2,1])
            end

            Row_Coord=5;

            for II = 31:3:45 %Next 15 rows M1Top
                switch II
                    case 31
                        III=1;
                    case 34
                        III=2;
                    case 37
                        III=3;
                    case 40
                        III=4;
                    otherwise
                        III=5;
                end
                X_val=H5Data(II,I);
                Y_val=H5Data(II+1,I);
                P_val=H5Data(II+2,I);
                if X_val>M2_XMin&& X_val<M2_XMax&&Y_val>M2_YMin&&Y_val<M2_YMax&&P_val>Thresh
                    Body_Part_Data(1,III)= X_val;
                    Body_Part_Data(2,III)= Y_val;
                else
                    Body_Part_Data(1:2,III)=NaN;
                end
            end
            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_FM2=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_FM2=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_FM2,[Row_Coord I],[2,1])
            end
        end
    elseif Letter=="M1"
        disp("Part 7 M1")
        F_XMax=1770;
        F_XMin=1250;
        F_YMax=1000;
        F_YMin=5;

        M1_XMax=1120;
        M1_XMin=5;
        M1_YMax=1000;
        M1_YMin=5;
        for I = 1:Nframes
            Row_Coord=7;
            Body_Part_Data=NaN(2,1);
            II = 1;%First 3 rows F M1
            III=1;

            X_val=H5Data(II,I);
            Y_val=H5Data(II+1,I);
            P_val=H5Data(II+2,I);

            % F
            if X_val>F_XMin && X_val<F_XMax && Y_val>F_YMin&&Y_val<F_YMax&&P_val>Thresh
                Body_Part_Data(1,III)=X_val;
                Body_Part_Data(2,III)=Y_val;
            else
                Body_Part_Data(1:2,III)=NaN;
            end

            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_F=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_F=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_F,[Row_Coord I],[2,1])
            end

            Row_Coord=9;
            Bird_Y_Coord=10;


            II = 4;
            III=1;
            Body_Part_Data=NaN(2,1);
            X_val=H5Data(II,I);
            Y_val=H5Data(II+1,I);
            P_val=H5Data(II+2,I);
            if X_val>M1_XMin&& X_val<M1_XMax&&Y_val>M1_YMin&&Y_val<M1_YMax&&P_val>Thresh
                Body_Part_Data(1,III)= X_val;
                Body_Part_Data(2,III)= Y_val;
            else
                Body_Part_Data(1:2,III)=NaN;
            end

            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_M=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_M=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_M,[Row_Coord I],[2,1])
            end
        end
    elseif Letter=="M2"
        disp("Part 7 M2")
        F_XMax=610;
        F_XMin=5;
        F_YMax=1000;
        F_YMin=5;

        M2_XMax=720;
        M2_XMin=5;
        M2_YMax=1000;
        M2_YMin=5;
        for I = 1:Nframes
            Row_Coord=11;
            Bird_Y_Coord=12;
            Body_Part_Data=NaN(2,1);
            II = 1; %First 3 rows F M1
            III=1;
            X_val=H5Data(II,I);
            Y_val=H5Data(II+1,I);
            P_val=H5Data(II+2,I);

            % TOP
            if X_val>F_XMin && X_val<F_XMax && Y_val>F_YMin&&Y_val<F_YMax&&P_val>Thresh
                Body_Part_Data(1,III)=X_val;
                Body_Part_Data(2,III)=Y_val;
            else
                Body_Part_Data(1:2,III)=NaN;
            end

            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_F=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_F=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_F,[Row_Coord I],[2,1])
            end

            Row_Coord=13;
            Bird_Y_Coord=14;

            II = 4;
            III=1;
            Body_Part_Data=NaN(2,1);
            X_val=H5Data(II,I);
            Y_val=H5Data(II+1,I);
            P_val=H5Data(II+2,I);
            if X_val>M2_XMin&& X_val<M2_XMax&&Y_val>M2_YMin&&Y_val<M2_YMax&&P_val>Thresh
                Body_Part_Data(1,III)= X_val;
                Body_Part_Data(2,III)= Y_val;
            else
                Body_Part_Data(1:2,III)=NaN;
            end

            M_X=fix(mean(Body_Part_Data(1,:),"omitmissing"));
            M_Y=fix(mean(Body_Part_Data(2,:),"omitmissing"));
            if I==1
                h5write(Bird_Coord_Name,"/Bird_Coord",[NaN;NaN],[Row_Coord I],[2,1])
                Save_M_M=[NaN;NaN];
            elseif ~isnan(M_X) && ~isnan(M_Y)
                h5write(Bird_Coord_Name,"/Bird_Coord",[M_X;M_Y],[Row_Coord I],[2,1])
                Save_M_M=[M_X;M_Y];
            else %replace coordinate with previous coordinate
                h5write(Bird_Coord_Name,"/Bird_Coord",Save_M_M,[Row_Coord I],[2,1])
            end
        end
    end
end
end

function FullAddress=Find_File_Wild(File_Name,Folder)
FullAddress=fullfile(Folder,string(ls(fullfile(Folder,File_Name))));
end

function When_Bird_Perched(Bird_Coord_Address,Date_Prefix)
Closest_Filter = Find_Closest_Filter(Date_Prefix);
disp("Selected Filter "+Closest_Filter)
%rows of h5
%x,y
%1,2    F   top view
%3,4    M1  top View
%5,6    M2  top view
%7,8    F   M1 view
%9,10   M1  M1 view
%11,12  F   M2 view
%13,14  M2  M2 view
%15     F  Perch condition  1=M1,2=M2
%16     M1 Perch condition
%17     M2 Perch condition

DLC_H5_File=fullfile(Bird_Coord_Address);
H5Data  = h5read(DLC_H5_File,  '/Bird_Coord');
Nframes = size(H5Data,2);

% Filter_File=fullfile(Perch_Filter_Folder,Closest_File);
Filter_File = fileread(Closest_Filter);
Filter = jsondecode(Filter_File);
%FM1
FM1XMax=Filter.FM1XMax;
FM1XMin=Filter.FM1XMin;
FM1YMax=Filter.FM1YMax;
FM1YMin=Filter.FM1YMin;
%FM2
FM2XMax=Filter.FM2XMax;
FM2XMin=Filter.FM2XMin;
FM2YMax=Filter.FM2YMax;
FM2YMin=Filter.FM2YMin;
%M1
M1XMax=Filter.M1XMax;
M1XMin=Filter.M1XMin;
M1YMax=Filter.M1YMax;
M1YMin=Filter.M1YMin;
%M2
M2XMax=Filter.M2XMax;
M2XMin=Filter.M2XMin;
M2YMax=Filter.M2YMax;
M2YMin=Filter.M2YMin;

% Step 3: Access data
%Row 1 Frame num female perch M1
%Row 2 Frame num female perch M2
%Row 3 Frame num M1 perch
%Row 4 Frame num M2 perch

%Row 15 is when F perched. 1 indicates M1, 2 indicates M2, 3 indicates
%both, requiring looking at its location from
for I = 1:Nframes
    Female_X=H5Data(1,I);
    for II=1:3
        if II==1
            Row_Coord=15;
            if isnan(Female_X)
                continue
            elseif Female_X>1200
                FM1X=H5Data(7,I);
                FM1Y=H5Data(8,I);
                if FM1Y>FM1YMin && FM1Y<FM1YMax && FM1X>FM1XMin && FM1X<FM1XMax
                    h5write(Bird_Coord_Address,"/Bird_Coord",[1],[Row_Coord, I],[1,1])
                end
            elseif Female_X<500
                FM2X=H5Data(11,I);
                FM2Y=H5Data(12,I);
                if FM2Y>FM2YMin && FM2Y<FM2YMax && FM2X>FM2XMin&& FM2X<FM2XMax
                    h5write(Bird_Coord_Address,"/Bird_Coord",[1],[Row_Coord, I],[1,1])
                end
            end
        elseif II==2
            Row_Coord=16;
            M1X=H5Data(9,I);
            M1Y=H5Data(10,I);
            if isnan(M1X)
                continue
            elseif M1Y>M1YMin && M1Y<M1YMax && M1X>M1XMin&& M1X<M1XMax
                h5write(Bird_Coord_Address,"/Bird_Coord",[1],[Row_Coord, I],[1,1])
            end
        else
            Row_Coord=17;
            M2X=H5Data(13,I);
            M2Y=H5Data(14,I);
            if isnan(M1X)
                continue
            elseif M2Y>M2YMin && M2Y<M2YMax && M2X>M2XMin&& M2X<M2XMax
                h5write(Bird_Coord_Address,"/Bird_Coord",[1],[Row_Coord, I],[1,1])
            end
        end
    end
end
end