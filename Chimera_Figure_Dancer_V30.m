%% Part Zero, Init all constants and select birds to analyze
clc
clear
close all
pb0 = pbNotify('o.0Yzyja3vaXct6GNCk73Lcx9tpixvlmNb');%Ease of use. Which phone gets notifications.
[HOS_X_Range,HOS_Y_Range,Max_Dist_Pix,Pixels_Per_Cm,HOS_x_cm_Range,HOS_y_cm_Range,Aggregate_Analysis,Max_Num_Birds,Coord_Thresh,Mic_Thresh,Points_per_Bird,BirdIndx_FView,BirdIndx_MView]=Init_Constants();
[Meta_Hab,Meta_Exp]=Init_Meta();

warning('on', 'backtrace')
Female_IDS=["F_LB211"];
Female_Folders="E:/"+Female_IDS;
Female_Folder_Selection=1;
Motif_Folders="D:\Lab Dropbox\BirdSong\BirdData_2024";

for I=Female_Folder_Selection %Which female we are looking a
    disp(Female_Folders(I))
    Female_Aggregate_Folder=fullfile(Female_Folders(I),Female_IDS(I)+"-Aggregate_Analysis");
    Obs_Folders=dir(fullfile(Female_Folders(I),"20*"));
    [Hab,Exp,NUM_Hab,NUM_Exp]=Init_Hab_Exp();
    for II=2:size(Obs_Folders,1) %which experiment of the female we are looking at
        clf
        Obs_Folder=fullfile(Obs_Folders(II).folder,Obs_Folders(II).name);
        disp(Obs_Folder)
        Obs_Analysis_Folder=fullfile(Obs_Folder,"Analysis");
        Bird_Coord_File=fullfile(Obs_Analysis_Folder,ls(fullfile(Obs_Analysis_Folder,"*-Bird_Coord.mat")));
        [File_Prefix,Date_Prefix,File_IDs,Obs_Type]=Breakup_Title_Exp_Folder(Obs_Folders(II).name);
        %If cannot load the Bird_Coord file, then skip it and replace its
        %frame in the analysis with zeros.
        try
            load(Bird_Coord_File,'Bird_Coord','Num_Frames','Lost_Frames','Lost_Points');
            disp("Loading coordinate data from"+newline+Bird_Coord_File)
        catch
            if Obs_Type==1
                Exp.Lost_Points=cat(3,Exp.Lost_Points,zeros(3,5));
                Exp.Lost_Frames=cat(1,Exp.Lost_Frames,[0,0,0]);
                Exp.BirdCoord=cat(3,Exp.BirdCoord,zeros(40,48));
                Exp.XAxis_Dat=cat(1,Exp.XAxis_Dat,[zeros(1,13)]);
                Exp.Choice=cat(1,Exp.Choice,[0,0,0,0]);
                Exp.Distance.F=cat(1,Exp.Distance.F,zeros(1,15));
                Exp.Distance.M1=cat(1,Exp.Distance.M1,zeros(1,15));
                Exp.Distance.M2=cat(1,Exp.Distance.M2,zeros(1,15));
                Exp.Prefix=cat(1,Exp.Prefix,File_Prefix+"Error");
            elseif Obs_Type==2
                Hab.Lost_Points=cat(3,Exp.Lost_Points,zeros(3,5));
                Hab.Lost_Frames=cat(1,Exp.Lost_Frames,[0,0,0]);
                Hab.BirdCoord=cat(3,Hab.BirdCoord,zeros(40,48));
                Hab.XAxis_Dat=cat(1,Hab.XAxis_Dat,[zeros(1,13)]);
                Hab.Choice=cat(1,Hab.Choice,[0,0,0,0]);
                Hab.Distance.F=cat(1,Hab.Distance.F,zeros(1,15));
                Hab.Distance.M1=cat(1,Hab.Distance.M1,zeros(1,15));
                Hab.Distance.M2=cat(1,Hab.Distance.M2,zeros(1,15));
                Hab.Prefix=cat(1,Hab.Prefix,File_Prefix+"Error");
            end
            continue
        end

        %Check if data is Hab or Exp
        if File_IDs(1)=="" %If there was no female, then its a habituation of males.
            tiledlayout(3,2)
            nexttile(1)
            %M1 Motif
            MicTemplate_Address=fullfile(Motif_Folders,File_IDs(2),"mic_template.mat");
            Show_Motif(File_IDs(2),MicTemplate_Address,1)
            title(File_IDs(2))
            nexttile(2)
            Motif_Coord_File=fullfile(Obs_Analysis_Folder,File_Prefix+"Motif_Coord_M1.mat");
            load(Motif_Coord_File,'Motif_Coord_Mid')
            Show_Start_Mic(File_IDs(2),Obs_Folder,1,Motif_Coord_Mid)
            nexttile(3)
            %Show_Start_Mic(MaleID,ExpFolder,Mic_Num,Motif_Coords)
            [Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges]=Create_Song_Time_Histogram(Motif_Coord_File);

            %M2 Motif
            nexttile(4)
            Show_Motif(File_IDs(3),M1_Motif_File,1)
            title(File_IDs(3))
            nexttile(5)
            Motif_Coord_File=fullfile(Obs_Analysis_Folder,File_Prefix+"Motif_Coord_M2.mat");
            load(Motif_Coord_File,'Motif_Coord_Mid')
            Show_Start_Mic(File_IDs(3),Obs_Folder,2,Motif_Coord_Mid)
            nexttile(6)
            [Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges]=Create_Song_Time_Histogram(Motif_Coord_File);
            saveas(gcf,fullfile(Obs_Analysis_Folder,File_Prefix+"-Summary_Social.svg"),'svg')
            continue
            % Exp.XAxis.Labels=cell(1);
            % Exp.Choice.Data=[0,0,0,0];
            % Exp.Choice.Labels=cell(1);
            % Exp.M1Motif.Data=cell(1);
            % Exp.M1Motif.Labels
            % Exp.M2Motif.Data=cell(1);
            % Exp.M2Motif.Labels=cell(1);
            % Exp.Distance.Data=cell(1);
            % Exp.Distance.Labels=cell(1);
        end


        % tiledlayout(6,6)
        %tile layout
        % 1     2     3     4     5     6
        % 7     8     9    10    11    12
        % 13    14    15    16    17    18
        % 19    20    21    22    23    24
        % 25    26    27    28    29    30
        % 31    32    33    34    35    36

        % Observation Data  MotifM1                 			MotifM2
        % 2DHistogram       StartSing(Mark motif)   			StartSing(Mark motif)
        % 2DHistogram       When Sang Across Time		        When Sang Across Time
        % X axis Loc        Conditions of signing			    Conditions of signing
        % Travel distance   Distance from Female (Mark Motif)	Distance from Female (Mark Motif)

        % nexttile(7,[2,2])
        set(gcf, 'Position', get(0, 'Screensize'))
        Hist_Values=Create_histo_2_bird(Bird_Coord(:,1),Bird_Coord(:,2),HOS_X_Range,HOS_Y_Range,Date_Prefix,File_IDs,"Location % and path",1);
        saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image1.svg",'svg')
        clf
        %Display data
        % annotation('textbox',[0.05 0.95 0 0],'String',[ replace(File_Prefix,"_"," "),...
        %     "Num Frames "+num2str(Num_Frames,3),"Lost Frames "+num2str(Lost_Frames,3), ...
        %     "Lost Points: Beak, Head, Body, Tail base, Tail tip", "%F  "+num2str((Lost_Points(1,:)/Num_Frames)*100,3),"%M1 "+num2str((Lost_Points(2,:)/Num_Frames)*100,3),"%M2 "+num2str((Lost_Points(3,:)/Num_Frames)*100,3)],...
        %     'FitBoxToText','on','Color','red');
        % nexttile(19,[1,2])
        [XHistogram_Values,Histogram_Label]=Create_X_Axis_Histogram(Bird_Coord(:,1),Pixels_Per_Cm,File_IDs);
        saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image2.svg",'svg')
        clf
        % nexttile(25,[1,2])
        Choice_Bar_Values=Create_Choice_Percent_Bars(Bird_Coord(:,1:2),Bird_Coord_File,BirdIndx_FView,Date_Prefix,File_IDs);
         saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image3.svg",'svg')
        clf
        % nexttile(31,[1,2])
        Dist_Bar_Values=Create_Dist_Histogram(Bird_Coord(:,1:2),File_IDs(1)); %F
         saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image4.svg",'svg')
        clf
        if Obs_Type==1
            if NUM_Exp>8
                Exp.Distance.DataF(NUM_Exp,:)=reshape(Dist_Bar_Values,1,15);
                continue
            else
                NUM_Exp=NUM_Exp+1;
            end
            % M1
            MicTemplate_Address=fullfile(Motif_Folders,File_IDs(2),"mic_template.mat");
            Motif_Coord_File=fullfile(Obs_Analysis_Folder,File_Prefix+"-Motif_Coord-M1.mat");
            load(Motif_Coord_File,'Motif_Coord_Mid')


            % nexttile(3,[1,2])
            Show_Motif(File_IDs(2),MicTemplate_Address,1)
            saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image5.svg",'svg')
            clf
            % nexttile(9,[1,2])
            Show_Start_Mic(File_IDs(2),Obs_Folder,1,Motif_Coord_Mid)
            saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image6.svg",'svg')
            clf
            % nexttile(15,[1,2])
            [Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges]=Create_Song_Time_Histogram(Motif_Coord_File);
            Create_Dist_Plot(Bird_Coord,1,Max_Dist_Pix,Pixels_Per_Cm,Motif_Coord_Hist_Values)%M1 function Show_When_Sung(MotifsCoords,SizeMic,Rate,IDs)
            saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image7.svg",'svg')
            clf
            % 
            % nexttile(27,[1,2])
            % 
            % 
            % nexttile(33,[1,2])
            Dist_Bar_Values=Create_Dist_Histogram(Bird_Coord(:,3:4),File_IDs(2));
            saveas(gcf,"D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image8.svg",'svg')
            clf
            Exp.Distance.DataM1(NUM_Exp,:)=reshape(Dist_Bar_Values,1,15);

            %M2
            MicTemplate_Address=fullfile(Motif_Folders,File_IDs(3),"mic_template.mat");
            Motif_Coord_File=fullfile(Obs_Analysis_Folder,File_Prefix+"-Motif_Coord-M2.mat");
            load(Motif_Coord_File,'Motif_Coord_Mid')

            nexttile(5,[1,2])
            Show_Motif(File_IDs(3),MicTemplate_Address,2)

            nexttile(11,[1,2])
            Show_Start_Mic(File_IDs(3),Obs_Folder,2,Motif_Coord_Mid)

            nexttile(17,[1,2])
            [Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges]=Create_Song_Time_Histogram(Motif_Coord_File);
            Create_Dist_Plot(Bird_Coord,2,Max_Dist_Pix,Pixels_Per_Cm,Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges)

            nexttile(29,[1,2])
            Show_Directed_Vs_Undirected()

            nexttile(29,[1,2])
            
            nexttile(35,[1,2])
            Dist_Bar_Values=Create_Dist_Histogram(Bird_Coord(:,5:6),File_IDs(3));
            %If hab, add to Exp file list.
            Exp.Lost_Points=Exp.Lost_Points+Lost_Points;
            Exp.Lost_Frames=Exp.Lost_Frames+Lost_Frames;
            Exp.BirdCoord(:,:,NUM_Exp)=Hist_Values';
            Exp.Num_Frames=Exp.Num_Frames+Num_Frames;
            Exp.XAxis_Dat(NUM_Exp,:)=XHistogram_Values;
            Exp.Choice(NUM_Exp,:)=Choice_Bar_Values;
            Exp.Distance.DataM2(NUM_Exp,:)=reshape(Dist_Bar_Values,1,15);
            % Exp.M1Motif.Data=cat(3,Exp.Lost_Points,Lost_Points);
            % Exp.M2Motif.Data=cat(3,Exp.Lost_Points,Lost_Points);
            Exp.Prefix(NUM_Exp,:)=File_Prefix;
        else
            if NUM_Hab>32
                continue
            else
                NUM_Hab=NUM_Hab+1;
            end
            Hab.Lost_Points=Hab.Lost_Points+Lost_Points;
            Hab.Lost_Frames=Hab.Lost_Frames+Lost_Frames;
            Hab.Num_Frames=Hab.Num_Frames+Num_Frames;
            Hab.BirdCoord(:,:,NUM_Hab)=Hist_Values';
            Hab.XAxis_Dat(NUM_Hab,:)=XHistogram_Values;
            Hab.Choice(NUM_Hab,:)=Choice_Bar_Values;
            % Exp.M1Motif.Data=cat(3,Exp.Lost_Points,Lost_Points);
            % Exp.M2Motif.Data=cat(3,Exp.Lost_Points,Lost_Points);
            Hab.DistanceF(NUM_Hab,:)=Dist_Bar_Values';
            Hab.Prefix=cat(1,Hab.Prefix,File_Prefix);
        end
        % save(fullfile(Obs_Analysis_Folder,"Social_Data.mat"),"Hist_Values","XHistogram_Values","Choice_Bar_Values","Dist_Bar_Values","-v7.3")
        % saveas(gcf,fullfile(Obs_Analysis_Folder,File_Prefix+"-Summary_Social.svg"),'svg')
    end

    clf
    %% Aggregate
    if ~isempty(Hab)
        %Remove place holder values


        tiledlayout(6,6)
        %tile layout
        % 1     2     3     4     5     6
        % 7     8     9    10    11    12
        % 13    14    15    16    17    18
        % 19    20    21    22    23    24
        % 25    26    27    28    29    30
        % 31    32    33    34    35    36
        annotation('textbox',[0.05 0.95 0 0],'String',...
            [Female_IDS(I),"Num Frames "+num2str(Hab.Num_Frames,3),"Lost Frames "+num2str(Hab.Lost_Frames,3), ...
            "Lost Points: Beak, Head, Body, Tail base, Tail tip", "%F  "+num2str((Hab.Lost_Points(1,:)/Hab.Num_Frames)*100,3),"%M1 "+num2str((Hab.Lost_Points(2,:)/Hab.Num_Frames)*100,3),"%M2 "+num2str((Hab.Lost_Points(3,:)/Hab.Num_Frames)*100,3)],...
            'FitBoxToText','on','Color','red');
        nexttile(7,[2,2])
        Hist_Vals=Create_histo_2_bird_Summary(Hab.BirdCoord,Female_IDS(I),0);
        nexttile(19,[3,2])
        Create_X_Axis_Histogram_Summary(Hab.XAxis_Dat,Hab.Prefix,0);
        nexttile(3,[6,2])
        Choice_Summ=Create_Choice_Percent_Summary(Hab.Choice,Hab.Prefix,0);
        nexttile(5,[6,2])
        Dist_Hist=Create_Dist_Histogram_Summary(Hab.DistanceF,Hab.Prefix,0); %F
        set(gcf, 'Position', get(0, 'Screensize'))
        saveas(gcf,fullfile("D:\Lab Dropbox\Shared_Gerrik\Code\DLC_coordinates\Image11.svg","Habituation_Summary_Social.svg"),'svg')
        clf

        Meta_Hab.Lost_Points=Meta_Hab.Lost_Points+Lost_Points;
        Meta_Hab.Lost_Frames=Meta_Hab.Lost_Frames+Hab.Lost_Frames;
        Meta_Hab.Num_Frames=Meta_Hab.Num_Frames+Hab.Num_Frames;
        Meta_Hab.BirdCoord=cat(3,Meta_Hab.BirdCoord,Hist_Vals);
        Meta_Hab.XAxis_Dat=cat(3,Meta_Hab.XAxis_Dat,Hab.XAxis_Dat);
        Meta_Hab.Choice=cat(3,Meta_Hab.Choice,Choice_Summ);
        Meta_Hab.DistanceF=cat(3,Meta_Hab.DistanceF,Dist_Hist);
    end

    %Create experiment summary
    if ~isempty(Exp)
        tiledlayout(6,6)

        % Lost_Frames=sum(Exp.Lost_Frames,1);
        annotation('textbox',[0.05 0.95 0 0],'String',["Num Frames "+num2str(Exp.Num_Frames,3),"Lost Frames "+num2str(Lost_Frames,3), ...
            "Lost Points: Beak, Head, Body, Tail base, Tail tip", "%F  "+num2str((Lost_Points(1,:)/Exp.Num_Frames)*100,3),"%M1 "+num2str((Lost_Points(2,:)/Exp.Num_Frames)*100,3),"%M2 "+num2str((Lost_Points(3,:)/Exp.Num_Frames)*100,3)],...
            'FitBoxToText','on','Color','red');
        tiledlayout(6,6)
        %tile layout
        % 1     2     3     4     5     6
        % 7     8     9    10    11    12
        % 13    14    15    16    17    18
        % 19    20    21    22    23    24
        % 25    26    27    28    29    30
        % 31    32    33    34    35    36
        nexttile(7,[2,2])
        Hist_Vals=Create_histo_2_bird_Summary(Exp.BirdCoord,Female_IDS(I),1);
        %Display data
        nexttile(19,[3,2])
        Create_X_Axis_Histogram_Summary(Exp.XAxis_Dat,Exp.Prefix,1);
        nexttile(3,[6,2])
        Choice_Summ=Create_Choice_Percent_Summary(Exp.Choice,Exp.Prefix,1);
        nexttile(5,[6,2])
        Dist_Hist=Create_Dist_Histogram_Summary(Exp.Distance.DataF,Exp.Prefix,1); %F
        set(gcf, 'Position', get(0, 'Screensize'))
        saveas(gcf,fullfile(Female_Aggregate_Folder,"Experimentation_Summary_Social.svg"),'svg')
        clf
        Meta_Exp.Lost_Points=Meta_Exp.Lost_Points+Exp.Lost_Points;
        Meta_Exp.Lost_Frames=Meta_Exp.Lost_Frames+Exp.Lost_Frames;
        Meta_Exp.Num_Frames=Meta_Exp.Num_Frames+Exp.Num_Frames;
        Meta_Exp.BirdCoord=cat(3,Meta_Exp.BirdCoord,Hist_Vals);
        Meta_Exp.XAxis_Dat=cat(3,Meta_Exp.XAxis_Dat,Exp.XAxis_Dat);
        Meta_Exp.Choice=cat(3,Meta_Exp.Choice,Choice_Summ);
        Meta_Exp.Distance.DataF=cat(3,Meta_Exp.Distance.DataF,Dist_Hist);
    end
