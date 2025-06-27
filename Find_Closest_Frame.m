function Closest_File = Find_Closest_Frame(Date_Prefix,Letter)
Frame_Folder="./Master_Frames";
% Convert target string to datetime
Obs_Time = datetime(Date_Prefix, 'InputFormat', 'yyyy_MM_dd_HH_mm');
Frame_List=dir(Frame_Folder+"/20*"+Letter+"*");
Frame_List([Frame_List(:).isdir])=[];
Frame_List=string({Frame_List.name});
% Initialize minimum difference and result
Minimum_Diff = Inf;

% Loop through all filter names
for I = 1:length(Frame_List)
    File_Name = Frame_List(I);
    File_Time=split(File_Name,"-");
    File_Letter=split(File_Time(3),".");
    File_Letter=File_Letter(1);
    File_Time=File_Time(1);
    try
        Filter_Time = datetime(File_Time, 'InputFormat', 'yyyy_MM_dd_HH_mm');
    catch
        continue; % Skip malformed date strings
    end
    if Filter_Time <= Obs_Time && File_Letter==Letter
        Difference = seconds(Obs_Time - Filter_Time);
        if Difference < Minimum_Diff
            Minimum_Diff = Difference;
            Closest_File = fullfile(Frame_Folder,File_Name);
        end
    end
end

end