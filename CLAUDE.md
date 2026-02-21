# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R-based pipeline for processing CMS Hospital Cost Report (HCRIS) data. Downloads raw cost report files from CMS, converts to Parquet, and produces two analysis-ready datasets:

- **Report-level** (`hcris_rpt`): one row per cost report filed
- **Synthetic hospital-year** (`hcris_hospyear`): one row per hospital per calendar year, constructed by apportioning fiscal-year reports into calendar years

## Running the Pipeline

The pipeline has three sequential stages. Each script has `START_YEAR`/`END_YEAR` configuration at the top that must be kept in sync across scripts.

```bash
# 1. Download raw CMS data into ./source/
#    Edit STARTYEAR/ENDYEAR in the script first
bash download_source.sh

# 2. Convert CSVs to Parquet in ./store/
#    Edit START_YEAR/END_YEAR in the script first
Rscript import-source-cms.R

# 3. Process into final datasets in ./output/
#    Edit START_YEAR/END_YEAR in the script first
Rscript hcris.R
```

There are no tests, linting, or build systems. The project is run as standalone R scripts.

## Architecture

```
CMS servers → download_source.sh → ./source/ (CSV)
              import-source-cms.R → ./store/  (Parquet, partitioned by year/format)
              hcris.R             → ./output/ (Rdata, CSV, DTA)
```

### Key files

- **`lookup.xlsx`** — Drives the entire variable extraction. Two sheets:
  - "Lookup Table": maps (worksheet, column, line range, format) → variable name. Set `enabled=1` to activate.
  - "Type and Label": assigns each variable a `type` (stock/flow/dollar_flow/alpha) and label.
- **`hcris.R`** — Core processing. The `items_wide()` function joins line items against the lookup table using DuckDB, then pivots to wide format. Produces both output datasets.
- **`import-source-cms.R`** — Converts raw CSV to Arrow/Parquet with schema validation.
- **`download_source.sh`** — Downloads from CMS, handles both 1996 and 2010 format files (overlap in 2010-2011).

### Data format duality

CMS changed the cost report format around 2010. Years 2010-2011 have reports in **both** formats. The lookup table has separate rows per format (`fmt=96` vs `fmt=10`), and the code reconciles them.

### Variable type system

The `type` column in `lookup.xlsx` controls how variables are aggregated into the hospital-year dataset:

| Type | Report-level behavior | Hospital-year aggregation |
|------|----------------------|--------------------------|
| `stock` | As-is | Weighted average (weights = fraction of year covered) |
| `flow` | As-is | Scaled sum (value × fraction of report in calendar year) |
| `dollar_flow` | Missing → 0 (with `.was.na` flag) | Same as flow, but NAs already zeroed out |
| `alpha` | As-is | Value from first report (earliest `fy_bgn_dt`) |

## R Dependencies

tidyverse, arrow, duckdb, readxl, labelled, haven

## Adding New Variables

1. Find the worksheet/row/column in CMS documentation (need both 1996 and 2010 format mappings for a full panel)
2. Add row(s) to the "Lookup Table" sheet in `lookup.xlsx` — keep `clmn_num` and `line_num_start` as text (preserve leading zeros), set `enabled=1`
3. Add a row to the "Type and Label" sheet with matching `rec` name, `type`, and `label`
4. To sum across lines/subscripts, set `line_num_end`; for non-consecutive lines, add multiple rows with the same `rec` and `fmt`

## Gitignored Data Directories

`source/`, `store/`, and `output/` contain large data files and are gitignored.