end
clear Bird_Coord Hab Exp
clf

% Met_Hab.Lost_Frames(1,:)=[];
% Met_Hab.Lost_Points(:,:,1)=[];
% Met_Hab.BirdCoord(:,:,1)=[];
% Met_Hab.XAxis_Dat(:,:,1)=[];
% Met_Hab.Choice(:,:,1)=[];
% Met_Hab.DistanceF(:,:,1)=[];
% Met_Exp.Distance.DataF(:,:,1)=[];
%
% Met_Exp.Lost_Frames(1,:)=[];
% Met_Exp.Lost_Points(:,:,1)=[];
% Met_Exp.BirdCoord(:,:,1)=[];
% Met_Exp.XAxis_Dat(:,:,1)=[];
% Met_Exp.Choice(:,:,1)=[];
% Met_Exp.DistanceF(:,:,1)=[];
tiledlayout(6,6)
%tile layout
% 1     2     3     4     5     6
% 7     8     9    10    11    12
% 13    14    15    16    17    18
% 19    20    21    22    23    24
% 25    26    27    28    29    30
% 31    32    33    34    35    36

annotation('textbox',[0.1 0.65 0 0],'String',["Num Frames "+num2str(Meta_Hab.Num_Frames,3),"Lost Frames "+num2str(Meta_Hab.Lost_Frames,3), ...
    "Lost Points: Beak, Head, Body, Tail base, Tail tip", "%F  "+num2str((Meta_Hab.Lost_Points(1,:)/Num_Frames)*100,3),"%M1 "+num2str((Meta_Hab.Lost_Points(2,:)/Meta_Hab.Num_Frames)*100,3),"%M2 "+num2str((Meta_Hab.Lost_Points(3,:)/Meta_Hab.Num_Frames)*100,3)],...
    'FitBoxToText','on','Color','red');
