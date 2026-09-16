%% Run TASC-DMD for a list of subjects

repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(fullfile(repositoryRoot, "src"));

dataRoot = "D:\path\to\NIRTC_HJF_Subjects";
subjectIDs = ["U01_HJF_0015_01"];
motionTag = "NR";

options = default_tasc_dmd_options();
options.outputRoot = fullfile(repositoryRoot, "outputs");

batchResults = cell(numel(subjectIDs), 1);
for subjectIndex = 1:numel(subjectIDs)
    subjectID = subjectIDs(subjectIndex);
    fprintf("Running %s (%d of %d)\n", ...
        subjectID, subjectIndex, numel(subjectIDs));
    try
        batchResults{subjectIndex} = run_tasc_dmd_subject( ...
            dataRoot, subjectID, motionTag, options);
    catch exception
        warning("run_batch:SubjectFailed", ...
            "Subject %s failed: %s", subjectID, exception.message);
    end
end

if ~isfolder(options.outputRoot)
    mkdir(options.outputRoot);
end
save(fullfile(options.outputRoot, "batch_results.mat"), ...
    "batchResults", "subjectIDs", "motionTag", "options", "-v7.3");
