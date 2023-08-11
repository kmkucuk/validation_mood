% this script does not load any data by itself
% make sure that you enter the correct input variables

% this is especially important for topographic plots/videos.
% make sure that you have channelInfo.mat ready, or as ws variable: chanInfoFile





% load data, preprocess and save sets 

getPath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\raw_sets';
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\processed_sets';

[ALLEEG] = func_loadData(getPath,savePath);



% segment the data
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
markerPath = "none";
[EEG_epoch] = func_segmentation(ALLEEG,savePath,markerPath);


% input the channel spatial locations to datasets
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
[EEG_epoch] = func_inputChanloc(EEG_epoch,savePath);

% 
% % mark bad channels manually 
% savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
% artifactStructure = func_markBadChans(EEG_epoch,savePath);

disp('interpolation started')
% interpolate bad channels and exclude high noise participants
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
[EEG_epoch] = func_interpolate(EEG_epoch,ALLEEG,artifactStructure,savePath);


disp('psd transform started')
% transform data into power spectral density
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
[EEG_psd_second] = func_psdSeconds(EEG_epoch,savePath);

disp('psd to sheets started')
% write psd into second by second excel sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
func_psdSecondsSheets(EEG_psd_second,savePath)

disp('cognitive index measures of psd data started')
% write cognitive index of psd data in seconds into sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
func_cognitiveSecondsSheet(EEG_psd_second,savePath)

%************ left here ************%
disp('Averaged cognitive index measures of psd data started')
% write AVERAGED cognitive index of psd data into sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
func_cognitiveOverallSheet(EEG_psd_second,savePath)


disp('toporaphic video started')
% create topographic videos from psd data 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\figures';
[EEG_topo_video] = func_topogVideo(EEG_psd_second,savePath);


disp('toporaphic plots of psd data started')
% create topographic plots from psd data 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\figures';
[EEG_topo_avg_freq] = func_topoPlotFreq(EEG_psd_second,savePath);

disp('toporaphic plots of mv data started')
% create topographic plots from mv data 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\figures';
[EEG_topo_avg_mv] = func_topoPlotMv(EEG_epoch,savePath); 