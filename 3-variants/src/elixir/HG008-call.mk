#
# This makefile aligns and calls variants for the HG0008 dataset.
#

# The local reference fasta file.
REF = refs/chr22.fa.gz

# R1 and R2 fastq files.
R1 = reads/HG008_N_R1.fq.gz
R2 = reads/HG008_N_R2.fq.gz

# The local bam file.
BAM = bam/HG008_N.bam

# The local vcf file.
VCF = vcf/HG008_N.vcf.gz

# Better defaults for the Makefile.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:

help:
	@echo "# Use the source, Luke!"

# Perform the alignment.
${BAM}: ${R1} ${R2}
	make -f src/run/bwa.mk BAM=${BAM} R1=${R1} R2=${R2} REF=${REF} run

${VCF}: ${BAM}
	make -f src/run/bcftools.mk BAM=${BAM} REF=${REF} VCF=${VCF} run

# Index the genome.
index:
	make -f src/run/bwa.mk REF=${REF} index

# Check the bam file.
bam: ${BAM}
	@ls -lh ${BAM}

vcf: ${VCF}
	@ls -lh ${VCF}

# Run the pipeline.
run: bam vcf

# Clean up the data.
clean:
	rm -f ${BAM} ${BAM}.* ${VCF} ${VCF}.*

.PHONY: help bam vcf

