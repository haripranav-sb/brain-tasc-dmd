function results = run_tasc_dmd_subject(dataRoot, subjectID, motionTag, options)
%RUN_TASC_DMD_SUBJECT Run the brain-strain pipeline for one subject.
%   RESULTS = RUN_TASC_DMD_SUBJECT(DATAROOT, SUBJECTID, MOTIONTAG, OPTIONS)
%   loads the strain volumes and mask, fits TASC-DMD, and writes the run
%   artifacts to a timestamped output directory.

arguments
    dataRoot (1,1) string
    subjectID (1,1) string
    motionTag (1,1) string
    options (1,1) struct = struct()
end

if ~isfolder(dataRoot)
    error("run_tasc_dmd_subject:DataRootNotFound", ...
        "Data root does not exist: %s", dataRoot);
end
if strlength(subjectID) == 0
    error("run_tasc_dmd_subject:EmptySubjectID", "subjectID cannot be empty.");
end

settings = merge_options(default_tasc_dmd_options(), options);
motionTag = normalize_motion_tag(motionTag);
subjectDirectory = find_subject_directory(dataRoot, subjectID);
motionDirectory = fullfile(subjectDirectory, subjectID + "_" + motionTag + "_tMRI");
if ~isfolder(motionDirectory)
    error("run_tasc_dmd_subject:MotionDirectoryNotFound", ...
        "Motion directory does not exist: %s", motionDirectory);
end

componentNames = ["Exx", "Exy", "Eyy", "Exz", "Eyz", "Ezz"];
strain = struct();
for component = componentNames
    file = find_unique_file(motionDirectory, "*_" + component + "*_fit.nii*");
    strain.(component) = read_nifti(file);
end

pvaFile = find_unique_file(motionDirectory, "*_PVA.mat");
pvaContents = load(pvaFile);
if isfield(pvaContents, "PVA")
    pva = pvaContents.PVA;
else
    pva = pvaContents;
end
frameTimeMs = extract_frame_times(pva);

maskFile = find_unique_file(subjectDirectory, "*mask*.nii*", true);
mask = read_nifti(maskFile);
[X, state] = build_strain_state_matrix(strain, mask, frameTimeMs, ...
    "dropFirstFrame", settings.dropFirstFrame, ...
    "frameStride", settings.frameStride, ...
    "removeConstantRows", settings.removeConstantRows, ...
    "timeStepTolerance", settings.timeStepTolerance);

fprintf("State matrix: %d rows x %d frames (dt = %.6f s)\n", ...
    size(X, 1), size(X, 2), state.dt);
model = tasc_dmd(X, state.dt, settings.numDelays, ...
    settings.spatialRank, settings.dmdRank);

if strlength(settings.outputRoot) == 0
    outputRoot = fullfile(dataRoot, "tasc_dmd_outputs");
else
    outputRoot = string(settings.outputRoot);
end
runStamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss_SSS"));
outputDirectory = fullfile(outputRoot, subjectID + "_" + motionTag + "_" + runStamp);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

exports = export_sindy_inputs(model, outputDirectory);
resultsFile = fullfile(outputDirectory, "tasc_dmd_results.mat");
save(resultsFile, "model", "state", "settings", "dataRoot", ...
    "subjectID", "motionTag", "-v7.3");

figureFile = "";
if settings.makeFigure
    figureHandle = plot_tasc_dmd_summary(model, state, ...
        settings.figureComponent, settings.figureSlice);
    figureFile = fullfile(outputDirectory, "tasc_dmd_summary.png");
    exportgraphics(figureHandle, figureFile, "Resolution", 200);
    close(figureHandle);
end

results = struct();
results.outputDirectory = outputDirectory;
results.resultsFile = resultsFile;
results.figureFile = figureFile;
results.exports = exports;
results.model = model;
results.state = state;
results.settings = settings;

fprintf("Results written to %s\n", outputDirectory);
end

function settings = merge_options(defaults, supplied)
settings = defaults;
names = fieldnames(supplied);
validNames = fieldnames(defaults);
for index = 1:numel(names)
    name = names{index};
    if ~ismember(name, validNames)
        error("run_tasc_dmd_subject:UnknownOption", "Unknown option: %s", name);
    end
    settings.(name) = supplied.(name);
end
end

function tag = normalize_motion_tag(tag)
tag = upper(erase(erase(string(tag), "_TMRI"), "_"));
if ~ismember(tag, ["NR", "NE"])
    error("run_tasc_dmd_subject:InvalidMotionTag", ...
        "motionTag must be NR or NE.");
end
end

function directory = find_subject_directory(dataRoot, subjectID)
matches = dir(fullfile(dataRoot, subjectID + "*"));
matches = matches([matches.isdir]);
matches = matches(~ismember({matches.name}, {".", ".."}));
if isempty(matches)
    error("run_tasc_dmd_subject:SubjectNotFound", ...
        "No directory matching %s* was found in %s.", subjectID, dataRoot);
elseif numel(matches) > 1
    error("run_tasc_dmd_subject:AmbiguousSubject", ...
        "Multiple directories match %s* in %s.", subjectID, dataRoot);
end
directory = string(fullfile(matches.folder, matches.name));
end

function file = find_unique_file(root, pattern, recursive)
if nargin < 3
    recursive = false;
end
if recursive
    matches = dir(fullfile(root, "**", pattern));
else
    matches = dir(fullfile(root, pattern));
end
matches = matches(~[matches.isdir]);
if isempty(matches)
    error("run_tasc_dmd_subject:FileNotFound", ...
        "No file matching %s was found in %s.", pattern, root);
elseif numel(matches) > 1
    error("run_tasc_dmd_subject:AmbiguousFile", ...
        "Multiple files matching %s were found in %s.", pattern, root);
end
file = string(fullfile(matches.folder, matches.name));
end

function frameTimeMs = extract_frame_times(pva)
if isfield(pva, "frameCenter_ms")
    frameTimeMs = double(pva.frameCenter_ms(:));
elseif isfield(pva, "frameCenter")
    frameTimeMs = double(pva.frameCenter(:));
else
    error("run_tasc_dmd_subject:MissingFrameTimes", ...
        "PVA data must contain frameCenter_ms or frameCenter (milliseconds).");
end
end

function volume = read_nifti(file)
file = string(file);
if endsWith(file, ".gz", "IgnoreCase", true)
    temporaryDirectory = string(tempname);
    mkdir(temporaryDirectory);
    cleanup = onCleanup(@() rmdir(temporaryDirectory, "s")); %#ok<NASGU>
    extracted = gunzip(file, temporaryDirectory);
    file = string(extracted{1});
end
volume = niftiread(niftiinfo(file));
end
