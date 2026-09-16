function figureHandle = plot_tasc_dmd_summary(model, state, component, sliceIndex)
%PLOT_TASC_DMD_SUMMARY Plot selected TASC modes and modal trajectories.

arguments
    model (1,1) struct
    state (1,1) struct
    component (1,1) string = "Exy"
    sliceIndex = []
end

validComponents = ["Exx", "Exy", "Eyy", "Exz", "Eyz", "Ezz"];
if ~ismember(component, validComponents)
    error("plot_tasc_dmd_summary:InvalidComponent", ...
        "component must be one of: %s.", strjoin(validComponents, ", "));
end
if isempty(sliceIndex)
    sliceIndex = round(size(state.mask, 3) / 2);
end
if ~isscalar(sliceIndex) || sliceIndex < 1 || sliceIndex > size(state.mask, 3)
    error("plot_tasc_dmd_summary:InvalidSlice", ...
        "sliceIndex must be between 1 and %d.", size(state.mask, 3));
end

modeIndices = select_modes(model);
numModes = numel(modeIndices);
numDelays = model.numDelays;
images = cell(numModes, numDelays);
colorLimit = 0;

for modeNumber = 1:numModes
    for delayIndex = 1:numDelays
        rows = (delayIndex - 1) * model.spatialRank + (1:model.spatialRank);
        stateMode = model.spatialBases(:, :, delayIndex) * ...
            model.modes(rows, modeIndices(modeNumber));
        volume = component_mode_to_volume(stateMode, state, component);
        image = squeeze(real(volume(:, :, sliceIndex)));
        images{modeNumber, delayIndex} = image;
        finiteValues = abs(image(isfinite(image)));
        if ~isempty(finiteValues)
            colorLimit = max(colorLimit, max(finiteValues));
        end
    end
end
if colorLimit == 0
    colorLimit = 1;
end

numColumns = max(numDelays, 3);
figureHandle = figure("Color", "w", "Position", [100, 100, 1300, 900]);
tiledlayout(numModes + 1, numColumns, ...
    "Padding", "compact", "TileSpacing", "compact");

for modeNumber = 1:numModes
    for delayIndex = 1:numDelays
        nexttile((modeNumber - 1) * numColumns + delayIndex);
        imagesc(1e3 * images{modeNumber, delayIndex});
        axis image off;
        colormap(diverging_colormap(256));
        caxis(1e3 * [-colorLimit, colorLimit]);
        if modeNumber == 1
            title(sprintf("Delay %d", delayIndex));
        end
        if delayIndex == 1
            ylabel(sprintf("Mode %d\n%.2f Hz", modeIndices(modeNumber), ...
                abs(model.frequencyHz(modeIndices(modeNumber)))));
        end
    end
end

nexttile(numModes * numColumns + 1, [1, numColumns - 1]);
plot(1e3 * model.time, real(model.modalDynamics(modeIndices, :)).', ...
    "LineWidth", 1.5);
grid on;
xlabel("Time (ms)");
ylabel("Modal amplitude");
title("TASC modal dynamics");
legend(compose("Mode %d (%.2f Hz)", modeIndices, ...
    abs(model.frequencyHz(modeIndices))), "Location", "best");

nexttile(numModes * numColumns + numColumns);
axis off;
text(0.05, 0.9, sprintf(["TASC-DMD\n\nDelays: %d\nSpatial rank: %d\n" ...
    "DMD rank: %d\nTime step: %.2f ms\nComponent: %s\nSlice: %d"], ...
    model.numDelays, model.spatialRank, model.dmdRank, 1e3 * model.dt, ...
    component, sliceIndex), "VerticalAlignment", "top");
end

function indices = select_modes(model)
[~, zeroIndex] = min(abs(model.frequencyHz));
scores = abs(model.amplitudes);
[~, order] = sort(scores, "descend");
indices = zeroIndex;
for index = order(:).'
    candidateFrequency = abs(model.frequencyHz(index));
    selectedFrequencies = abs(model.frequencyHz(indices));
    if all(abs(candidateFrequency - selectedFrequencies) > 0.5)
        indices(end + 1) = index; %#ok<AGROW>
    end
    if numel(indices) == min(3, model.dmdRank)
        break;
    end
end
for index = 1:model.dmdRank
    if numel(indices) == min(3, model.dmdRank)
        break;
    end
    if ~ismember(index, indices)
        indices(end + 1) = index; %#ok<AGROW>
    end
end
end

function volume = component_mode_to_volume(stateMode, state, component)
selectedRows = state.rowComponent == component;
positions = state.rowMaskedPosition(selectedRows);
values = stateMode(selectedRows);
maskedValues = nan(state.numVoxels, 1);
maskedValues(positions) = values;
volume = nan(size(state.mask), "single");
volume(state.mask) = single(maskedValues);
end

function colors = diverging_colormap(count)
lowerCount = floor(count / 2);
upperCount = count - lowerCount;
lower = [linspace(0, 1, lowerCount)', linspace(0, 1, lowerCount)', ones(lowerCount, 1)];
upper = [ones(upperCount, 1), linspace(1, 0, upperCount)', linspace(1, 0, upperCount)'];
colors = [lower; upper];
end
