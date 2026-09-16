%% Run TASC-DMD for one subject
% Update these three values for your local dataset.

repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(fullfile(repositoryRoot, "src"));

dataRoot = "D:\path\to\NIRTC_HJF_Subjects";
subjectID = "U01_HJF_0015_01";
motionTag = "NR";

options = default_tasc_dmd_options();
options.numDelays = 3;
options.spatialRank = 6;
options.dmdRank = 5;
options.outputRoot = fullfile(repositoryRoot, "outputs");

results = run_tasc_dmd_subject(dataRoot, subjectID, motionTag, options);
disp(results.outputDirectory);
