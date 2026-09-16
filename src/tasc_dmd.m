function model = tasc_dmd(X, dt, numDelays, spatialRank, dmdRank)
%TASC_DMD Compute a TASC-DMD model from uniformly sampled snapshots.
%   X is an n-by-m matrix whose columns are snapshots separated by dt
%   seconds. numDelays controls the delay embedding, spatialRank is the
%   rank retained for each delayed block, and dmdRank is the final DMD rank.

arguments
    X {mustBeNumeric, mustBeNonempty}
    dt (1,1) double {mustBePositive, mustBeFinite}
    numDelays (1,1) double {mustBeInteger, mustBePositive}
    spatialRank (1,1) double {mustBeInteger, mustBePositive}
    dmdRank (1,1) double {mustBeInteger, mustBePositive}
end

X = double(X);
if any(~isfinite(X), "all")
    error("tasc_dmd:NonfiniteInput", "X must contain only finite values.");
end

[numStates, numSnapshots] = size(X);
numEmbeddedSnapshots = numSnapshots - numDelays + 1;
if numEmbeddedSnapshots < 2
    error("tasc_dmd:TooFewSnapshots", ...
        "At least numDelays + 1 snapshots are required.");
end

maxSpatialRank = min(numStates, numEmbeddedSnapshots);
if spatialRank > maxSpatialRank
    error("tasc_dmd:SpatialRankTooLarge", ...
        "spatialRank cannot exceed min(size(X,1), size(X,2)-numDelays+1) = %d.", ...
        maxSpatialRank);
end

projectedBlocks = zeros(numDelays * spatialRank, numEmbeddedSnapshots);
spatialBases = zeros(numStates, spatialRank, numDelays);

for delayIndex = 1:numDelays
    block = X(:, delayIndex:(numSnapshots - numDelays + delayIndex));
    [basis, ~, ~] = svd(block, "econ");
    rowRange = (delayIndex - 1) * spatialRank + (1:spatialRank);
    spatialBases(:, :, delayIndex) = basis(:, 1:spatialRank);
    projectedBlocks(rowRange, :) = basis(:, 1:spatialRank)' * block;
end

past = projectedBlocks(:, 1:end-1);
future = projectedBlocks(:, 2:end);
[U, S, V] = svd(past, "econ");

singularValues = diag(S);
tolerance = max(size(past)) * eps(max(singularValues));
numericalRank = nnz(singularValues > tolerance);
effectiveRank = min(dmdRank, numericalRank);
if effectiveRank == 0
    error("tasc_dmd:RankDeficientInput", ...
        "The embedded snapshot matrix has numerical rank zero.");
end

U = U(:, 1:effectiveRank);
S = S(1:effectiveRank, 1:effectiveRank);
V = V(:, 1:effectiveRank);

reducedOperator = U' * future * V / S;
[eigenvectors, eigenvalueMatrix] = eig(reducedOperator);
modes = future * (V / S) * eigenvectors;
eigenvalues = diag(eigenvalueMatrix);
continuousEigenvalues = log(eigenvalues) / dt;
amplitudes = modes \ past(:, 1);

time = (0:(numEmbeddedSnapshots - 1)) * dt;
sampleIndices = 0:(numEmbeddedSnapshots - 1);
modalDynamics = amplitudes .* (eigenvalues .^ sampleIndices);

model = struct();
model.numDelays = numDelays;
model.spatialRank = spatialRank;
model.requestedDmdRank = dmdRank;
model.dmdRank = effectiveRank;
model.spatialBases = spatialBases;
model.embeddedCoordinates = projectedBlocks;
model.modes = modes;
model.eigenvalues = eigenvalues;
model.continuousEigenvalues = continuousEigenvalues;
model.frequencyHz = imag(continuousEigenvalues) / (2 * pi);
model.amplitudes = amplitudes;
model.modalDynamics = modalDynamics;
model.reconstruction = modes * modalDynamics;
model.time = time;
model.dt = dt;
end
