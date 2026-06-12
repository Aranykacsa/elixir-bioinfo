#
# SNP evaluation for a cancer study in a bottle.
# From: https://www.biostarhandbook.com/fast/
#

# Makefile customizations.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The link to the DeepVariant VCF file.
# The supposed to be the "gold standard" for the study.
VALID_VCF = https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/analysis/Ultima_DeepVariant-somatic-SNV-INDEL_20240822/HG008_edv_AF_recalibration.result.PASS.vcf.gz

# The complete reference file.
REF=refs/GRCh38.fa.gz

# The region of interest.
REGION=chr12:24000000-26000000

# The two VCF files to evaluate.
VCF_1 = vcf/KRAS-N-P.vcf.gz
VCF_2 = vcf/KRAS-T.vcf.gz

# The VCF file names after evaluation.

# The merged VCF files.
VCF_MERGED=vcf/merged.vcf.gz

# Variants unique to the control sample.
VCF_CONTROL=vcf/control.vcf.gz

# Variants unique to the tumor sample.
VCF_TUMOR=vcf/tumor.vcf.gz

# Removing false positives from the tumor sample.
VCF_FILTERED=vcf/tumor.filtered.vcf.gz

usage:
	@echo "#"
	@echo "# Cancer genome in a bottle."
	@echo "#"
	@echo "# Input parameters."
	@echo "#"
	@echo "# VCF_1=${VCF_1}"
	@echo "# VCF_2=${VCF_2}"
	@echo "#"
	@echo "# Resulting files:"

# Merges the vcf files into a single VCF file
# Also computes unique variants as separate samples.
${VCF_MERGED}: 
 
	mkdir -p $(dir ${VCF_MERGED})
	# Create VCF with variants unique to the first file (KRAS-N-P).
	bcftools isec -c none \
		-p eval/isec/ \
		${VCF_1} \
		${VCF_2}
	
	# Rename the samples in the first isec file.
	bcftools reheader -s <(echo -e "HG008-N-P-Only") \
		vcf/isec/0000.vcf | \
		bcftools view -W -O z -o ${VCF_CONTROL}

	# Rename the samples in the second isec file.
	bcftools reheader -s <(echo -e "HG008-T-Only") \
		vcf/isec/0001.vcf | \
		bcftools view -W -O z -o ${VCF_TUMOR}
	
	# Merge the VCF files 
	bcftools merge -W -O z -o ${VCF_MERGED} \
		${VCF_1} \
		${VCF_2}

# Trigger the merge.
merge: ${VCF_MERGED}
	@ls -lh ${VCF_CONTROL} 
	@ls -lh ${VCF_TUMOR}
	@ls -lh ${VCF_MERGED}

# Load the VCF file into IGV.
NC=nc localhost 60151

# A shortcut to show a VCF file in IGV.
SHOW = ${VCF_MERGED}
igv: 
	echo "load $$PWD/${SHOW}" | ${NC}

# A shortcut to show the valid VCF file.
valid:
	echo "load ${VALID_VCF}" | ${NC}

# Filter the tumor sample to remove false positives.
filter:
	mkdir -p $(dir ${VCF_FILTERED})
	bcftools view \
		--max-alleles 2 \
		--types snps \
		-W -O z \
		-o ${VCF_FILTERED} \
		${VCF_TUMOR}

# Targets that are not files.
.PHONY: usage merge igv check