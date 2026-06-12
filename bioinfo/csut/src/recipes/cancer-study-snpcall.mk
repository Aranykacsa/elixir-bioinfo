#
# SNP calling for a cancer study in a bottle.
#
# From: https://www.biostarhandbook.com/fast/
#

# Makefile customizations.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The name of the design file
DESIGN=design.csv

# The URL for the hg38 reference genome
REF_URL=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GRCh38_GIABv3_no_alt_analysis_set_maskedGRC_decoys_MAP2K3_KMT2C_KCNJ18.fasta.gz

# The complete reference file.
REF=refs/GRCh38.fa.gz

# The URL for the complete BAM file.
BAM_URL=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/Element-AVITI-20241216/HG008-N-P_Element-StdInsert_70x_GRCh38-GIABv3.bam

# The name of the region of interest.
NAME=KRAS-N-P

# The chromosome and region of interest.
CHR=chr12

# The start and end positions of the region of interest.
START=24000000
END=26000000

# The region of interest.
REGION=${CHR}:${START}-${END}

# The name of the small BAM file.
BAM=bam/${NAME}.bam

# The VCF file name.
VCF=vcf/${NAME}.vcf.gz

usage:
	@echo "#"
	@echo "# SNP calling for a cancer study in a bottle."
	@echo "#"
	@echo "# Input parameters."
	@echo "#"
	@echo "# NAME=${NAME}"
	@echo "# CHR=${CHR}"
	@echo "# START=${START}"
	@echo "# END=${END}"
	@echo "#"
	@echo "# Resulting files:"
	@echo "#"
	@echo "# REF=${REF}"
	@echo "# BAM=${BAM}"
	@echo "# VCF=${VCF}"
	@echo "#"
	@echo "# make genome|bam|vcf|igv|clean"
	@echo "#"

# Download the full reference genome.
${REF}:
	# Create the directory for the full reference genome.
	mkdir -p $(dir ${REF})

	# Download the full reference genome.
	curl -L -o ${REF} ${REF_URL}

	# Index the full reference genome.
	samtools faidx ${REF}

# Get the subset of the BAM file.
${BAM}:
	# Create the directory for the BAM file.
	mkdir -p $(dir ${BAM})

	# Download the BAM file.
	samtools view -b ${BAM_URL} ${REGION} > ${BAM}

	# Index the BAM file.
	samtools index ${BAM}

# Call variants with bcftools.
${VCF}: ${BAM} ${REF}
	make -f src/run/bcftools.mk \
		REF=${REF} \
		BAM=${BAM} \
		VCF=${VCF} \
		run

# Make the single chromosome reference genome.
genome: ${REF}
	@ls -lh ${REF}

bam: ${BAM}
	@ls -lh ${BAM}

vcf: ${VCF}
	@ls -lh ${VCF}

clean:
	rm -f ${BAM} ${BAM}.bai ${VCF}

# Create the design file
${DESIGN}:
	@cat << EOF > ${DESIGN}
	name,url
	KRAS-N-P,https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/Element-AVITI-20241216/HG008-N-P_Element-StdInsert_70x_GRCh38-GIABv3.bam,HG008-N-P
	KRAS-T,https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/Element-AVITI-20241216/HG008-T_Element-StdInsert_111x_GRCh38-GIABv3.bam
	EOF
	@echo "# Created: ${DESIGN}"

# List the design file.
design: ${DESIGN}
	@ls -lh ${DESIGN}

# Call variants for each sample separately.
batch: ${DESIGN} ${REF}
	cat ${DESIGN} | parallel \
		--header : --colsep , --lb \
		make -f src/recipes/cancer-study-snpcall.mk \
		NAME={name} \
		BAM_URL={url} \
		vcf

# Load the VCF file into IGV.
# IGV should already have the hg38 reference genome loaded.
NC=nc localhost 60151
igv: 
	echo "load $$PWD/${VCF}" | ${NC}

# Targets that are not files.
.PHONY: usage genome bam vcf igv batch clean