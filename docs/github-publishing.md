# GitHub publishing checklist

## Suggested repository metadata

- **Repository name:** `brain-tasc-dmd`
- **Description:** `MATLAB pipeline for reduced-order modeling of 4-D brain strain fields using TASC-DMD.`
- **Topics:** `biomechanics`, `brain-deformation`, `dynamic-mode-decomposition`, `matlab`, `medical-imaging`, `reduced-order-modeling`, `tagged-mri`

## Before making the repository public

1. Choose a software license. MIT and BSD-3-Clause are common permissive options, but confirm that your institution and any upstream code permit your choice.
2. Confirm that no NIfTI, MAT, CSV, participant identifiers, credentials, or local paths are staged.
3. Run the synthetic tests in MATLAB.
4. Run one representative subject and inspect the MAT file, CSV exports, and summary image.
5. If data-sharing terms allow it, add a de-identified result image to the README. Do not publish raw participant data by default.
6. Replace or supplement the example subject identifier if it is not appropriate to expose publicly.

## First push

Create an empty repository on GitHub without adding generated files, then run:

```bash
git init
git add .
git status
git commit -m "Prepare public TASC-DMD brain biomechanics pipeline"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/brain-tasc-dmd.git
git push -u origin main
```

Review `git status` before the commit. The `.gitignore` is a safeguard, not a substitute for checking what will become public.
