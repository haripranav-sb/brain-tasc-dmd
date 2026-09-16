function [X, state] = build_strain_state_matrix(strain, mask, frameTimeMs, options)
%BUILD_STRAIN_STATE_MATRIX Stack masked strain components by time.

arguments
    strain (1,1) struct
    mask {mustBeNonempty}
    frameTimeMs (:,1) double {mustBeFinite}
    options.dropFirstFrame (1,1) logical = true
    options.frameStride (1,1) double {mustBeInteger, mustBePositive} = 1
    options.removeConstantRows (1,1) logical = true
    options.timeStepTolerance (1,1) double {mustBeNonnegative} = 0.05
end

componentNames = ["Exx", "Exy", "Eyy", "Exz", "Eyz", "Ezz"];
if ~(isnumeric(mask) || islogical(mask))
    error("build_strain_state_matrix:InvalidMaskType", ...
        "The mask must be a numeric or logical array.");
end
for component = componentNames
    if ~isfield(strain, component)
        error("build_strain_state_matrix:MissingComponent", ...
            "Missing strain component %s.", component);
    end
end

referenceSize = size(strain.Exx);
if numel(referenceSize) < 4 || referenceSize(4) < 2
    error("build_strain_state_matrix:InvalidStrainSize", ...
        "Strain components must be 4-D arrays with at least two frames.");
end

for component = componentNames
    if ~isequal(size(strain.(component)), referenceSize)
        error("build_strain_state_matrix:ComponentSizeMismatch", ...
            "All strain components must have identical dimensions.");
    end
end

if ndims(mask) == 4 && size(mask, 4) == 1
    mask = mask(:, :, :, 1);
end
if ~isequal(size(mask), referenceSize(1:3))
    error("build_strain_state_matrix:MaskSizeMismatch", ...
        "The mask dimensions must match the strain-volume dimensions.");
end
if numel(frameTimeMs) ~= referenceSize(4)
    error("build_strain_state_matrix:TimestampCountMismatch", ...
        "The number of timestamps must match the number of strain frames.");
end

frameIndices = 1:referenceSize(4);
if options.dropFirstFrame
    frameIndices(1) = [];
end
frameIndices = frameIndices(1:options.frameStride:end);
if numel(frameIndices) < 2
    error("build_strain_state_matrix:TooFewSelectedFrames", ...
        "Frame selection must retain at least two snapshots.");
end

selectedTimesMs = frameTimeMs(frameIndices);
steps = diff(selectedTimesMs) / 1000;
dt = mean(steps);
if dt <= 0
    error("build_strain_state_matrix:InvalidTimestamps", ...
        "Frame timestamps must be strictly increasing.");
end
relativeVariation = max(abs(steps - dt)) / dt;
if relativeVariation > options.timeStepTolerance
    error("build_strain_state_matrix:NonuniformSampling", ...
        "Frame spacing varies by %.1f%%; the configured tolerance is %.1f%%.", ...
        100 * relativeVariation, 100 * options.timeStepTolerance);
end

mask = mask > 0;
numVoxels = nnz(mask);
if numVoxels == 0
    error("build_strain_state_matrix:EmptyMask", "The brain mask is empty.");
end

numFrames = numel(frameIndices);
X = zeros(numVoxels * numel(componentNames), numFrames, "single");
for componentIndex = 1:numel(componentNames)
    volume = single(strain.(componentNames(componentIndex)));
    rowRange = (componentIndex - 1) * numVoxels + (1:numVoxels);
    for frameIndex = 1:numFrames
        snapshot = volume(:, :, :, frameIndices(frameIndex));
        X(rowRange, frameIndex) = snapshot(mask);
    end
end

finiteRows = all(isfinite(X), 2);
keepRows = finiteRows;
if options.removeConstantRows
    finiteData = double(X(finiteRows, :));
    nonconstantFiniteRows = var(finiteData, 0, 2) > 0;
    finiteIndices = find(finiteRows);
    keepRows(:) = false;
    keepRows(finiteIndices(nonconstantFiniteRows)) = true;
end
if ~any(keepRows)
    error("build_strain_state_matrix:NoUsableRows", ...
        "No finite, time-varying state rows remain after filtering.");
end
X = X(keepRows, :);

rowComponent = repelem(componentNames', numVoxels);
rowMaskedPosition = repmat((1:numVoxels)', numel(componentNames), 1);
stateNames = rowComponent + "_vox" + compose("%06d", rowMaskedPosition);

state = struct();
state.rowComponent = rowComponent(keepRows);
state.rowMaskedPosition = rowMaskedPosition(keepRows);
state.stateNames = stateNames(keepRows);
state.dt = dt;
state.numVoxels = numVoxels;
state.numComponents = numel(componentNames);
state.numFrames = numFrames;
state.frameTimeMs = selectedTimesMs;
state.frameIndices = frameIndices;
state.mask = mask;
state.keepRows = keepRows;
end
