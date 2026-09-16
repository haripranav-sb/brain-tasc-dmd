function options = default_tasc_dmd_options()
%DEFAULT_TASC_DMD_OPTIONS Return the default analysis settings.

options = struct();
options.numDelays = 3;
options.spatialRank = 6;
options.dmdRank = 5;
options.dropFirstFrame = true;
options.frameStride = 1;
options.removeConstantRows = true;
options.makeFigure = true;
options.figureComponent = "Exy";
options.figureSlice = [];
options.outputRoot = "";
options.timeStepTolerance = 0.05;
end
