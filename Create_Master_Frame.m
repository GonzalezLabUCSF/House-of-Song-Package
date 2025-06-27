% Select video you would like to use to create a master frame.
function Create_Master_Frame(Date_Prefix,Master_Frame,Letter)
Filter_Folder="./Perch_Filters";
Master_Frame_Folder="./Master_Frames";
clf
image(Master_Frame)
if Letter=="M2"||Letter=="M1"
    PushBullet = pbNotify('o.0Yzyja3vaXct6GNCk73Lcx9tpixvlmNb'); % Initialize PushBullet for notifications;
    PushBullet.notify('Come back to select master frame.')
    Satisfaction=0;
    while Satisfaction==0
        title("Select F perching region")
        F_Region = drawrectangle('Label','F','Color',[1 1 0]);
        F_Region=single(fix(F_Region.Position));
        title("Select M perching region")
        rect_M=drawrectangle('Label','M','Color',[0 1 1]);
        rect_M=single(fix(rect_M.Position));
        Satisfaction=input("Satisfied? 1 Yes 0 No ");
    end
    Closest_Filter = Find_Closest_Filter(Date_Prefix);
    % Read the JSON file as a string
    try

        jsonText = fileread(Closest_Filter);
    catch
        jsonText = fileread("./Perch_Filters/Perch_Filter_Template.txt");
    end
    data = jsondecode(jsonText);
    if Letter=="M1"
        data.FM1YMax=F_Region(2)+F_Region(4);
        data.FM1YMin=F_Region(2);
        data.FM1XMax=F_Region(1)+F_Region(3);
        data.FM1XMin=F_Region(1);
        data.M1YMax=rect_M(2)+rect_M(4);
        data.M1YMin=rect_M(2);
        data.M1XMax=rect_M(1)+rect_M(3);
        data.M1XMin=rect_M(1);
    elseif Letter=="M2"
        data.FM2YMax=F_Region(2)+F_Region(4);
        data.FM2YMin=F_Region(2);
        data.FM2XMax=F_Region(1)+F_Region(3);
        data.FM2XMin=F_Region(1);
        data.M2YMax=rect_M(2)+rect_M(4);
        data.M2YMin=rect_M(2);
        data.M2XMax=rect_M(1)+rect_M(3);
        data.M2XMin=rect_M(1);
    end
    Encoded_Data=jsonencode(data);
    fid = fopen(fullfile(Filter_Folder,Date_Prefix+".json"),'w');
    fprintf(fid,'%s',Encoded_Data);
    fclose(fid);
end
clf
image(Master_Frame)
%Save image to use for future image correction.
save(fullfile(Master_Frame_Folder,Date_Prefix+"-Frame_Correction-"+Letter+".mat"),'Master_Frame')
clf
end