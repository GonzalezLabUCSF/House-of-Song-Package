function Closest_File = Find_Closest_Filter(Date_Prefix)
Filter_Folder="./Perch_Filters";
% Convert target string to datetime
Obs_Time = datetime(Date_Prefix, 'InputFormat', 'yyyy_MM_dd_HH_mm');
Filter_List=dir(Filter_Folder+"/20*");
Filter_List([Filter_List(:).isdir])=[];
Filter_List=string({Filter_List.name});
% Initialize minimum difference and result
Minimum_Diff = Inf;
Closest_File = '';

% Loop through all filter names
for I = 1:length(Filter_List)
    Filter_Name = Filter_List(I);
    Filter_Name=split(Filter_Name,".");
    Filter_Name=Filter_Name(1);

    try
        Filter_Time = datetime(Filter_Name, 'InputFormat', 'yyyy_MM_dd_HH_mm');
    catch
        continue; % Skip malformed date strings
    end
    if Filter_Time <= Obs_Time
        Difference = seconds(Obs_Time - Filter_Time);
        if Difference < Minimum_Diff
            Minimum_Diff = Difference;
            Closest_File = fullfile(Filter_Folder,Filter_Name+".json");
        end
    end
end
if Closest_File==''
    error("No filter found younger than current video. Please manually create json file.")
end
end