nexttile(1,[2,2])
[~]=Create_histo_2_bird_Summary(mean(Meta_Hab.BirdCoord,3),"All",0);
%Display data
nexttile(19,[3,2])
Create_X_Axis_Histogram_Summary(mean(Meta_Hab.XAxis_Dat,3),NaN,0);
nexttile(3,[6,2])
[~]=Create_Choice_Percent_Summary(mean(Meta_Hab.Choice,3),NaN,0);
nexttile(5,[6,2])
[~]=Create_Dist_Histogram_Summary(mean(Meta_Hab.DistanceF,3),NaN,0); %F
set(gcf, 'Position', get(0, 'Screensize'))
saveas(gcf,fullfile(Aggregate_Analysis,"Habituation_Summary_Social.svg"),'svg')
clf

tiledlayout(6,6)
annotation('textbox',[0.1 0.65 0 0],'String',["Num Frames "+num2str(Meta_Exp.Num_Frames,3),"Lost Frames "+num2str(Meta_Exp.Lost_Frames,3), ...
    "Lost Points: Beak, Head, Body, Tail base, Tail tip", "%F  "+num2str((Meta_Exp.Lost_Points(1,:)/Num_Frames)*100,3),"%M1 "+num2str((Meta_Exp.Lost_Points(2,:)/Meta_Exp.Num_Frames)*100,3),"%M2 "+num2str((Meta_Exp.Lost_Points(3,:)/Meta_Exp.Num_Frames)*100,3)],...
    'FitBoxToText','on','Color','red');
