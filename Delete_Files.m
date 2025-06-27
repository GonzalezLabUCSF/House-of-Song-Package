Cohort_Folders=dir(fullfile("\\GERRIKLABCOMP\a\HOS_Cohorts\Cohort*")); %Select specific or general female folders
% 
% Female_Folders(~[Female_Folders(:).isdir])=[];
% Folders=dir("20*");
% Female_Folders="E:/"+Female_IDS;

for I=1:size(Cohort_Folders,1) %Which female we are looking a
    disp(Cohort_Folders(I).name)
    Female_Folders=dir(fullfile(Cohort_Folders(I).folder,Cohort_Folders(I).name,"F*"));
    for II=1:size(Female_Folders,1)
        disp(Female_Folders(II).name)
        Obs_Folders=dir(fullfile(Female_Folders(II).folder,Female_Folders(II).name,"20*"));
        for III=1:size(Obs_Folders,1) %which experiment of the female we are looking at
            disp(Obs_Folders(III).name)
            % mkdir(fullfile(Obs_Folders(III).folder,Obs_Folders(III).name,"Analysis"))
            Exp_Files=dir(fullfile(Obs_Folders(III).folder,Obs_Folders(III).name,"*-Alignment_Signal_N_Shift*"));
            Exp_Files([Exp_Files(:).isdir])=[]; %Remove folders from list
            if ~isempty(Exp_Files)
                for VI=1:size(Exp_Files,1)
                    Old=fullfile(Exp_Files(VI).folder,Exp_Files(VI).name);
                    disp(Old)
                    New=fullfile(Exp_Files(VI).folder,"Analysis",Exp_Files(VI).name);
                    % delete(Old)
                    movefile(Old,New)
                end
            end
        end
    end
end

function [FilePrefix,DatePrefix,FileIDs,Obs_Type,Social_Group]=Breakup_Title_Exp_Folder(ExpFolder)
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
Social_Group=FilePrefix(2);
FilePrefix=string(ExpFolder);
if (FileIDs(1)=="") && ((FileIDs(2)=="")&&(FileIDs(3)==""))
    Obs_Type=0;
elseif (FileIDs(1)~="") && ((FileIDs(2)~="")&&(FileIDs(3)~=""))
    Obs_Type=1;
else
    Obs_Type=2;
end
end