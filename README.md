# Bioinformatics Education

Hands-on bioinformatics workflows covering read alignment, variant calling, and RNA-Seq analysis. Organized as weekly sessions, managed with [pixi](https://pixi.sh).

## Structure

```
edu/
├── 1-data-types/       # Download & inspect reference genomes (NCBI datasets, seqkit)
├── 2-alignment/        # Read alignment to Ebola genome (BWA, samtools, IGV)
├── 3-variants/         # Variant calling pipeline (bcftools mpileup → call → sort)
├── 4-quantification/   # RNA-Seq quantification & DE (HiSat2, featureCounts, edgeR)
├── bioinfo/
│   └── snpcall/        # Standalone SNP calling exercise (AF086833 / SRR1553425)
├── stats/              # R/stats-only pixi environment
├── main.nf             # Nextflow pipeline (auto-commit results via GIT_PAT)
└── results/
```

Each numbered module has its own `src/` library with tool-wrapper Makefiles (`src/run/`), R scripts (`src/r/`), and reusable workflow modules (`src/workflows/`).

## Setup

```bash
cd bioinfo
pixi install
pixi shell
```

## Usage

Each session is driven by `make`. Run `make` from any session directory to see available targets.

```bash
# Ebola alignment + variant calling
cd bioinfo/kedd
make genome && make align && make call

# RNA-Seq differential expression
cd bioinfo/csut
make download && make index && make align && make count && make edger
```

## Automation

`nextflow run main.nf` generates a pipeline summary and pushes results to the repository using a `GIT_PAT` secret.
