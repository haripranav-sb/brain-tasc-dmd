function exports = export_sindy_inputs(model, outputDirectory)
%EXPORT_SINDY_INPUTS Write real modal coordinates and derivatives to CSV.

arguments
    model (1,1) struct
    outputDirectory (1,1) string
end

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

modalState = real(model.modalDynamics).';
modalDerivative = gradient(modalState, model.dt, 1);
names = "a" + string(1:size(modalState, 2));

stateFile = fullfile(outputDirectory, "modal_timeseries_real.csv");
derivativeFile = fullfile(outputDirectory, "modal_derivative_real_per_sec.csv");
timeFile = fullfile(outputDirectory, "time_vector_sec.csv");
namesFile = fullfile(outputDirectory, "modal_state_names.csv");

writetable(array2table(modalState, "VariableNames", cellstr(names)), stateFile);
writetable(array2table(modalDerivative, "VariableNames", cellstr(names)), derivativeFile);
writetable(table(model.time(:), "VariableNames", {"time_sec"}), timeFile);
writetable(table(names(:), "VariableNames", {"state_name"}), namesFile);

exports = struct();
exports.stateFile = stateFile;
exports.derivativeFile = derivativeFile;
exports.timeFile = timeFile;
exports.namesFile = namesFile;
end
