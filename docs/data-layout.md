# Data and output conventions

## Expected input layout

The pipeline expects one directory per subject beneath `dataRoot`:

```text
dataRoot/
└── U01_HJF_0015_01/
    ├── ...mask....nii.gz
    └── U01_HJF_0015_01_NR_tMRI/
        ├── ..._Exx..._fit.nii.gz
        ├── ..._Exy..._fit.nii.gz
        ├── ..._Eyy..._fit.nii.gz
        ├── ..._Exz..._fit.nii.gz
        ├── ..._Eyz..._fit.nii.gz
        ├── ..._Ezz..._fit.nii.gz
        └── ..._PVA.mat
```

Replace `NR` with `NE` for a neck-extension acquisition. Ellipses indicate dataset-specific filename text. Each filename pattern must resolve to exactly one file; ambiguous matches are rejected.

## Required variables and dimensions

- Each strain NIfTI must be a 4-D array organized as `x × y × z × time`.
- All six strain components must have identical dimensions.
- The mask must be a 3-D NIfTI with the same spatial dimensions as the strain fields. A singleton fourth dimension is accepted.
- The PVA MAT-file must contain either `frameCenter_ms` or `frameCenter`, directly or inside a `PVA` structure. Both are interpreted as milliseconds.
- The number of timestamps must equal the number of strain frames.

The state vector stacks all masked voxels of `Exx`, followed by `Exy`, `Eyy`, `Exz`, `Eyz`, and `Ezz`. Rows containing nonfinite values are removed. Constant rows are removed by default.

## Output layout

```text
outputs/
└── U01_HJF_0015_01_NR_YYYYMMDD_HHMMSS_mmm/
    ├── tasc_dmd_results.mat
    ├── tasc_dmd_summary.png
    ├── modal_timeseries_real.csv
    ├── modal_derivative_real_per_sec.csv
    ├── time_vector_sec.csv
    └── modal_state_names.csv
```

`tasc_dmd_results.mat` contains:

- `model`: TASC bases, embedded coordinates, DMD modes, eigenvalues, frequencies, amplitudes, modal dynamics, and reconstruction
- `state`: mask, retained-row mapping, frame selection, timestamps, and time step
- `settings`: the complete options used for the run
- subject and acquisition identifiers

The CSV files include headers and are shaped as observations by modal state, which is convenient for PySINDy. Derivatives are computed with MATLAB's finite-difference `gradient` using the time step in seconds.

## Data governance

The source brain biomechanics imaging data are available through the [Brain Biomechanics Imaging Resources (BBIR) collection on NITRC](https://www.nitrc.org/frs/?group_id=1390). Download the appropriate release directly from NITRC and follow its release notes and data-use conditions.

Do not commit participant data or generated analysis files to a public repository unless the dataset's consent and distribution terms explicitly allow it. The supplied `.gitignore` excludes common NIfTI, MAT, and CSV artifacts, but you should still inspect staged files before every commit:

```bash
git status
git diff --cached --stat
```
