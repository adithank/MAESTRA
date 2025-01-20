function whole_FOV_analysis(rootdir,alias,cfg_data,output_file_connection,whichPass)

arguments
    rootdir (1,1) string
    alias   (1,1) string
    cfg_data (1,1) struct
    output_file_connection 
    whichPass (1,1) double = length(cfg_data.Deformation);
end

whichPass

analysisdir = fullfile(rootdir,'output',alias,'whole-ROI_analysis');
mkdir(analysisdir)
[raw_trace,frames] = wholeFOV.compute_traces_whole_well(cfg_data, rootdir, alias,whichPass);
if cfg_data.TFM.DoTFM
    fnameout = fullfile(analysisdir,[alias,'_tfm_trace_raw.pdf']);
    fnameout2 = fullfile(analysisdir,[alias,'_tfm_trace_peaks.pdf']);
    rawout    = fullfile(rootdir,'raw',[alias,'_tfm_trace_peaks.pdf']);
else
    fnameout = fullfile(analysisdir,[alias,'_div_trace_raw.pdf']);
    fnameout2 = fullfile(analysisdir,[alias,'_div_trace_peaks.pdf']);
    rawout    = fullfile(rootdir,'raw',[alias,'_div_trace_peaks.pdf']);
end
tvec= (frames-min(frames)) / cfg_data.OtherParameters.FrameRate;

% save_traces(raw_trace,[],tvec,fnameout,cfg_data)
[peakIDs,time_interp,signal_interp] = wholeFOV.split_peaks(tvec,raw_trace);
% save_traces(signal_interp,peakIDs,time_interp,fnameout2,cfg_data)
% src = fnameout2;
% dst = rawout;
% copyfile(src,dst);

%DWS ADD - save min index in seperate file
[minval,minindex] = min(raw_trace)
fid = fopen(fullfile(analysisdir,'min_frame.txt'),'w');
fprintf(fid,'%3d',minindex);
fclose(fid);

metrics = wholeFOV.measure_peaks(peakIDs,time_interp,signal_interp);
t = struct2table(metrics);
t.alias=repmat({alias},[height(t),1]);

% Load elastography results and add them to the table
if cfg_data.TFM.DoTFM
    tfmdir = fullfile(rootdir,'output',alias,'tfm');
    %DWS fix for when elastography does not work
    try
        a = readtable(fullfile(tfmdir,[alias,'_elastography_metrics.csv']),'TextType','char');
        t = join(t,a);
    catch ME%fill elastography with NaN if the elastography doesn't work
        a = table;
        a.E = NaN(height(t),1);
        a.nu = NaN(height(t),1);
        a.G = NaN(height(t),1);
        a.K = NaN(height(t),1);
        t = [t a];%add the columns of zeros to table
    end
end


means = varfun(@nanmean, t(:,2:end), 'InputVariables', @isnumeric);
sds = varfun(@nanstd, t(:,2:end), 'InputVariables', @isnumeric);

% Move alias column to the front
t = movevars(t,{'alias'},'Before',1);

% Pack time-series arrays into a string
signal_str = ['{', sprintf('%f;',signal_interp) ,'}'];
time_str   = ['{', sprintf('%f;',time_interp)   ,'}'];
peakID_str = ['{', sprintf('%d;',peakIDs)   ,'}'];

% Write peak by peak measurements inside alias folders
peaksfilename = fullfile(analysisdir,[alias+"_peak_metrics.csv"]);
writetable(t,peaksfilename)

% Write time-series, averages and sd values to file
means_str = arrayfun(@num2str,means{1,:},'UniformOutput',false);
sds_str  = arrayfun(@num2str,sds{1,:},'UniformOutput',false);
stringout = strjoin([alias , signal_str , time_str , peakID_str, means_str,sds_str],',');
fprintf(output_file_connection,'\n%s',stringout);
