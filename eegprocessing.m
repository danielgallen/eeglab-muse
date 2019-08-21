clear all;
eeglab;
% Input directory
inputDir = uigetdir('','Input Data Directory');
files = dir(append(inputDir,'/**/*.csv'));
channelDir = uigetdir('','Channel Removed Directory');
icaDir = uigetdir('','ICA Directory');
% Select Output Directory
outputDir = uigetdir('','Final Output Directory');
for k = 1:length(files)
    baseFileName = files(k).name;
    fullFileName = fullfile(files(k).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    outfilename = files(k).name;
    idx = find(ismember(outfilename,'_/\:'),1,'last');
    if outfilename(idx) == '_'; outfilename(idx:end) = []; end
    outfilename = append(outfilename, '_channelremoved.set');
    channelfilepath = fullfile(channelDir, outfilename);
    if ~isfile(channelfilepath)
        EEG = csveeg(EEG,fullFileName,0,0,{'TP9','Fp1','Fp2','TP10','Pz'},256);
        EEG = eeg_checkset( EEG );
        EEG = pop_chanedit(EEG, 'lookup','standard-10-5-cap385.elp');
        EEG = eeg_checkset( EEG );
        pop_eegplot( EEG, 1, 1, 1);
        waitfor( findobj('parent', gcf, 'string', 'REJECT'), 'userdata');
        list = {'TP9','Fp1','Fp2','TP10','Pz'};
        channeltodelete = listdlg('PromptString','Select channel(s) to delete', 'ListString',list);
        if ~isempty(channeltodelete)
            EEG = pop_select( EEG,'nochannel',list(channeltodelete));
        end
        EEG = pop_eegfiltnew(EEG, [], 1, 846, true, [], 0);
        EEG = eeg_checkset( EEG );
        EEG = pop_eegfiltnew(EEG, [], 57, 60, 0, [], 0);
        EEG = eeg_checkset( EEG );
        EEG = pop_reref( EEG, []);
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset(EEG, 'filename', outfilename, 'filepath', channelDir);
    end
end

files = dir(append(channelDir,'/**/*.set'));
for k = 1:length(files)
    EEG = pop_loadset('filename', files(k).name, 'filepath', channelDir);
    EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',EEG.nbchan-1);
    EEG = eeg_checkset( EEG );
    outfilename = files(k).name;
    idx = find(ismember(outfilename,'_/\:'),1,'last');
    if outfilename(idx) == '_'; outfilename(idx:end) = []; end
    outfilename = append(outfilename, '_ica.set');
    EEG = pop_saveset(EEG, 'filename', outfilename, 'filepath', icaDir);
end

files = dir(append(icaDir,'/**/*.set'));
for k = 1:length(files)
    outfilename = files(k).name;
    idx = find(ismember(outfilename,'_/\:'),1,'last');
    if outfilename(idx) == '_'; outfilename(idx:end) = []; end
    outfilename = append(outfilename, '_processed.set');
    outfilepath = fullfile(outputDir, outfilename);
    if ~isfile(outfilepath)
        EEG = pop_loadset('filename', files(k).name, 'filepath', icaDir);  
        pop_eegplot( EEG, 0, 1, 1);
        EEG = pop_selectcomps(EEG, [1:cn]);
        waitfor( findobj('parent', gcf, 'string', 'REJECT'), 'userdata');
        waitfor(gcf);
        EEG = eeg_checkset( EEG );
        EEG = pop_subcomp( EEG, [], 0);
        EEG = eeg_eegrej( EEG, [1 11520] );
        EEG = eeg_checkset( EEG );
        EEG = eeg_regepochs(EEG, 'recurrence', 1, 'rmbase', NaN);
        EEG = pop_autorej(EEG, 'nogui','on','startprob',3,'maxrej',10,'eegplot','on');
        waitfor( findobj('parent', gcf, 'string', 'REJECT'), 'userdata');
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset(EEG,'filename',outfilename,'filepath',outputDir);
    end
end