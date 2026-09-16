# Brain Deformation Modeling with TASC-DMD

This MATLAB project applies time-augmented, space-contracted dynamic mode decomposition (TASC-DMD) to 4-D brain strain fields from tagged MRI. It converts six strain-tensor components into a masked state matrix, extracts a low-dimensional spatiotemporal representation, and exports modal trajectories for downstream sparse system identification.

The repository is a research implementation intended for method exploration. It is not clinical software and does not include participant data.

## What the pipeline does

1. Loads six time-resolved NIfTI strain volumes: `Exx`, `Exy`, `Eyy`, `Exz`, `Eyz`, and `Ezz`.
2. Restricts the fields to a brain mask and stacks the tensor components into a state matrix.
3. Applies delay embedding and a truncated spatial basis to construct TASC coordinates.
4. Runs exact DMD in the contracted coordinate system.
5. Saves the decomposition, a summary figure, and real-valued modal time series for SINDy/PySINDy.

## Repository layout

```text
brain-tasc-dmd/
├── src/                  MATLAB functions used by the analysis
├── examples/             Configurable single- and multi-subject examples
├── tests/                Synthetic unit tests for the numerical core
├── docs/                 Input-data and output-file conventions
├── .gitignore            Excludes participant data and generated results
└── README.md
```

## Requirements

- MATLAB R2020b or newer
- Image Processing Toolbox (`niftiinfo`, `niftiread`)
- 4-D strain data arranged as described in [`docs/data-layout.md`](docs/data-layout.md)

No participant data are distributed with this repository. The numerical unit tests use synthetic data and do not require NIfTI files.

## Data source

The brain biomechanics imaging datasets used with this pipeline are available from the [Brain Biomechanics Imaging Resources (BBIR) collection on NITRC](https://www.nitrc.org/frs/?group_id=1390). This repository does not redistribute those files. Please obtain the data directly from NITRC and follow the collection's release notes, access requirements, and applicable data-use terms.

## Quick start

Clone the repository, open MATLAB in its root directory, and add the source folder:

```matlab
addpath("src")
```

Edit `examples/run_single_subject.m` with your local data directory and subject identifier, then run it. The main entry point is:

```matlab
results = run_tasc_dmd_subject(dataRoot, subjectID, motionTag, options);
```

`motionTag` accepts `"NR"` (neck rotation) or `"NE"` (neck extension). The optional settings structure can be created with `default_tasc_dmd_options`.

```matlab
options = default_tasc_dmd_options();
options.numDelays = 3;
options.spatialRank = 6;
options.dmdRank = 5;
options.outputRoot = fullfile(pwd, "outputs");

results = run_tasc_dmd_subject( ...
    "D:\path\to\subjects", "U01_HJF_0015_01", "NR", options);
```

See [`examples/run_batch.m`](examples/run_batch.m) for a multi-subject workflow.

## Outputs

Each run creates a timestamped directory containing:

- `tasc_dmd_results.mat`: decomposition, state metadata, and run settings
- `tasc_dmd_summary.png`: selected spatial modes and their time dynamics
- `modal_timeseries_real.csv`: real part of the DMD modal coordinates
- `modal_derivative_real_per_sec.csv`: time derivative in units per second
- `time_vector_sec.csv`: time coordinate for the modal samples
- `modal_state_names.csv`: column names for downstream system identification

The full output schema is described in [`docs/data-layout.md`](docs/data-layout.md).

## Tests

From the repository root:

```matlab
results = runtests("tests");
table(results)
```

The tests check recovery of a synthetic oscillation, output dimensions, input validation, state-matrix construction, and derivative scaling. A MATLAB runtime was not bundled with the original project, so real-data regression results are not included.

## Method reference

This implementation follows the TASC-DMD formulation described in:

> Arani, A. H. G., Alshareef, A. A., Pham, D. L., et al. “A novel spatiotemporal decomposition and identification of sparse equations for human brain deformation.” *Scientific Reports* 16, 14468 (2026). https://doi.org/10.1038/s41598-026-41995-1

The authors also provide a general MATLAB implementation in the [TASC-DMD reference repository](https://github.com/Amir-Arani/TASC-DMD).

## Scope and limitations

- This repository performs subject-level TASC-DMD and prepares modal trajectories for SINDy; it does not fit a SINDy model itself.
- Hyperparameters are user-selected and should be validated for the dataset and scientific question.
- The input volumes must share the same spatial dimensions and number of frames. The pipeline rejects mismatches instead of silently cropping medical images.
- DMD assumes approximately uniform temporal sampling; the timestamp check can be tuned through `options.timeStepTolerance`.

For suggested repository metadata and a pre-publication privacy checklist, see [`docs/github-publishing.md`](docs/github-publishing.md).

## License

No license has been selected yet. Add a license before inviting reuse or accepting contributions. GitHub's license picker can generate common choices such as MIT or BSD-3-Clause.
