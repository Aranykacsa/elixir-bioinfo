#
# Downloads Genome data from NCBI.
#

# Accession number
ACC ?= GCF_000848505.1

#
# Datasets will add an assembly name for the genome.
#
# You can find the assembly name with: 
#
#  make info ACC=GCF_000840245.1 | grep assembly_name
#
NAME ?= Ebola.Mayinga.1976

# The genome file name as downloaded.
GENOME_FA = ncbi_dataset/data/${ACC}*/${ACC}*_genomic.fna

# The GFF file name as downloaded.
GENOME_GFF = ncbi_dataset/data/${ACC}*/genomic.gff

# The GTF file name as downloaded.
GENOME_GTF = ncbi_dataset/data/${ACC}*/genomic.gtf

# The protein file name as downloaded.
GENOME_PROTS = ncbi_dataset/data/${ACC}*/protein.faa

# The final names for the reference and GFF files.
REF = refs/${NAME}.fa
GFF = refs/${NAME}.gff
GTF = refs/${NAME}.gtf
PROTS = refs/${NAME}.protein.fa

# Which files to download.
INCLUDE ?= genome,gff3,gtf,protein

# Makefile customizations.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Print usage information.
usage:
	@echo "#"
	@echo "# datasets.mk: downloads NCBI genomes"
	@echo "#"
	@echo "# ACC=${ACC}"
	@echo "# NAME=${NAME}"
	@echo "#"
	@echo "# REF=${REF}"
	@echo "# GFF=${GFF}"
	@echo "# GTF=${GTF}"
	@echo "# PROTS=${PROTS}"
	@echo "#"
	@echo "# make info|name|run|clean "
	@echo "#"

# Print the summary information on the genome.
info:
	@datasets summary genome accession ${ACC} | jq

# Finds the assembly name for an accession
name:
	@datasets summary genome accession ${ACC} | jq '.reports[] | {accession: .paired_accession, assembly_name: .assembly_info.assembly_name}'

# Not all files are available for all genomes.
${REF}:
	@if ! command -v datasets > /dev/null; then \
		echo "# Error: datasets tool is not installed"; \
		echo "# Try: micromamba install ncbi-datasets-cli"; \
		exit 1; \
	fi; \

	# Download the genome.
	datasets download genome accession ${ACC} --include ${INCLUDE} --filename ncbi_dataset.zip

	# Never overwrite files when unzipping!
	unzip -n ncbi_dataset.zip -x README.md md5sum.txt
	
	# Clean up the zip file.
	rm -f ncbi_dataset.zip

	# Make the reference directories
	mkdir -p $(dir ${REF}) $(dir ${GFF})

	# Copy the genome file to the reference directory.
	cp ${GENOME_FA} ${REF}

	# If the GFF file exists copy it to destination.
	@if [ -f ${GENOME_GFF} ]; then \
		cp ${GENOME_GFF} ${GFF}; \
	fi; 

	# If the GTF file exists copy it to destination.
	@if [ -f ${GENOME_GTF} ]; then \
		cp ${GENOME_GTF} ${GTF}; \
	fi; 

	# If the protein file exists copy it to destination.
	@if [ -f ${GENOME_PROTS} ]; then \
		cp ${GENOME_PROTS} ${PROTS}; \
	fi; 

# Show the files if they exist.
run: ${REF}
	ls -lh ${REF} ${GENOME_FA}
	@for target in ${GFF} ${GTF} ${PROTS}; do \
		[ -f "$$target" ] && ls -lh "$$target"; \
	done; 

# These are shortcuts to match previous documentation.
# Use the run target instead.
fasta: run
gff: run
gtf: run
protein: run

# Triggers the download if the files does not exist.
stats: ${REF}
	seqkit stats ${REF}

# Cleanup the downloaded files.
clean:
	rm -rf ncbi_dataset/data/${ACC}*
	rm -f md5sum.txt ncbi_dataset.zip ${REF} ${GFF} ${GTF}

# A shortcut to clean.
run!: clean

# Test the tool
test: clean run

# Update the datasets tool.
update:
	micromamba update ncbi-datasets-cli

# Mark the targets that do not create files.
.PHONY: usage info name run stats clean run! test update