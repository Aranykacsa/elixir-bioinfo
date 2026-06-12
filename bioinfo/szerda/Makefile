FASTA_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.fna.gz

# The URL to the annotation.
GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.gff.gz

# The name of the genome.
GENOME=ebola-mayinga

# The path to the genome FASTA file.
FASTA=refs/${GENOME}.fasta

# The path to the genome GFF file.
GFF=refs/${GENOME}.gff

# The SRR ID of the sample.
SRR=SRR1553425

# The name of the sample
SAMPLE=${SRR}

# The name of the alignment BAM file
BAM=bam/${SAMPLE}-${GENOME}.bam

# The number of reads to download.
LIMIT=10000

# The path to the read files
R1=fastq/${SRR}_1.fastq
R2=fastq/${SRR}_2.fastq

VCF=vcf/$(GENOME).vcf.gz

help:
	@echo "Use the source, Luke!"

# Download and unzip the fasta and gff files
genome:
	mkdir -p refs
	wget -O ${FASTA}.gz ${FASTA_URL}
	wget -O ${GFF}.gz ${GFF_URL}
	gunzip -f ${FASTA}.gz
	gunzip -f ${GFF}.gz
	bwa index ${FASTA}

# Download the reads from SRA
fastq:
	mkdir -p fastq
	fastq-dump -X ${LIMIT} --outdir fastq --split-files ${SRR}

# Align the reads to the genome
align:
	mkdir -p bam
	bwa mem -t 4 ${FASTA} ${R1} ${R2} | \
		samtools sort --write-index -o ${BAM}
	samtools flagstat ${BAM}

vcf:
	make -f src/run/bcftools.mk REF=$(FASTA) BAM=$(BAM) VCF=$(VCF) run

# Open IGV with the results
igv: vcf
	echo "new" | nc localhost 60151
	echo "genome $$PWD/${FASTA}" | nc localhost 60151
	echo "load $$PWD/${GFF}" | nc localhost 60151
	echo "load $$PWD/${VCF}" | nc localhost 60151
	echo "load $$PWD/${BAM}" | nc localhost 60151

# Remove all the derived files
clean:
	rm -rf fastq bam refs vcf

.PHONY: genome fastq index align vcf igv clean