nexttile(1,[2,2])
[~]=Create_histo_2_bird_Summary(mean(Meta_Exp.BirdCoord,3),"All",1);
%Display data
nexttile(19,[3,2])
Create_X_Axis_Histogram_Summary(mean(Meta_Exp.XAxis_Dat,3),NaN,0);
nexttile(3,[6,2])
[~]=Create_Choice_Percent_Summary(mean(Meta_Exp.Choice,3),NaN,0);
nexttile(5,[6,2])
[~]=Create_Dist_Histogram_Summary(mean(Meta_Exp.Distance.DataF,3),NaN,0); %F
set(gcf, 'Position', get(0, 'Screensize'))
saveas(gcf,fullfile(Aggregate_Analysis,"Experimentation_Summary_Social.svg"),'svg')

pb0.notify('Done creating graphs');

%% Setup Functions
%F or M % ID number

function [FilePrefix,DatePrefix,FileIDs,Obs_Type]=Breakup_Title_Exp_Folder(ExpFolder)

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
    Obs_Type=0; %Test
elseif (FileIDs(1)~="") && ((FileIDs(2)~="")&&(FileIDs(3)~=""))
    Obs_Type=1; %Social
else
    Obs_Type=2; %Habituation
end
end

%% Position Functions

function [Output]=Window_Sum_Data_Before_And_Between_Indc(Data,Window,Points)
if ~rem(Window,2)==0
    WinBnd=Window-1;
else
    WinBnd=Window;
end

Output=NaN;
LOW=NaN;
for I=Points
    if (I-WinBnd)<1
        Low=1;
    else
        Low=I-WinBnd;
    end
    if I>height(Data)
        Hi=height(Data);
    else
        Hi=I;
    end
    if isnan(Output)
        Output=sum(Data(fix(Low):fix(Hi)),"omitnan");
    else
        Output=cat(1,Output,sum(Data(fix(Low):fix(Hi)),"omitnan"));
    end
    if isnan(LOW)
        LOW=Low;
    else
        LOW=cat(1,LOW,Low);
    end
end
end

function HistValues=Create_histo_2_bird(X,Y,Xedges,Yedges,DatE,IDs,Title,PlotPath)

HIST=histogram2(X,Y,'XBinEdges',Xedges,'YBinEdges',Yedges,'Displaystyle','tile','Normalization','percentage','EdgeColor','black','LineStyle','none',"ShowEmptyBins","on");
%relative percentage, The percentage of elements in each bin is at most 100.
hold on
HistValues=HIST.Values;
if PlotPath
    plot(X,Y,Color="red",LineWidth=0.01)
end
% if length(IDs)>1
%     % title([replace(DatE,"_"," "),"F "+IDs(4)+" M1 "+IDs(5)+" M2 "+IDs(6)+" "+Title+"bin10x20 pixels"])
% else
%     % title([replace(DatE,"_"," "),"F "+IDs(1)+Title+"bin10x20 pixels"])
% end
GCA_Fig=gca;
xlabel('Length HOS (cm)')
ylabel('Width HOS (cm)')
Pixels_Per_cm=1002/60.96;
GCA_Fig.XTick=0:178:Xedges(end);
GCA_Fig.YTick=0:77:Yedges(end);
xticklabels(fix(GCA_Fig.XTick/Pixels_Per_cm))
GCA_Fig.XTickLabelRotation=90;
yticklabels(fix(GCA_Fig.YTick/Pixels_Per_cm))
c=colorbar();
% c.Label.String = 'Percentage of time spent';
%create Borders
Fnt_Sz=12;
Xline=linspace(0,490);
line(Xline,ones(length(Xline),1)*500,'LineStyle','-','Color','k')
Xline=linspace(1325,1776);
line(Xline,ones(length(Xline),1)*500,'LineStyle','-','Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*490,Yline,'Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*1325,Yline,'Color','k')
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*220;
line(Xline,Yline,'Color','k')%,Label="M2 perch")
Yline=linspace(670,1002);
Xline=ones(length(Yline),1)*930;
line(Xline,Yline,'Color','k')%,Label="Nut perch")
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*1580;
line(Xline,Yline,'Color','k')%,Label="M1 perch")
% % text(1500,270,"M1 Q",'FontSize',Fnt_Sz)
% if length(IDs)>1
%     text(1500,740,IDs(2),'FontSize',Fnt_Sz)
%     text(200,740,IDs(3),'FontSize',Fnt_Sz)
% end
% text(850,740,"Nutri Q",'FontSize',Fnt_Sz)
% text(850,270,"Neut Q",'FontSize',Fnt_Sz)
% text(200,270,"M2 Q",'FontSize',Fnt_Sz)
hold off
end

