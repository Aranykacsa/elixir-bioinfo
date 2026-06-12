
# Make sure we run in bash.
SHELL = bash

# Accession number for reference genome.
ACC ?= AF086833

# Accession number for the SRA run.
SRR ?= SRR1553425

# Number of compute cores.
CPU ?= 4

# Number of test reads used when running testdata.
LIMIT ?=10000

# GenBank reference file.
GBK=${ACC}.gbk

# Fasta reference file.
REF=refs/${ACC}.fa

# GFF reference file.
GFF=refs/${ACC}.gff

# All names will have this common element.
ROOT=${SRR}-${ACC}

# Alignment file.
BAM=bam/${ROOT}.bam

# Variant file.
VCF=vcf/${ROOT}.vcf.gz

# The annotated VCF file.
ANN=vcf/${ROOT}.annotated.vcf.gz

# Original read names.
R1=fastq/${SRR}_1.fastq
R2=fastq/${SRR}_2.fastq

# Name of the quality trimmed read pairs.
Q1=fastq/${SRR}_1P.fq
Q2=fastq/${SRR}_2P.fq

# Name of the adapter FASTA file.
ADAPTER_FASTA = adapter.fa

# The BWA index.
IDX=${REF}.amb

# Phony targets instruct make to use these as rules only.
.PHONY: data vcf


# Check that the GNU make version is 4 or higher.
MAKE_MAJOR := $(firstword $(subst ., ,$(MAKE_VERSION)))

ifeq ($(shell [ $(MAKE_MAJOR) -lt 4 ] && echo yes),yes)
    $(error This Makefile needs make version 4 or higher. Your version is $(MAKE_VERSION). Update it with 'pixi add make')
endif

# Check that required executables exist.
EXE = bio bwa samtools bcftools trimmomatic
K := $(foreach exec,$(EXE),\
        $(if $(shell which $(exec)),ok,$(error "Program: $(exec) not found.")))

# Print usage.
all:
	@echo "Usage:"
	@echo
	@echo "    make fastq       # downloads the FASTQ data"
	@echo "    make vcf         # generates a VCF file"
	@echo "    make install     # software installation command"
	@echo ""
	@echo "Defaults:"
	@echo ""
	@echo "   ACC=${ACC}  SRR=${SRR}  CPU=${CPU}  LIMIT=${LIMIT}"
	@echo ""



# Removes created files
clean:
	rm -rf ${R1} ${R2} ${Q1} ${Q2} ${BAM} ${VCF} ${GFF} ${REF}

# Rule to make the GFF file.
${GFF}:
	mkdir -p refs
	bio fetch ${ACC} -format gff > ${GFF}

# Rule to make the reference genome.
# We stick the GFF here as a dependency so that it gets downloaded early on.
${REF}: ${GFF}
	mkdir -p refs
	bio fetch ${ACC} -format fasta > ${REF}
	samtools faidx ${REF}

# The index depends on the reference genome.
${IDX}: ${REF}
	bwa index ${REF}
	echo ${IDX}

# Download a subset (test) of the SRA data.
${R1} ${R2}:
	mkdir -p $(dir ${R1})
	fastq-dump -F -X ${LIMIT} --split-files -O $(dir ${R1}) ${SRR}

fastq: ${R1} ${R2}
	ls -l ${R1} ${R2}

# Apply quality control to the reads.
${Q1} ${Q2}: ${R1} ${R2}

	# Generate both adapters.
	echo ">illumina" > ${ADAPTER_FASTA}
	echo "AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC" >> ${ADAPTER_FASTA}
	echo ">nextera" >> ${ADAPTER_FASTA}
	echo "CTGTCTCTTATACACATCTCCGAGCCCACGAGAC" >> ${ADAPTER_FASTA}

	# Apply the trimming.
	trimmomatic PE -threads ${CPU} -phred33 -basein fastq/${SRR}_1.fastq -baseout fastq/${SRR}.fq\
		ILLUMINACLIP:${ADAPTER_FASTA}:2:30:5 SLIDINGWINDOW:4:15 MINLEN:50

# BAM file depends on the BWA index and reads.
${BAM}: ${IDX} ${Q1} ${Q2}
	mkdir -p $(dir ${BAM})
	# Note how we filter alignment for mapped reads only.
	bwa mem -t ${CPU} ${REF} ${Q1} ${Q2} | samtools view -b -F 4 | samtools sort -@ ${CPU} > ${BAM}
	samtools index ${BAM}
	samtools flagstat ${BAM}

# The VCF file depends on the BAM file.
${VCF}: ${BAM}
	mkdir -p $(dir ${VCF})
	bcftools mpileup -O v -f ${REF} ${BAM}  | bcftools call --ploidy 1 -mv -O z -o ${VCF}
	bcftools index ${VCF}
	printf "\n# VCF file: ${VCF}\n"

# Generate the VCF file
vcf: ${VCF}
	ls -l ${VCF}

# Show the required software
install:
	@echo pixi add bio make bwa samtools bcftools trimmomatic sra-tools fastqc python=3.12

# Automating IGV visualization
IGV = nc localhost 60151
PWD = $(shell pwd)
igv:
	# Create a new session
	echo "new" | ${IGV}

	# Load the genome
	echo "genome ${PWD}/${REF}" | ${IGV}

	# Load the annotation file
	echo "load ${PWD}/${GFF}" | ${IGV}

	# Load the BAM file
	echo "load ${PWD}/${BAM}" | ${IGV}

	# Load the VCF file
	echo "load ${PWD}/${VCF}" | ${IGV}

.PHONY: install clean vcf fastq

