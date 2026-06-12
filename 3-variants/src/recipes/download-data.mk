#
# Download data from Ensembl, GenBank, and NCBI.
#
# Docs: https://www.biostarhandbook.com/
#

# Chromosome Y of the human genome.
URL = http://ftp.ensembl.org/pub/release-104/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz

# The name of the local file for the data.
FILE = refs/chrY.fa.gz

# GenBank accession.
ACC=AF086833

# The name of the fasta file
FASTA = refs/${ACC}.fa

# For NCBI assembly ids
NCB_GCA = GCA_000005845.2

# We found out the file name structure only after we downloaded it.
NCBI_FASTA = refs/${NCB_GCA}.fa


# Makefile settings
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

usage:
	@echo "#"
	@echo "# Ensembl:"
	@echo "#"
	@echo "# URL=${URL}"
	@echo "# FILE=${FILE}"
	@echo "#"
	@echo "# GenBank:"
	@echo "#"
	@echo "# ACC=${ACC}"
	@echo "# FASTA=${FASTA}"
	@echo "#"
	@echo "# NCBI:"
	@echo "#"
	@echo "# NCB_GCA=${NCB_GCA}"
	@echo "# NCBI_FASTA=${NCBI_FASTA}"
	@echo "#"
	@echo "# make ensembl genbank assembly"
	@echo "#"

# Downlaoding Ensembl files.
# Ensembl provides gzip files instead of bg-zipped FASTA. We need to recompress with bgzip.
${FILE}:

	# Create the directory for the file.
	mkdir -p $(dir $@)

	# Download the file.
	curl ${URL} > ${FILE}

	# Compress the file with bgzip.
	make -f src/run/bgzip.mk run FILE=${FILE}

ensembl: ${FILE}
	@ls -lh $<

# Accessing GENBANk files.
${FASTA}:
	mkdir -p $(dir $@)
	bio fetch ${ACC} -format fasta > $@

# Download the GENBANK fasta.
genbank: ${FASTA}
	@ls -lh $<

# The assembly fasta file generation.
${NCBI_FASTA}:

	# Create the directory for the file.
	mkdir -p $(dir $@)

	# Download the file.
	datasets download genome accession ${NCB_GCA}  --filename ncbi_dataset.zip

	# Unzip skipping overwrite
	unzip -n ncbi_dataset.zip

	# Copy the assembly fasta file to the reference file.
	cp ncbi_dataset/data/${NCB_GCA}*/${NCB_GCA}*genomic.fna $@

# Download the NCBI genome assembly
assembly: ${NCBI_FASTA}
	@ls -lh $<

# Run all the tests.
run: ensembl genbank assembly

run!:
	rm -rf ${FILE} ${FASTA} ncbi_dataset.zip ncbi_dataset

all: run

clean: run!

# Targets that are not files.
.PHONY: usage ensembl genbank assembly run clean all
