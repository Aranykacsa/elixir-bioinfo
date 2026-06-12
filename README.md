# Bioinformatics Education Repository

A hands-on bioinformatics learning repository covering read alignment, variant calling, and RNA-Seq differential expression analysis. Workflows are organized by weekly session and managed with [pixi](https://pixi.sh) for reproducible environments.

## Repository structure

```
edu/
├── bioinfo/            # Bioinformatics workflows
│   ├── hetfo/          # Monday   — viral genome download & stats
│   ├── kedd/           # Tuesday  — Ebola alignment, SNP calling, IGV
│   ├── szerda/         # Wednesday — variant calling pipeline
│   ├── csut/           # Thursday  — RNA-Seq (HiSat2 + edgeR/DESeq2)
│   ├── snpcall/        # SNP calling practice (AF086833 / SRR1553425)
│   └── pixi.toml       # Shared conda environment definition
├── stats/              # Statistical analysis environment (pixi)
├── results/            # Nextflow pipeline outputs
├── main.nf             # Nextflow automation pipeline (git commit + push)
└── .gitignore
```

Each session directory (`hetfo`, `kedd`, `szerda`, `csut`) shares the same internal layout:

```
<session>/
├── Makefile            # Orchestrates the full workflow
├── src/
│   ├── r/              # R scripts (edgeR, DESeq2, PCA, heatmap, Salmon)
│   ├── workflows/      # Reusable Makefile modules
│   │   ├── airway.mk       # Airway RNA-Seq (Salmon + edgeR)
│   │   ├── benchmark.mk    # Multi-organism aligner benchmark
│   │   ├── snpcall.mk      # Parallel chr-split SNP calling
│   │   ├── snpeval.mk      # Variant evaluation
│   │   └── presenilin.mk   # Presenilin dataset workflow
│   ├── run/            # Tool-specific Makefile modules (bwa, hisat2, salmon…)
│   ├── setup/          # Environment setup scripts
│   └── data/           # Reference count datasets (golden, barton)
├── reads/              # Raw FASTQ files
├── refs/               # Reference genomes and indices
├── bam/                # Alignment outputs
├── vcf/                # Variant call outputs
└── results/            # Workflow results
```

## Topics covered

### Viral genomics (hetfo → kedd → szerda)

Working with **Zaire ebolavirus Mayinga** (NC_002549.1, 18,959 bp, accession GCF_000848505.1):

| Step | Tool | Output |
|------|------|--------|
| Reference download | `wget` / `ncbi-datasets-cli` | FASTA + GFF |
| Read download | `fastq-dump` / EBI FTP | FASTQ |
| Read QC | `fastp` / `fastqc` | QC reports |
| Alignment | `bwa mem` | BAM |
| Alignment filtering | `samtools view` | filtered BAM |
| Variant calling | `bcftools mpileup \| call \| norm \| sort` | VCF.gz |
| Visualization | IGV | session XML |

The `kedd` session targets SRR1972738 (Ebola-targeted sequencing, ~541k reads); `snpcall` uses SRR1553425 / AF086833.

### RNA-Seq differential expression (csut)

HBR vs UHR comparison on chromosome 22:

```bash
cd bioinfo/csut
make download   # fetch UHR/HBR reads from biostarhandbook.com
make index      # HiSat2 genome index for chr22
make align      # align all 6 samples (HBR_1–3, UHR_1–3)
make count      # featureCounts with reverse-stranded flag
make add_names  # BioMart tx2gene mapping
make edger      # edgeR differential expression → gene_expression.csv
make pca        # PCA plot → csv/pca.pdf
make heatmap    # heatmap → csv/heatmap.pdf
```

R scripts used: `edger.r`, `deseq2.r`, `plot_pca.r`, `plot_heatmap.r`, `format_featurecounts.r`, `create_tx2gene.r`, `combine_salmon.r`.

### Advanced workflow modules (src/workflows/)

**`airway.mk`** — Salmon-based RNA-Seq of the airway dataset (dexamethasone treatment, 8 samples, GRCh38 cDNA):
```bash
make -f src/workflows/airway.mk all
```

**`benchmark.mk`** — Benchmark BWA / HISAT2 / STAR / Salmon across 5 organisms (yeast, *Drosophila*, rice, zebrafish, human):
```bash
make -f src/workflows/benchmark.mk all
```

**`snpcall.mk`** — Parallel variant calling: splits BAM by chromosome, calls variants on each chromosome in parallel, then merges with `bcftools concat`:
```bash
make -f src/workflows/snpcall.mk run SRR=SRR6808334 NCPU=4
```

**ELIXIR exercise** — Somatic variant calling on GIAB HG008 pancreatic cancer sample (normal ductal vs tumour cell line, PacBio Onso data):
```bash
# see bioinfo/csut/src/elixir/README.md for full command sequence
```

## Environment setup

All tools are managed via [pixi](https://pixi.sh). Install pixi, then:

```bash
cd bioinfo
pixi install          # installs samtools, bwa, bcftools, hisat2, R + Bioconductor packages, etc.
pixi shell            # activate the environment
```

Key packages in `bioinfo/pixi.toml`: `samtools`, `bwa`, `bcftools`, `hisat2`, `subread` (featureCounts), `fastp`, `fastqc`, `sra-tools`, `bedtools`, `bioconductor-edger`, `bioconductor-deseq2`, `bioconductor-tximport`, `r-gplots`.

## Nextflow automation

`main.nf` is a small Nextflow DSL2 pipeline that generates a run summary and then automatically commits and pushes changes to the repository:

```bash
nextflow run main.nf
```

The `COMMIT_AND_PUSH` process runs on the local executor so it has access to SSH keys, checks for staged changes, and commits using the Nextflow run name as the commit message.

## IGV visualization

After alignment, open results in IGV:

```bash
# Option A — session file (kedd)
igv igv_session.xml

# Option B — IGV batch commands via netcat (snpcall / szerda)
make igv
```

The session loads the Ebola Mayinga reference, GFF annotation, and the BAM alignment track. Navigate to `NC_002549.1:1-18959` to view the full genome.
