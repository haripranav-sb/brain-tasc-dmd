function tests = test_export_sindy_inputs
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

function testDerivativeUsesSeconds(testCase)
outputDirectory = string(tempname);
mkdir(outputDirectory);
cleanup = onCleanup(@() rmdir(outputDirectory, "s")); %#ok<NASGU>

model = struct();
model.dt = 0.25;
model.time = 0:0.25:1;
model.modalDynamics = model.time .^ 2;
exports = export_sindy_inputs(model, outputDirectory);

derivative = readtable(exports.derivativeFile);
verifyEqual(testCase, derivative.a1(2:4), 2 * model.time(2:4)', ...
    "AbsTol", 10 * eps);
end
