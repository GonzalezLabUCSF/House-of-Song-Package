cd("A:\HOS_Package_V4\")
Folders=dir("Perch*");
for I=1:size(Folders,1)
    Exp_Files=dir(fullfile(Folders(I).folder,Folders(I).name,"*.txt")); %Discover all folders in the Female folder
    Exp_Files([Exp_Files(:).isdir])=[]; %Remove folders from list
    for II=1:size(Exp_Files,1)
        Old=fullfile(Exp_Files(II).folder,Exp_Files(II).name);
        disp(Old)
        New=replace(Old,".txt",".json");
        disp(New)
        movefile(Old,New,"f")
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