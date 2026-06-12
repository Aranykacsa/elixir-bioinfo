Cikk:
PRJNA257197

Mérések:
SRR1972738

command:
	bio search SRR1972738

---

## IGV Visualization

**Prerequisites:** IGV desktop app ≥ v2.4 installed (<https://igv.org/doc/desktop/>)

### Option A — Session file (recommended)

Open IGV, then:

```
File → Open Session → igv_session.xml
```

This loads the reference genome, gene annotation, and alignment track in one step.
IGV must be opened from the project directory, or use the absolute path to `igv_session.xml`.

### Option B — Manual loading (three steps)

1. **Load reference genome**
   `Genomes → Load Genome from File → refs/ebola-mayinga.fasta`

2. **Load gene annotation**
   `File → Load from File → refs/ebola-mayinga.gff`

3. **Load alignment**
   `File → Load from File → results/SRR1972738.bam`

### What you will see

- **Reference sequence track** — Zaire ebolavirus Mayinga (NC_002549.1, 18,959 bp)
- **Annotation track** — 7 protein-coding genes: NP, VP35, VP40, GP, VP30, VP24, L
- **BAM coverage track** — flat / empty (0 reads mapped — see note below)

Navigate to the full genome: type `NC_002549.1:1-18959` in the search bar.

### Why the coverage track is empty

The workflow downloads only the first 10,000 reads (`LIMIT=10000` in `Makefile`).
These reads come from a patient total-RNA library, so they are almost entirely human
transcripts — none of the first 10k reads happen to be viral.

To get viral reads, download the full dataset and realign:

```bash
# Edit Makefile: remove the -X ${LIMIT} flag from the fastq-dump line, then:
make clean
make align
```

Or override just the limit:

```bash
make align LIMIT=1000000
```

After realigning, reload the BAM in IGV to see Ebola read coverage.