function [HistogramValues,HistogramLabel]=Create_X_Axis_Histogram(BirdCoord,PixelsPerCm,FileIDs)
HIST=histogram((BirdCoord-888)./PixelsPerCm,BinLimits=[-1776/(PixelsPerCm*2),1776/(PixelsPerCm*2)],NumBins=13,FaceColor="y",Normalization="percentage");
hold on
GCA_Fig=gca;
title("X axis location of "+FileIDs(1))
GCA_Fig.XLim=HIST.BinLimits;
GCA_Fig.YLim=[0,100];
GCA_Fig.XTick=HIST.BinEdges;
TEXTX=HIST.BinEdges(1:end-1)+diff(HIST.BinEdges)/2;
text(TEXTX,HIST.Values,num2str(fix(HIST.Values)',3)+"%",FontSize=8)
ll=cat(2,FileIDs(3),[string(fix(HIST.BinEdges(2:end-1)))],FileIDs(2));
GCA_Fig.XTickLabel=ll;
xline((220-888)/PixelsPerCm,Label="M2 perch")
xline((930-888)/PixelsPerCm,Label="Nutrition perch")
xline((1580-888)/PixelsPerCm,Label="M1 perch")
ylabel('Percentage time')
xlabel("Distance cm")
hold off
HistogramValues=HIST.Values;
HistogramLabel=ll;
end

function BarValues=Create_Dist_Histogram(BirdCoord,FileID)
PixelsPerCm=1002/60.96;
Fem_Dist_Travel=sqrt((diff(BirdCoord(:,1)).^2)+(diff(BirdCoord(:,2)).^2))/PixelsPerCm; %Take the magnitude of velocity between frames, and take the average sliding window of 5 points.
Indeces=linspace(1,height(BirdCoord),16);
T=diff(Indeces);
T=T(1);
[BarValues]=Window_Sum_Data_Before_And_Between_Indc(Fem_Dist_Travel,T,Indeces(2:end));
bar(BarValues);
hold on
GCA_Fig=gca;
axis tight
xlabel('Time')
ylabel('Distance (cm)')
title(FileID+" travel (cm) over time")
GCA_Fig.XTick=[0:1:numel(Indeces)];
GCA_Fig.XTickLabel=0:15;
GCA_Fig.XLim=[0,numel(Indeces)];
GCA_Fig.XTickLabelRotation=45;
text(1:numel(BarValues),BarValues,num2str(fix(BarValues),3),HorizontalAlignment="center",VerticalAlignment="bottom",FontSize=5)
hold off
end

function ChoiceBarValues=Create_Choice_Percent_Bars(BirdCoord,BirdCoordFile,BirdIndx,DatePrefix,FileIDs)
CntIndx=1;
Row_BirdIndx=1;
YGCAText=ones(1,4);
% disp("Getting coordinates from column x "+BirdIndx(Row_BirdIndx,1)+" column y "+BirdIndx(Row_BirdIndx,2))
Choice_Series=Process_Choices(BirdCoord,BirdIndx,Row_BirdIndx,replace(DatePrefix,"_"," "),CntIndx);
% Choice_Srs={FlPrfx,NaN_Cnt,Crd_Height;... %placeholder, Number of NaN, Number of coordinates=number of frames
%     M1_Choice_Adj,Neutral_Choice_Adj,M2_Choice_Adj,Nutrition_Choice_Adj;... %Adj
%     M1_Choice_LoEr,Neutral_Choice_LoEr,M2_Choice_LoEr,Nutrition_Choice_LoEr;... %Low Error for error bars
%     M1_Choice_HiEr,Neutral_Choice_HiEr,M2_Choice_HiEr,Nutrition_Choice_HiEr;...%Hi Error for error bars
%     M1_Choice,Neutral_Choice,M2_Choice,Nutrition_Choice};
%b=bar([1,2,3,4],[M1_Choice_Adj,M2_Choice_Adj,Neutral_Choice_Adj,Nutrition_Choice_Adj]);
%Plot
BAR=bar([FileIDs(3),"Neutral","Nutrition",FileIDs(2)],[Choice_Series{2,3,CntIndx},Choice_Series{2,2,CntIndx},Choice_Series{2,4,CntIndx},Choice_Series{2,1,CntIndx}]);
ChoiceBarValues=[Choice_Series{2,3,CntIndx},Choice_Series{2,2,CntIndx},Choice_Series{2,4,CntIndx},Choice_Series{2,1,CntIndx}];
% BAR=bar([" Neutral ", " Nutrition ",FileIDs(5),FileIDs(6)],[Choice_Series{2,2,CntIndx},Choice_Series{2,4,CntIndx},Choice_Series{2,1,CntIndx},Choice_Series{2,3,CntIndx}]);
% ChoiceBarValues=[Choice_Series{2,2,CntIndx},Choice_Series{2,4,CntIndx},Choice_Series{2,1,CntIndx},Choice_Series{2,3,CntIndx}];
title("Female relative stay at quadrants")
hold on
XTips1 = BAR(1).XEndPoints;
Choice_Value = compose('%.3f',BAR(1).YData*100)+"%";
GCA_Fig=gca;
GCA_Fig.YTick=0:.1:1;
GCA_Fig.YLim=[0,1];
ylabel("%Frames At Quadrant")
xlabel("Quadrants")
% title(replace(DatePrefix,"_"," ")+" Female "+replace(FileIDs(4),"_"," ")+" accounted location percentage",...
%     "Portion unaccounted for "+(Choice_Series{1,2,CntIndx}/Choice_Series{1,3,CntIndx})*100+"%")
text(XTips1,YGCAText*0.6,Choice_Value,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontSize',6)
%Neutral_Choice_LoEr Nutrition_Choice_LoEr M1_Choice_LoEr M2_Choice_LoEr
text(XTips1,YGCAText*0.3,compose('%.3f',[Choice_Series{3,[2,4,1,3],CntIndx}]*100),...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',6)
%Neutral_Choice_HiEr Nutrition_Choice_HiEr M1_Choice_LHiEr M2_Choice_HiEr
text(XTips1,YGCAText*0.9,compose('%.3f',[Choice_Series{4,[2,4,1,3],CntIndx}]*100),...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',6)
% annotation('textbox',[0 1 0 0],'String',["Upper Error Percentage of Adj %","Adj Percentage","Lower Error Percentage of Adj %","Adj=Choice/(Total Observations-Filtered Observation)"],'FitBoxToText','on','Color','red');
ER=errorbar([1,2,3,4],[Choice_Series{2,2,CntIndx},Choice_Series{2,4,CntIndx},Choice_Series{2,1,CntIndx},Choice_Series{2,3,CntIndx}],... %Adj_Val
    [Choice_Series{3,2,CntIndx},Choice_Series{3,4,CntIndx},Choice_Series{3,1,CntIndx},Choice_Series{3,3,CntIndx}],... %LoError
    [Choice_Series{4,2,CntIndx},Choice_Series{4,4,CntIndx},Choice_Series{4,1,CntIndx},Choice_Series{4,3,CntIndx}]); %HiError
ER.Color = [0 0 0];
ER.LineStyle = 'none';
hold off
save(BirdCoordFile,"Choice_Series","-append")
end

function Choice_Srs=Process_Choices(BrdCrd,BrdIndx,RwBrdIndx,FlPrfx,CntIndx)
Crd_Height=height(BrdCrd);
NaN_Cnt=nnz(isnan([BrdCrd(:,BrdIndx(RwBrdIndx,1))]));
%M1
M1_Choice=nnz([BrdCrd(:,1)]>1325);
[M1_Choice_Adj,M1_Choice_LoEr,M1_Choice_HiEr]=Calculate_choice(M1_Choice,Crd_Height,NaN_Cnt);

%M2
M2_Choice=nnz(530>[BrdCrd(:,1)]);
[M2_Choice_Adj,M2_Choice_LoEr,M2_Choice_HiEr]=Calculate_choice(M2_Choice,Crd_Height,NaN_Cnt);
% M2_Choice_Adj=M2_Choice./(Crd_Height-NaN_Cnt);
% M2_Choice_LoEr=abs(M2_Choice_Adj-(M2_Choice./Crd_Height));
% M2_Choice_HiEr=abs(M2_Choice_Adj-((M2_Choice+NaN_Cnt)./Crd_Height));

%Neutral
Neutral_Choice=nnz([[1325>[BrdCrd(:,1)]] == [[BrdCrd(:,1)]>530]]&[500>[BrdCrd(:,2)]]);
[Neutral_Choice_Adj,Neutral_Choice_LoEr,Neutral_Choice_HiEr]=Calculate_choice(Neutral_Choice,Crd_Height,NaN_Cnt);
%Nutrition
Nutrition_Choice=nnz([[1325>[BrdCrd(:,1)]] == [[BrdCrd(:,1)]>530]] & [500<[BrdCrd(:,2)]]);
[Nutrition_Choice_Adj,Nutrition_Choice_LoEr,Nutrition_Choice_HiEr]=Calculate_choice(Nutrition_Choice,Crd_Height,NaN_Cnt);

Choice_Srs={FlPrfx,NaN_Cnt,Crd_Height,CntIndx;... %placeholder, Number of NaN, Number of coordinates=number of frames
    M1_Choice_Adj,Neutral_Choice_Adj,M2_Choice_Adj,Nutrition_Choice_Adj;... %Adj
    M1_Choice_LoEr,Neutral_Choice_LoEr,M2_Choice_LoEr,Nutrition_Choice_LoEr;... %Low Error for error bars
    M1_Choice_HiEr,Neutral_Choice_HiEr,M2_Choice_HiEr,Nutrition_Choice_HiEr;...%Hi Error for error bars
    M1_Choice,Neutral_Choice,M2_Choice,Nutrition_Choice};
end

function [Adj,LoEr,HiEr]=Calculate_choice(Choice_num,HEight,NAN_Count)
Adj=Choice_num./(HEight-NAN_Count); %Percentage of time, excluding dropped coords, when M1 was chosen.
LoEr=abs(Adj-(Choice_num./(HEight))); %Percentage of time, including dropped coords, when M1 was chosen, but not during dropped coords.
HiEr=abs(Adj-((Choice_num+NAN_Count)./HEight)); %Percentage of time, including dropped coords, when M1 was chosen, but including during dropped coords
end

function Choice_Timeline=When_Choice(BrdCrd,BrdCrdFile) %M1=1, M2=2, Neutral=3, Nutrition=4
Crd_Height=height(BrdCrd);
Choice_Timeline=zeros(Crd_Height,1);
%M1
Choice_Timeline([BrdCrd(:,1)]>1325)=1;

%M2
Choice_Timeline(530>[BrdCrd(:,1)])=2;

%Neutral
Choice_Timeline([[1325>[BrdCrd(:,1)]] == [[BrdCrd(:,1)]>530]]&[500>[BrdCrd(:,2)]])=3;
%Nutrition
Choice_Timeline([[1325>[BrdCrd(:,1)]] == [[BrdCrd(:,1)]>530]] & [500<[BrdCrd(:,2)]])=4;
save(BrdCrdFile,"Choice_Timeline","-append")
end


function Create_Dist_Plot(Bird_Coords,M1orM2,Max_Dist,Pix_Cm,Hist_Values)



a = [3, 5];
    b = [4, 6];
    X_distances = abs(Bird_Coords(:,1) - Bird_Coords(:,a(M1orM2))).^2;
    Y_distances = abs(Bird_Coords(:,2) - Bird_Coords(:,b(M1orM2))).^2;
    Abs_distance = sqrt(X_distances + Y_distances) / Pix_Cm;

    % Plot setup
    Nframes = height(Bird_Coords);
    Xindeces = linspace(0, Nframes, 16);
    binEdges = Xindeces;
    binCenters = binEdges(1:end-1) + diff(binEdges)/2;
    
    % Background using imagesc
    hold on
    yRange = [0, 130]; % Y-axis background range
    % Repeat Hist_Values to create vertical banding
    imagesc('XData', binEdges, ...
            'YData', yRange, ...
            'CData', repmat(Hist_Values(:)', [2,1]), ...
            'AlphaData', 0.5);  % Optional: make background semi-transparent

    % Overlay the line plot
    plot(Abs_distance, '-k', 'LineWidth', 1.5)

    % Axis formatting
    ylabel('Distance (cm)')
    xlabel('Time (minutes)')
    title('Distance from female')
    GCA_Fig = gca;
    xticks(binEdges)
    GCA_Fig.XTickLabel = 0:15;
    yticks(0:26:round(Max_Dist/Pix_Cm,-1))
    axis tight
    GCA_Fig.YLim = yRange;
    % Colorbar
    ColorBar = colorbar;
    ColorBar.Label.String = 'Motifs detected';

    hold off

%%%%%%%%%%%%
% 
% 
% 
% 
% 
% a=[3,5];
% b=[4,6];
% 
% Nframes = height(Bird_Coords);
% Xindeces = linspace(0, Nframes, 16);
% X_Distances=abs(Bird_Coords(:,1)-Bird_Coords(:,a(M1orM2))).^2;
% Y_Distances=abs(Bird_Coords(:,2)-Bird_Coords(:,b(M1orM2))).^2;
% Abs_Distance=sqrt(X_Distances+Y_Distances)/Pix_Cm; %distance between female and male birds.
% 
% binCenters = Xindeces(1:end-1) + diff(Xindeces)/2;
% histImg = repmat(Hist_Values(:)', 20, 1);  % 20 rows
% 
% imagesc(binCenters, [0, 130], histImg);
% set(gca, 'YDir', 'normal');  % Correct Y-direction
% colormap(parula);            % Adjust colormap if needed
% c = colorbar;
% c.Label.String = 'Motifs detected';
% plot(Abs_Distance, '-k', 'LineWidth', 1.5);
% ylabel('Distance (cm)');
% xlabel('Time (minutes)');
% title("Distance from Female");
% axis tight
% 
% xticks(Xindeces);
% xticklabels(0:15);
% yticks(0:26:round(Max_Dist/Pix_Cm, -1));
% ylim([0 130]);
% 
% 
% plot(Abs_Distance,'-k')
% ylabel('Distance cm')
% xlabel('Time (minutes)')
% title("Distance from female")
% GCA_Fig=gca;
% Xindeces=linspace(0,height(Bird_Coords),16);
% xticks(Xindeces)
% GCA_Fig.XTickLabel=0:15;
% GCA_Fig.YTickLabel=0:26:130;
% yticks(0:26:round(Max_Dist/Pix_Cm,-1))
% GCA_Fig.YLim=[0,130];
% binCenters=[Xindeces(1:end-1)]+diff([Xindeces])/2;
% % Display as color strip
% imagesc(binCenters, [0,130], Hist_Values);  % y = [0 1] is just to make it visible
% ColorBar=colorbar;
% ColorBar.Label.String = 'Motifs detected';
% hold off
end
%% Song Analysis Functions

function Show_Directed_Vs_Undirected(MaleID,BirdCoord,Mic_Num)
load(BirdCoord,"Choice_Timeline","Motif_Coord") %Get data for when bird sang, and where female was.
Motif_Coord=Motif_Coord{Mic_Num};   %When motif [started, ended]
Overlap=zeros(height(Choice_Timeline),1);
for I=1:height(Motif_Coord)
    Overlap(Motif_Coord(I,1):Motif_Coord(I,2))=1;
end
TTT=hist(Choice_Timeline(Overlap),4) %classification histogram of when Bird sang and where female was.


end

function Show_Motif(MaleID,Motifile,Mic_Num)
MICCC=["M1","M2"];
load(Motifile,"mic","FS_Mic");
[MotifTemplate, F, Motif_Data] = zftftb_pretty_sonogram(mic, FS_Mic,...
    'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);
imagesc(Motif_Data,F,MotifTemplate,[prctile(MotifTemplate(:),1) max(1,prctile(MotifTemplate(:),99))])
hold on
axis tight
set(gca,'YDir','Normal')
ylabel('Frequency (Hz)')
xlabel('Time (seconds)')
title(MICCC(Mic_Num)+" "+MaleID+" Motif")
hold off
end

function Show_Start_Mic(MaleID,ExpFolder,Mic_Num,Motif_Coords) %(File_IDs(5),Exp_Folder,1)
MICCC=["M1","M2"];
Montage_File=ls(fullfile(ExpFolder,"*Mic_Montage-"+MICCC(Mic_Num))+".wav");
AudInfo=audioinfo(fullfile(ExpFolder,Montage_File));
End_Time=60*AudInfo.SampleRate;
[Mic,FS] = audioread(fullfile(ExpFolder,Montage_File),[1,End_Time]);
[MotifTemplate, F, Motif_Data] = zftftb_pretty_sonogram(Mic, FS,...
    'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);
imagesc(Motif_Data,F,MotifTemplate,[prctile(MotifTemplate(:),1) max(1,prctile(MotifTemplate(:),99))])
xline(Motif_Coords(Motif_Coords<60),'-w','LineWidth',2)
hold on
axis tight
set(gca,'YDir','Normal')
ylabel('Frequency (Hz)')
xlabel('Time (seconds)')
title(MICCC(Mic_Num)+" "+MaleID+" 1st Minute Spectrogram")
hold off
end

function [Motif_Coord_Hist_Values,Motif_Coord_Hist_Bin_Edges]=Create_Song_Time_Histogram(Motif_Coord_File)
load(Motif_Coord_File,'Motif_Coord_Mid')
Motif_Coord=histogram(Motif_Coord_Mid,'BinEdges',0:1*30:15*60);
Motif_Coord_Hist_Values=Motif_Coord.Values;
Motif_Coord_Hist_Bin_Edges=Motif_Coord.BinEdges;

% GCA_Fig=gca;
% title("When Detected Motif and Female Distance")
% xticks(30:1*60:15*60)
% GCA_Fig.XTickLabel=1:15;
% xlabel("Minutes");
% axis tight
end

%% Summary Functions [FilePrefix,DatePrefix,FileIDs,IsExp]=Breakup_Title_Exp_Folder(ExpFolder)
function Create_X_Axis_Histogram_Summary(XAxisData,FilePrefix,ISExp)
PixelsPerCm=1002/60.96;
imagesc(XAxisData,[0,100])
hold on
GCA_Fig=gca;
title("X axis location")
colorbar
GCA_Fig.XTick=1:14;
X=string(strsplit(num2str(linspace(-888,888,13)/PixelsPerCm,"%.1f+"),"+"));
X=X(1:end-1);
GCA_Fig.XTickLabel=X;
xline(1.5,Label="M2 perch",Color="r") %Open a labeled image from DeepLabCut in MS paint to confirm.
xline(6.5,Label="Nutrition perch",Color="r")
xline(12.5,Label="M1 perch",Color="r")
Xline=linspace(0,490);
line(Xline,ones(length(Xline),1)*500,'Color','k')
Xline=linspace(1325,1776);
line(Xline,ones(length(Xline),1)*500,'Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*490,Yline,'Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*1325,Yline,'Color','k')
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*220;
line(Xline,Yline,'Color','k')%,Label="M2 perch")
Yline=linspace(670,1002);
Xline=ones(length(Yline),1)*930;
line(Xline,Yline,'Color','k')%,Label="Nut perch")
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*1580;
line(Xline,Yline,'Color','k')%,Label="M1 perch")
Fnt_Sz=12;
text(1500,270,"M1 Q",'FontSize',Fnt_Sz)
if length(IDs)>1
    text(1500,740,IDs(5),'FontSize',Fnt_Sz)
    text(200,740,IDs(6),'FontSize',Fnt_Sz)
end
text(850,740,"Nutri Qu",'FontSize',Fnt_Sz)
text(850,270,"Neut Q",'FontSize',Fnt_Sz)
text(200,270,"M2 Q",'FontSize',Fnt_Sz)
if ISExp
    YLabels="";
    for B=1:height(FilePrefix)
        [~,~,FileIDs,~]=Breakup_Title_Exp_Folder(FilePrefix(B));
        YLabels=cat(1,YLabels,strjoin(FileIDs(5:6)));
    end
    YLabels(1,:)=[];
    GCA_Fig.YTickLabel=YLabels;
end
ylabel('Percentage time')
xlabel("Distance cm")
% set(GCA_Fig,'YDir','reverse')
hold off
end

function Values=Create_Choice_Percent_Summary(ChoiceData,FilePrefix,ISExp)
Values=ChoiceData;
imagesc(ChoiceData,[0,1])%already percent of time spent at each location.
hold on
GCA_Fig=gca;
if ISExp
    YLabels="";
    for B=1:height(FilePrefix)
        [~,~,FileIDs,~]=Breakup_Title_Exp_Folder(FilePrefix(B));
        YLabels=cat(1,YLabels,strjoin(FileIDs(4:6)));
    end
    YLabels(1,:)=[];
    GCA_Fig.YTickLabel=YLabels;
    ylabel("Experiment Set")
else
    ylabel("Recording Num")
end
title("Female Choice ")
colorbar
GCA_Fig.XTick=1:4;
GCA_Fig.XTickLabel=["Neutral", "Nutrition","M1","M2"];
xlabel("Choices")
hold off
end

function Values=Create_Dist_Histogram_Summary(Data,FilePrefix,ISExp)%F
Values=Data;
imagesc(Data)
hold on
GCA_Fig=gca;
if ISExp
    YLabels="";
    for B=1:height(FilePrefix)
        [~,~,FileIDs,~]=Breakup_Title_Exp_Folder(FilePrefix(B));
        YLabels=cat(1,YLabels,strjoin(FileIDs(5:6)));
    end
    YLabels(1,:)=[];
    GCA_Fig.YTickLabel=YLabels;
end
title("Distance Traveled")
colorbar
GCA_Fig.XTick=0:15;
GCA_Fig.XTickLabel=0:15;
ylabel('Distance traveled')
xlabel("Time minutes")
% set(GCA_Fig,'YDir','reverse')
hold off
end

function Values=Create_histo_2_bird_Summary(Data,FemaleID,ISExp)
Values=sum(Data,3);
imagesc(Values,[0,100])
PixelsPerCm=1002/60.96;
hold on
GCA_Fig=gca;
GCA_Fig.XTick=0:PixelsPerCm:1776;
GCA_Fig.YTick=0:PixelsPerCm:1002;
GCA_Fig.XTickLabel=0:122;
GCA_Fig.YTickLabel=0:61;
yticklabels(0:121.92)
if ISExp
    title("Exper Posit Dist "+replace(FemaleID,"_"," "))
else
    title("Hab Posit Dist "+replace(FemaleID,"_"," "))
end

colorbar


xlabel('Length HOS cm')
ylabel('Width HOS cm')

Xline=linspace(0,490);
line(Xline,ones(length(Xline),1)*500,'Color','k')
Xline=linspace(1325,1776);
line(Xline,ones(length(Xline),1)*500,'Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*490,Yline,'Color','k')
Yline=linspace(500,1002);
line(ones(length(Xline),1)*1325,Yline,'Color','k')
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*220;
line(Xline,Yline,'Color','k')%,Label="M2 perch")
Yline=linspace(670,1002);
Xline=ones(length(Yline),1)*930;
line(Xline,Yline,'Color','k')%,Label="Nut perch")
Yline=linspace(280,680);
Xline=ones(length(Yline),1)*1580;
line(Xline,Yline,'Color','k')%,Label="M1 perch")
FntSz=8;
text(1500,270,"M1 Q",'FontSize',FntSz)
text(850,740,"Nutri Qu",'FontSize',FntSz)
text(850,270,"Neut Q",'FontSize',FntSz)
text(200,270,"M2 Q",'FontSize',FntSz)
set(gca,'YDir','Normal')
hold off
end

function [HOS_x_range,HOS_y_range,Max_Dist_Pix,Pixels_Per_Cm,HOS_x_cm_Range,HOS_y_cm_Range,Aggregate_Analysis,Max_Num_Birds,Coord_Thresh,Mic_Thresh,Points_per_Bird,BirdIndx_FView,BirdIndx_MView]=Init_Constants
HOS_x_range=0:37:1776;
HOS_y_range=0:25:1002;
Max_Dist_Pix=sqrt(1776^2+1002^2);
Pixels_Per_Cm=1002/60.96;
HOS_x_cm_Range=[0,1776/Pixels_Per_Cm];
HOS_y_cm_Range=[0,1002/Pixels_Per_Cm];
Aggregate_Analysis="D:\Meta_Analysis";
Max_Num_Birds=3;
Coord_Thresh=0.2;
Mic_Thresh=0.5;
Points_per_Bird=5;
BirdIndx_FView=   [1,2;...%F     %Index where each birds x and y data is in BirdCoord
    3,4;... %M1
    5,6];%M2

BirdIndx_MView=   [1,2;...%F     %Index where each birds x and y data is in BirdCoord
    3,4];%M
end

function [Meta_Hab,Meta_Exp]=Init_Meta()
Meta_Hab.Lost_Frames=[0,0,0];
Meta_Hab.Lost_Points=zeros(3,5);
Meta_Hab.Num_Frames=0;
Meta_Hab.BirdCoord=zeros(40,48);
Meta_Hab.XAxis_Dat=zeros(32,13);
Meta_Hab.Choice=zeros(32,4);
Meta_Hab.DistanceF=zeros(32,15);

Meta_Exp.Lost_Points=zeros(3,5);
Meta_Exp.Lost_Frames=[0,0,0];
Meta_Exp.Num_Frames=0;
Meta_Exp.BirdCoord=zeros(40,48);
Meta_Exp.XAxis_Dat=zeros(8,13);
Meta_Exp.Choice=zeros(8,4);
Meta_Exp.Distance.DataF=zeros(8,15);
end

function [Hab,Exp,NUM_Hab,NUM_Exp]=Init_Hab_Exp()
Hab.Lost_Points=zeros(3,5);
Hab.Lost_Frames=[0,0,0];
Hab.Num_Frames=0;
Hab.BirdCoord=zeros(40,48,32);
Hab.XAxis_Dat=zeros(32,13);
Hab.Choice=zeros(32,4);
Hab.Distance.F=zeros(8,15);
Hab.Distance.M1=zeros(8,15);
Hab.Distance.M2=zeros(8,15);
Hab.Prefix=strings(32,1);
NUM_Hab=0;

Exp.Lost_Points=zeros(3,5);
Exp.Lost_Frames=[0,0,0];
Exp.Num_Frames=0;
Exp.BirdCoord=zeros(40,48,8);
Exp.XAxis_Dat=zeros(8,13);
Exp.Choice=zeros(8,4);
Exp.Distance.F=zeros(8,15);
Exp.Distance.M1=zeros(8,15);
Exp.Distance.M2=zeros(8,15);
Exp.Prefix=strings(8,1);
NUM_Exp=0;
end