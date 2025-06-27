%% Step 1 clear all, init variables and notifier
clear
clc
clf
close all
Cohort_Dir="\\GERRIKLABCOMP\a\HOS_Cohorts\Cohort_*";
Letters=["F","M1","M2"];
Cohort_Folders=dir(Cohort_Dir);
for C=1:size(Cohort_Folders,1) %Which female we are looking a
    disp(Cohort_Folders(C).name)
    Female_Folders=dir(fullfile(Cohort_Folders(C).folder,Cohort_Folders(C).name,"F*"));
    for I=1:size(Female_Folders,1)
        for I=1:size(Female_Folders,1)
            Exp_Folders=dir(fullfile(Female_Folders(I).folder,Female_Folders(I).name,"20*")); %Discover all folders in the Female folder
            Exp_Folders(~[Exp_Folders(:).isdir])=[]; %Remove files from list
            disp(Female_Folders(I).name)
            for II=8:size(Exp_Folders,1)
                Obs_Folder= fullfile(Exp_Folders(II).folder,Exp_Folders(II).name); % Current observation folder address.
                Analysis_Folder= fullfile(Obs_Folder,"Analysis");                   % Current observation folder addresses analysis folder
                [File_Prefix,Date_Prefix,File_IDs,Obs_Type]=Breakup_Title_Exp_Folder(Exp_Folders(II).name); %Generate File ID, and determine if current observation is social, habituation, or test.
                disp(File_Prefix)
                [File_Table,Skip_Folder]=Check_Rec_Files(Obs_Folder,File_Prefix,Obs_Type);
                %For vid being looked at, find out if it needs shifting more than
                %300 pixels. If yes, then say its the new master frame, or ignore
                %the problem.

                for Letter_Num=1:3
                    Letter=Letters(Letter_Num);
                    disp(Letter)
                    if File_Table{2}{1,Letter}&&File_Table{2}{2,Letter}&&~File_Table{2}{3,Letter}
                        Read_Cam= VideoReader(File_Table{1}{2,Letter}); %Read Cam-Letter.mp4
                        clf
                        Frame = read(Read_Cam, 2000); % 500th frame of Cam-Letter.mp4
                        Frame= imresize(Frame,[1002,1776]); % Resize video frame to whats accepted by Deep Lab Cut
                        Frame = rgb2gray(Frame);
                        Unshifted=Frame;

                        % saveas(gcf,fullfile(Analysis_Folder,File_Prefix+"-Alignment_Preshift-"+Letter+".svg"),'svg')
                        try
                            Closest_Frame = Find_Closest_Frame(Date_Prefix,Letter);
                            load(Closest_Frame,'Master_Frame')
                            correlation = normxcorr2(Master_Frame, Frame);
                            [~, max_index] = max(abs(correlation(:)));
                            [ypeak, xpeak] = ind2sub(size(correlation), max_index(1));
                            Fy_offset = ypeak - size(Master_Frame, 1);
                            Fx_offset = xpeak - size(Master_Frame, 2);
                            Frame=imtranslate(Frame, [-Fx_offset, -Fy_offset]);
                            if abs(Fy_offset)>300 || abs(Fx_offset)>300
                                nexttile
                                image(Unshifted) % Show comparison of images before shift
                                hold on
                                title("Unshifted")
                                hold off
                                nexttile
                                image(Frame)  % Show comparison of images after shift
                                title("Shifted Frame")
                                nexttile
                                image(Master_Frame)
                                title("Master Frame")
                                Create_Master_Frame(Date_Prefix,Unshifted,Letter)
                            end
                        catch
                            nexttile
                            image(Unshifted) % Show comparison of images before shift
                            hold on
                            title("Unshifted")
                            hold off
                            nexttile
                            image(Frame)  % Show comparison of images after shift
                            title("Shifted Frame")
                            nexttile
                            image(Master_Frame)
                            title("Master Frame")
                            Create_Master_Frame(Date_Prefix,Unshifted,Letter)
                        end
                    end
                end

            end
        end
    end
end


function [FilePrefix,DatePrefix,FileIDs,Obs_Type]=Breakup_Title_Exp_Folder(ExpFolder)
%Obs_Type
%0 means test
%1 means social
%2 means habituation
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
else
    Obs_Type=2;
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
    for II=1:Number_Rows
        Existance_Table(II,Letter)={exist(Name_Table{II,Letter},"file")==2};
    end
end
Name_Table(1,"Extra")={fullfile(Rec_Folder,File_Prefix+"-Stamp.wav")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(2,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Social_Data.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(3,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Summary_Social.svg")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(4,"Extra")={fullfile(Rec_Folder,File_Prefix+"-Signal_Tracking.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(5,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Motif_Coord-M1.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(6,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Motif_Coord-M2.mat")}; %Coordinate Processor data, showing all F view videos have been processed.
Name_Table(7,"Extra")={fullfile(Rec_Folder,"Analysis",File_Prefix+"-Symphony.h5")}; %Coordinate Processor data, showing all F view videos have been processed.

for II=1:Number_Rows
    Existance_Table(II,"Extra")={exist(Name_Table{II,"Extra"},"file")==2};
end

Name_Existance_Table={Name_Table,Existance_Table};
if Obs_Type==1
    Skip_Folder=sum(Existance_Table{:,:},'all')==26;
else
    Skip_Folder=sum(Existance_Table{:,:},'all')==24;
end

end

function [Female_Folders,FS,Letters]=Part_Zero(Working_Dir)
Female_Folders=dir(Working_Dir+"/F_*"); %Select specific or general female folders
Female_Folders(~[Female_Folders(:).isdir])=[]; %Remove files from list
% Female_Folders=Female_Folders(7);
FS=48000;   %Set sampling rate of NIDAQ substitute
Letters=["F","M1","M2"];
warning('off','MATLAB:table:RowsAddedExistingVars')
end

function FullAddress=Find_File_Wild(File_Name,Folder)
FullAddress=fullfile(Folder,string(ls(fullfile(Folder,File_Name))));
end
