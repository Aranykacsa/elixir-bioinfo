#
# Annotating SNP effects with SNPeff.
#

# This is here to be able to generate the names
# more easily. You can also pass the other arguments
# with full paths.
NAME = Ebola.Mayinga.1976

# The label for the SNPeff database.
LABEL ?= ${NAME}

# Genbank accession number.
REF = refs/${NAME}.fa

# The GenBank annotation file.
GTF ?= refs/${NAME}.gtf

# Protein sequences
PROTS ?= refs/${NAME}.protein.fa

# The variant calls that need to be annotated.
VCF ?= vcf/variants.vcf.gz

# # The directory that holds the SNPeff database.
IDX_DIR ?= refs/idx/snpEff/

# The SNPeff database.
IDX ?= ${IDX_DIR}/${LABEL}/snpEffectPredictor.bin

# Trying to figure out the root of the VCF file.
root_vcf = $(notdir $(basename $(basename ${VCF})))

# Annotated variants.
ANN ?= snpeff/${root_vcf}.snpeff.vcf.gz

# Derive the name of the SNPeff html report.
HTML ?= $(basename ${ANN}).html

# Derive the name of the SNPeff CSV report.
CSV ?= $(basename ${ANN}).csv

# The SNPeff configuration file.
CONFIG ?= snpeff.config

# Makefile customizations.
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

# General usage information.
usage:
	@echo "#"
	@echo "# snpeff.mk: annotate variants calls with SNPeff."
	@echo "#"
	@echo "# NAME=${NAME}"
	@echo "# LABEL=${LABEL}"
	@echo "#"
	@echo "# CONFIG=${CONFIG}"
	@echo "# IDX=${IDX}"
	@echo "# IDX_DIR=${IDX_DIR}"
	@echo "#"
	@echo "# REF=${REF}"
	@echo "# GTF=${GTF}"
	@echo "# PROTS=${PROTS}"
	@echo "# VCF=${VCF}"
	@echo "#"
	@echo "# ANN=${ANN}"
	@echo "# HTML=${HTML}"
	@echo "# CSV=${CSV}"
	@echo "#"
	@echo "# make build|run|clean"
	@echo "#"

# Check the reference file.
${REF}:
	@echo "#"
	@echo "# REF not found: ${REF}"
	@echo "#"
	exit -1

# Check the GFF file.
${GTF}:
	@echo "#"
	@echo "# GTF not found: ${GTF}"
	@echo "#"
	exit -1

# Check the GFF file.
${VCF}:
	@echo "#"
	@echo "# VCF not found: ${VCF}"
	@echo "#"
	exit -1

${PROTS}:
	@echo "#"
	@echo "# PROTS not found: ${PROTS}"
	@echo "#"
	exit -1

check:
	@if ! command -v snpEff > /dev/null; then \
		echo "# Error: snpEff is not installed"; \
		echo "# Try: micromamba install snpeff"; \
		exit 1; \
	fi; 
	@if ! command -v bcftools > /dev/null; then \
		echo "# Error: bcftools is not installed"; \
		echo "# Try: micromamba install bcftools"; \
		exit 1; \
	fi; 

# Building a custom snpEff database snpeff needs the files in specific folders.
# 1. copy the files to their specific location.
# 2. append entry to current genome to the config.
# 3. Build the snpEff database.
${IDX}: ${GTF} ${REF} ${PROTS} check
	mkdir -p $(dir $@) $(dir ${CONFIG}) 

	# Create the SNPeff configuration file.
	echo "${LABEL}.genome : ${LABEL}" >	${CONFIG}

	# Copy the files to the snpEff folder.
	cp -f ${REF} $(dir $@)/sequences.fa
	cp -f ${GTF} $(dir $@)/genes.gtf
	cp -f ${PROTS} $(dir $@)/protein.fa

	# Build the database.
	snpEff build \
		-noCheckCds \
		-noCheckProtein \
		-gtf22 \
		-dataDir ${IDX_DIR} \
		-v ${LABEL} \
		-c ${CONFIG}

# Create the annotated VCF file.
${ANN}: 
	mkdir -p $(dir ${ANN}) $(dir ${HTML}) $(dir ${CSV})
	snpEff ann \
		-nodownload \
		-config ${CONFIG} \
		-csvStats ${CSV} \
		-s ${HTML} \
		-dataDir ${IDX_DIR} \
		${LABEL} \
		${VCF} | bcftools view -O z -o ${ANN}
	bcftools index -f ${ANN}

# Creates the SNPeff database
build: ${IDX}
	@ls -lh ${IDX}

# Another name for index
index: build

# Removes the SNPeff database
build!:
	rm -f ${SNPEFF_DB}

# Runs the SNPeff tool.
run: ${ANN} 
	@ls -lh ${ANN}
	@ls -lh ${HTML}
	@ls -lh ${CSV}

# Removes the SNPeff output
clean:
	rm -f ${ANN} ${HTML} ${CSV} 

# Removes the SNPeff database
realclean: clean
	rm -rf ${IDX}

# Another name cleanup
run!: clean

# Shows the usage information.
install::
	@echo micromamba install snpeff

.PHONY: run
