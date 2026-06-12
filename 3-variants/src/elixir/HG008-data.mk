#
# This makefile obtains a subset of the fastq files for the HG0008 dataset.
#

# Chromosome and limits for the region of interest.
CHR = chr22
LIM = 41961537-50818469

# Seed and fraction for subsampling the bam files.
SEED = 50
FRAC = 5

# The published bam file.
BAM_URL = https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/PacBio_Onso_20240415/HG008-N-D_Pacbio-onso_48x_GRCh38-GIABv3.bam

# The local bam file.
BAM = giab/HG008-N-D_NIST.bam

# R1 and R2 fastq files.
R1 = reads/HG008-N-D_R1.fq.gz
R2 = reads/HG008-N-D_R2.fq.gz

# The published variants vcf file.
VCF_URL = https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/analysis/Ultima_DeepVariant-somatic-SNV-INDEL_20240822/HG008_edv_AF_recalibration.result.PASS.vcf.gz

# The local vcf file.
VCF = giab/HG008_NIST.vcf.gz

# The published reference fasta file.
REF_URL = https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/${CHR}.fa.gz

# The local reference fasta file.
REF = refs/${CHR}.fa.gz

# Better defaults for the Makefile.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:

# Print the help message.
help:
	@echo "# Read the source, Luke!"

# Commands to obtain the bam file.
${BAM}:
	# Create the directory for the bam file.
	mkdir -p $(dir $@)

	# Obtain the bam file.
	samtools view -s ${SEED}.${FRAC} -b ${BAM_URL} ${CHR}:${LIM} | samtools sort --write-index -o ${BAM}

	# Remove the remote BAM index. 
	rm -f *.bai

# Commands to extract FASTQ reads from a BAM file.
${R1} ${R2}: ${BAM}
	# Create the directory for the fastq files.
	mkdir -p $(dir $@)

	# Create the fastq file.
	samtools collate -O ${BAM}| samtools fastq -s /dev/null -1 ${R1} -2 ${R2} 
	
# Commands to select variants in the region of interest.
${VCF}: 
	# Create the directory for the vcf file.
	mkdir -p $(dir $@)

	# Download the variants file.

	# NOTE: Certain fields like BG_SB and SB seem to be invalid and fail when merging. 
	# We remove these here.

	# Rename the samples to be consistent with the bam file.
	bcftools view -r ${CHR}:${LIM} ${VCF_URL} | \
		bcftools reheader -s <(echo -e "HG008_T\tHG008_NIST") | \
		bcftools annotate -W -x FORMAT/BG_SB,FORMAT/SB -Oz -o ${VCF} 

	# Remove the remote VCF index. 
	rm -f *.csi *.tbi

	# List the samples in the vcf file.
	bcftools query -l ${VCF}

# Commands to download the reference file.
${REF}:
	# Create the directory for the reference file.
	mkdir -p $(dir $@)

	# Download the reference file.
	curl ${REF_URL} | gunzip -c | bgzip -c > ${REF}

	# Create the reference index.
	samtools faidx ${REF}

	# Create the reference index.	
	make -f src/run/bwa.mk REF=${REF} index

# Commands to check the bam file.
check: ${BAM}
	seqkit stats ${R1} ${R2}
	samtools quickcheck ${BAM}

# Trigger the BAM creation.
bam: ${BAM}
	@ls -lh ${BAM}

# Trigger the fastq file creation.
fastq: ${R1} ${R2}
	@ls -lh ${R1} ${R2}

# Trigger the vcf file creation.
vcf: ${VCF}
	@ls -lh ${VCF}

# Trigger the reference file creation.
ref: ${REF}	
	@ls -lh ${REF}

# Run the entire pipeline.
run: vcf bam fastq ref

# Clean up the data.
clean:
	rm -f ${R1} ${R2} ${BAM} ${BAM}.* 

# Not file targets.
.PHONY: help fastq vcf ref bam run clean