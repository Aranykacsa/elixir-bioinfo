# The URL for the Denisovan BAM file.
URL =  http://cdna.eva.mpg.de/denisova/alignments/T_hg19_1000g.bam

# The region to extract.
REGION = 7:17,320,000-17,430,000

# The name of the output file.
BAM = denisovan.bam


# Apply Makefile customizations.
.DELETE_ON_ERROR:
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

help:
	@echo "#"
	@echo "# This Makefile will extract the Denisovan reads from the AHM BAM file."
	@echo "#"
	@echo "# make all"
	@echo "#"
	@echo "#"

${BAM}:
	mkdir -p $(dir ${BAM})
	samtools view -b ${URL} ${REGION} > ${BAM}
	samtools index ${BAM}

# Shortcut to generating the BAM file.
bam: ${BAM}
	ls -lh ${BAM}

# Shortcut to running the pipeline.
all: ${BAM}
	ls -lh ${BAM}

