function [EEG_epoch] = func_segmentation(ALLEEG,savePath,markerPath)

% savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
% markerPath = "none";
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT VARIABLES 
%
% ALLEEG = datasets loaded into EEGLAB's ALLEEG variable
% 
% savePath = directory in which you are going to save the segmented data
% variable (EEG_epoch) 
%
% markerPath = directory in which you'll load the event sheet. Type in
% "none" if you are not using an external data sheet. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% initialize the storage for segmented datasets. 
EEG_epoch = struct();



% if there is valid path for the external event sheet 
if ~strcmp(markerPath,"none")
    % change dir to marker sheet's directory 
    cd(markerPath)
    % read event sheet as table 
    markerSheet = readtable('markers_matlab.xlsx');
    % transform table to cell for efficient processing 
    markerSheet = table2cell(markerSheet);
end


% this variable is used for storing each of the event marker letters. once
% a letter has been stored (markerName_event_1), same letters that come after it will change the
% data field name as markerName_event2, markerName_event3... etc.)

for pi = 1:length(ALLEEG)
    storeEvents = struct();
    fprintf('\n******CURRENT PARTICIPANT: %s ******\n',ALLEEG(pi).setname); 
    fprintf('\n******PROGRESS %d of %d ******\n',pi,length(ALLEEG));     
    
    
    % INITIALIZE THE EPOCHED DATA STRUCTURE
    EEG_epoch(pi).A_subject  = ALLEEG(pi).setname;
    EEG_epoch(pi).A_srate    = ALLEEG(pi).srate;
    EEG_epoch(pi).A_chanlocs = ALLEEG(pi).chanlocs;
    samplingrate             = ALLEEG(pi).srate;
    
    % create duplicate of event type and latency 
    event_list_code         = {ALLEEG(pi).urevent.type}.';
    event_list_latency      = {ALLEEG(pi).urevent.latency}.';
    
    % create a virtual event sheet which replicates the event sheet that we
    % normally would use. For this project, we don't have valid events or
    % event counts in the sheet. 
    % This required us to create a cell list with valid event markers
    % (denoted by letters only). 
    event_list_letter_code  =  {[]}; % cell(length(event_list_code),1);
    
    regIteration = 0; 
    
    for listi = 1:length(event_list_code)
        
        
        % get current event from participant's eeglab data 
        currentEvent            = event_list_code{listi};
        
        % get time difference between this and next event if this is not
        % the last loop
        if listi < length(event_list_code)
            timeDifference          = (event_list_latency{listi+1} - event_list_latency{listi})*1/samplingrate;
        else
            timeDifference = 1;
        end
        
        % accept this segment if the next event is 5s after this one 
        if timeDifference < 5
            acceptSegment = false; 
        elseif timeDifference > 5
            acceptSegment = true;
        end
            
        
        
        % check if this is a valid event 
        isEvent = ~isempty(strfind(currentEvent,'Trigger')) && ~isempty(strfind(currentEvent,'RS232')) && acceptSegment;  %#ok<*STREMP>        

        % extract the letter of event
        apostropheIndex = strfind(currentEvent,''''); %  find the first ' in event name and get the letter after it because events are named = 'RS232 Trigger: 98('b')'
        
        
        if ~isempty(apostropheIndex)
            currentEvent = currentEvent(apostropheIndex(1)+1);    
        else
            continue
        end
        
        % check if this is a letter not a number code 
        isEvent = isEvent && isnan(str2double(currentEvent));
        

        % register valid events to the virtual event sheet
        if isEvent
            regIteration = regIteration + 1; 
            currentEvent = lower( currentEvent ); 
            event_list_letter_code{regIteration} = currentEvent; 
        end
        
        
    end
    
    % get all codes just once
    event_list_letter_code = unique(event_list_letter_code);

    howManyEvents = length(event_list_code);
    
    
    for eventi = 1:howManyEvents
        % a logical variable used for skipping to next markers if there is
        % no valid match
        skipToNextMarker = 0;
        

        
        % get current event from eeglab dataset, time point of the event, and its order on the
        % list
        currentEvent    = event_list_code{eventi};
        currentLatency  = event_list_latency{eventi};
        currentOrder    = eventi;
        
        
        % get current event, time point of the event, and its order on the
        % list
%         currentEvent    = ALLEEG(pi).urevent(eventi).type;
%         currentLatency  = ALLEEG(pi).urevent(eventi).latency;
%         currentOrder    = eventi;
        
        % check if this is a viable event (not 'continue','pause', or
        % 'condition 26' etc.        
        isEvent = ~isempty(strfind(currentEvent,'Trigger')) && ~isempty(strfind(currentEvent,'RS232'));  %#ok<*STREMP>        
        
        % if this is not a viable event, proceed to next event
        if ~isEvent
            disp('skipping, not an event')
            disp(currentEvent)
            continue
        end

        % extract the letter of event        
        apostropheIndex     = strfind(currentEvent,''''); %  find the first ' in event name and get the letter after it because events are named = 'RS232 Trigger: 98('b')'
        currentEvent        = currentEvent(apostropheIndex(1)+1);
        currentEvent        = lower( currentEvent ); 
        
        epochduration       = 20; 
        segmentduration     = 20;

        for matchi = 1:length(event_list_letter_code)
            
            % get event from marker 
            sheetEvent      = event_list_letter_code{matchi};
            % match the current marker with the markers in markerSheet
            if strcmp(currentEvent,sheetEvent)
                
                
%                 segmentLength = markerSheet{matchi,4} * (ALLEEG(pi).srate);  % multiply with sampling rate to get the time point necessary for epoch
%                 segmentCount = markerSheet{matchi,3} / markerSheet{matchi,4}; % get how many epochs there are for this condition
%                 markerLetter =  markerSheet{matchi,5};
                
                segmentLength = segmentduration * samplingrate;  % multiply with sampling rate to get the time point necessary for epoch
                segmentCount  = epochduration / segmentduration;  % get how many epochs there are for this condition
                markerLetter  = event_list_letter_code{matchi};
                
                % if this marker appears more than once, start to name the
                % data field as markerName_event2, markerName_event3 etc.
                if isfield(storeEvents,markerLetter)
                    storeEvents.(markerLetter) = storeEvents.(markerLetter)+1;                    
                else
                    storeEvents.(markerLetter) = 1;
                end                
                
                conditionName = cat(2,'event_',sheetEvent,'_',num2str(storeEvents.(markerLetter))); % get the condition name from markerSheet
                fprintf('\ncondition name: %s\n',conditionName)
                skipToNextMarker = 0;
                
                
                break
            % skip to next event if (i) no more markers to check remain AND (ii) current marker does not match any
            % of the valid markers we have on the markerSheet
            elseif matchi==length(event_list_letter_code) && ~strcmp(currentEvent,sheetEvent)
                skipToNextMarker = 1;
            end

        end
        
        % skip to next marker if there was no match in markers 
        if skipToNextMarker
            disp('skipping, no match was found')
            disp(currentEvent)
            disp(skipToNextMarker)
            continue
        end
        
        
        currentData = [];
        % initiate segmentation for the current marker 
        for epochi = 1:segmentCount
            timeInterval = currentLatency+((segmentLength*(epochi-1)):((segmentLength*epochi)-1)); % get the time interval for the epoch 

            % print marker onset and time window to command window
            if max(timeInterval) > size(ALLEEG(pi).data,2)

                % abort segmentation if epochs are not bound within limits
                fprintf('\nepoch limit exceeds data length, aborting this segmentation!\n');
                break

            else
                %continue segmentation
                fprintf('\ncurrent marker: %s \n',conditionName);
                fprintf('current latency: %d \n',currentLatency);            
                fprintf('current time interval: %d to %d\n',min(timeInterval),max(timeInterval));

                % concatenate epochs on 3rd dimension 
                currentData = cat(3,ALLEEG(pi).data(:,timeInterval),currentData);        
            end

        end        
        
        

        if isfield(EEG_epoch,conditionName)
            % if this condition had a previously registered data,
            % concatenate the new one. each repeated ooccurence of the same event
            % will be stored at the 3rd dimension. 
            EEG_epoch(pi).(conditionName)=cat(3,EEG_epoch(pi).(conditionName),currentData);            
        else
            % if there is no prior registry, create this condition
            EEG_epoch(pi).(conditionName)= currentData;
        end
        
        
        
        

    end
end


% order field names for the 
EEG_epoch = orderfields(EEG_epoch);

% change dir to save path
cd(savePath);

% name of the segmented dataset variable as a file
segmentedData = 'seg_data.mat';
%% save EEG_psd_data 
save(segmentedData,'EEG_epoch','-v7.3');

% %% remove events below, most participants do not have these. 
% EEG_epoch = rmfield(EEG_epoch, 'write_audio_trigger_control_event_7');
% EEG_epoch = rmfield(EEG_epoch, 'podcast_1_pre_roll_trigger_event_2');


