# Megtusalen validation (2026)

Repository: https://github.com/crisglav/megtusalen_validation2026

This repository validates neuropsychological and genetic variables from the Megtusalen dataset (first session) against original source datasets from the UMEC, FAMILIARES, and NEMOS projects.

## Project structure

- `data/` → source datasets
- `code/` → MATLAB scripts
- `results/` → validation outputs, log files and corrected excel

## Data sources

Original data are located in `data/source_data/`.

### UMEC
- Neuropsychology:
  - Source: `UMEC_DAVID.sav` (provided by Brenda)
  - Notes:
    - Exported to `.csv` for processing
    - Considered the reference dataset

- Genetics:
  - Source not available

- UMEC extension (≥236):
  - Source: `cortisolyluna_inma.xlsx` (provided by Inma)
  - Notes:
    - Contains neuropsychology and APOE
    - Diagnosis uncertain for some participants (Group variable matches diagnosis for UMEC participants)
    - Group variable inconsistent for familiares

### FAMILIARES

- Neuropsychology:
  - Source: `BBDD Conjunta 261 familiares.xlsx` (provided by Alejandra)
  - Notes:
    - Considered the reference dataset for neuropsychological variables

- Genetics:
  - Primary file:
    - `BBDD Conjunta 261 familiares.xlsx`
  - Additional source files (provided by Fede):
    - `familiares Resultados totales enviados abril 2018.xlsx`
    - `familiares resto pacientes abril 2019.xlsx`
    - `familiares Resultados pendientes julio 2019.xlsx`
  - Notes:
    - Genetics data in the Megtusalen dataset did not match the primary file
    - Additional Excel files were obtained to reconstruct the complete genetics dataset
    - The file `familiares Resultados pendientes julio 2019.xlsx` includes additional participants not present in the main BBDD file
    - The following files are used as final genetics reference:
      - `BBDD Conjunta 261 familiares.xlsx`
      - `familiares Resultados pendientes julio 2019.xlsx`

### NEMOS

- Neuropsychology and genetics:
  - Source:
    - `Base de Datos Proyecto NEMOS para MEGTUSALEN 17.03.26.xlsx`
      (provided by María Eugenia)
  - Modified version:
    - `Base de Datos Proyecto NEMOS para MEGTUSALEN 18.03.26.xlsx`
  - Notes:
    - Excel file was created specifically for this validation
    - Column names were modified in the updated version
    - The modified file is used as the working reference dataset

## Known data issues

- UMEC extension:
  - Diagnosis could not be verified for UMEC participants with ID higher than 235

- Genetics (UMEC):
  - Source data not found

- FAMILIARES:
  - Multiple Excel files required to reconstruct full dataset

## Code

- Main script: `code/main_script.m`
- Variable range validation: `code/review_ranges.m`
- Diagnosis validation after correction: `code/diagnostic_review_megtusalen.m`
- Variable definitions: `data/participants_megtusalen.json`

The JSON file defines variable names, descriptions, ranges, and metadata used during validation.

## How to run

Requirements:
- MATLAB

Steps:
1. Place source data inside `data/source_data/`
2. Run:
   ```matlab
   code/main_script.m

## Outputs

- `results/participants_megtusalen_corrected.xlsx`:
  - Harmonized dataset
  - Corrected variables based on validation rules

- Variable schema: [`participants_megtusalen.json`](data/participants_megtusalen.json)
  - Created manually

Note: for comparing outputs visually one can use the tool "spreadsheet compare" which is preinstalled with Microsoft Excel.

## Data privacy

This repository contains sensitive clinical data belonging to the C3N. This dataset is for internal use only.
Ensure compliance with data protection regulations before sharing.

# Contact

Cristina Gil Ávila, cgilavila@ucm.es
Adelia Solás Martínez Évora, adeliasm@ucm.es

24.03.2026

## Confirmed changes

- **NEMOS participants**
  - NEMOS-141 → MCIa
  - NEMOS-184 → MCIa
  - NEMOS-190 → MCIa
  - Source: verbal confirmation (F.M.U., 11.03.2026)

- **FAMILIARES participants**
  - FAM-079 → m
  - FAM-220 → f
  - FAM-234 → m
  - FAM-239 → f
  - Source: email confirmation (A.G.C., 17.03.2026)

