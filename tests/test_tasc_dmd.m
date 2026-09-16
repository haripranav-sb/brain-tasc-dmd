function tests = test_tasc_dmd
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
sourceDirectory = fullfile(repositoryRoot, "src");
addpath(sourceDirectory);
testCase.TestData.sourceDirectory = sourceDirectory;
end

function teardownOnce(testCase)
rmpath(testCase.TestData.sourceDirectory);
end

function testRecoversSyntheticFrequency(testCase)
dt = 0.01;
frequency = 2.5;
time = 0:dt:2;
X = [cos(2 * pi * frequency * time); sin(2 * pi * frequency * time)];

model = tasc_dmd(X, dt, 1, 2, 2);

verifyEqual(testCase, sort(abs(model.frequencyHz)), ...
    [frequency; frequency], "AbsTol", 1e-10);
verifySize(testCase, model.reconstruction, [2, numel(time)]);
verifyLessThan(testCase, norm(model.reconstruction - X, "fro") / norm(X, "fro"), 1e-10);
end

function testDelayEmbeddingDimensions(testCase)
X = randn(8, 20);
model = tasc_dmd(X, 0.02, 3, 4, 5);

verifySize(testCase, model.spatialBases, [8, 4, 3]);
verifySize(testCase, model.embeddedCoordinates, [12, 18]);
verifySize(testCase, model.modalDynamics, [5, 18]);
end

function testRejectsOversizedSpatialRank(testCase)
X = randn(3, 8);
verifyError(testCase, @() tasc_dmd(X, 0.01, 2, 4, 2), ...
    "tasc_dmd:SpatialRankTooLarge");
end

function testBuildsMaskedStateMatrix(testCase)
frameTimeMs = (0:10:40)';
base = reshape(single(1:(2 * 2 * 2 * 5)), [2, 2, 2, 5]);
strain = struct( ...
    "Exx", base, "Exy", 2 * base, "Eyy", 3 * base, ...
    "Exz", 4 * base, "Eyz", 5 * base, "Ezz", 6 * base);
mask = false(2, 2, 2);
mask(1, 1, 1) = true;
mask(2, 2, 2) = true;

[X, state] = build_strain_state_matrix(strain, mask, frameTimeMs, ...
    "dropFirstFrame", false, "removeConstantRows", false);

verifySize(testCase, X, [12, 5]);
verifyEqual(testCase, state.dt, 0.01, "AbsTol", eps);
verifyEqual(testCase, state.numVoxels, 2);
verifyEqual(testCase, state.rowComponent(1:2), ["Exx"; "Exx"]);
end

function testRejectsMismatchedMask(testCase)
frameTimeMs = (0:10:40)';
volume = randn(2, 2, 2, 5, "single");
strain = struct( ...
    "Exx", volume, "Exy", volume, "Eyy", volume, ...
    "Exz", volume, "Eyz", volume, "Ezz", volume);

verifyError(testCase, @() build_strain_state_matrix( ...
    strain, true(3, 3, 3), frameTimeMs), ...
    "build_strain_state_matrix:MaskSizeMismatch");
end
