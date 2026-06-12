#
# Annotating SNP effects with Ensembl VEP.
#

#
# Assumers that you have installed the VEP software
# into a separate enviroment as described in
#
# https://www.biostarhandbook.com/fast/methods/vep/
#


# Genbank accession number.
REF = refs/genome.fa

# The GenBank annotation file.
GFF ?= refs/annotations.gff

# Existing Variant calls.
VCF ?= vcf/variants.vcf.gz

# Annotation results.
ANN ?= ann/$(notdir $(basename ${VCF})).vep.txt

# The directory where VEP is installed.
VEP_DIR ?= ~/src/ensembl-vep/vep

# Makefile customizations.
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

# General usage information.
usage::
	@echo "#"
	@echo "# vep.mk: annotate variants calls with Ensembl VEP."
	@echo "#"
	@echo "# VEP_DIR=${VEP_DIR}"
	@echo "# REF=${REF}"
	@echo "# GFF=${GFF}"
	@echo "# VCF=${VCF}"

	@echo "#"
	@echo "# ANN=${ANN}"
	@echo "#"
	@echo "# make run|clean"
	@echo "#"

# Check the reference file.
${REF}:
	@echo "#"
	@echo "# REF not found: ${REF}"
	@echo "#"
	exit -1

# Check the GFF file.
${GFF}:
	@echo "#"
	@echo "# GFF not found: ${GFF}"
	@echo "#"
	exit -1

# Check the GFF file.
${VCF}:
	@echo "#"
	@echo "# VCF not found: ${VCF}"
	@echo "#"
	exit -1

# VEP needs a sorted and compressed GFF file.
${GFF}.gz:
	cat ${GFF} | sort -k1,1 -k4,4n -k5,5n -t$$'\t' | awk 'NF' | bgzip -c > ${GFF}.gz

	# Index the GFF file
	tabix -p gff ${GFF}.gz

# VEP is installed in the environment called vep
${ANN}: ${GFF}.gz
	mkdir -p $(dir ${ANN})
	micromamba run -n vep \
		${VEP_DIR} \
		-i ${VCF} \
		-o ${ANN} \
		--gff ${GFF}.gz \
		--fasta ${REF} \
		--force_overwrite 

# Runs the SNPeff tool.
run: ${ANN} 
	@ls -lh ${ANN}

# Removes the SNPeff output
clean:
	rm -f ${ANN} ${GFF}.gz

.PHONY: run clean usage
