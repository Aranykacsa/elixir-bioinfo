# The URL to the genome FASTA file.
FASTA_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.fna.gz

# The URL to the genome GFF file.
GFF_URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.gff.gz

# The common for the genome file names.
GENOME=ebola-mayinga

# The path to the genome FASTA file.
FASTA=refs/${GENOME}.fasta

# The path to the genome GFF file.
GFF=refs/${GENOME}.gff

# The SRR ID of the sample.
# SRR1972738: targeted Ebola genome sequencing (~541k reads, high viral coverage)
# SRR1972976: bulk patient RNA-Seq (mostly human reads, 0% viral mapping with 10k limit)
SRR=SRR1972738

# The name of the sample
SAMPLE=${SRR}

# The name of the alignment BAM file
BAM=results/${SAMPLE}.bam

# The number of reads to download.
LIMIT=10000

# The path to the read files
R1=reads/${SRR}_1.fastq.gz
R2=reads/${SRR}_2.fastq.gz

# The filtered BAM (properly paired, mapped, quality >= 20)
FILTERED=results/${SAMPLE}.filtered.bam

# The output VCF file
VCF=vcf/${SAMPLE}.vcf.gz

# Flags for bcftools mpileup
PILEUP_FLAGS=-d 100 --annotate 'INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP'

# Flags for bcftools call (ploidy 1 = haploid, correct for RNA virus)
CALL_FLAGS=--ploidy 1 --annotate 'FORMAT/GQ'

all: align stats filter call

help:
	@echo "Use the source, Luke!"

# Download and unzip the fasta and gff files
genome:
	mkdir -p refs
	wget -O ${FASTA}.gz ${FASTA_URL}
	wget -O ${GFF}.gz ${GFF_URL}
	gunzip -f ${FASTA}.gz
	gunzip -f ${GFF}.gz

# Download the reads from SRA (slow, limited to LIMIT reads)
fastq:
	mkdir -p reads
	fastq-dump -X ${LIMIT} --outdir reads --split-files --gzip ${SRR}

# Download the reads directly from EBI FTP (fast, full dataset)
fastq-ebi:
	mkdir -p reads
	wget -c -O ${R1} https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR197/008/${SRR}/${SRR}_1.fastq.gz
	wget -c -O ${R2} https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR197/008/${SRR}/${SRR}_2.fastq.gz

# Index the genome for bwa
index: genome
	bwa index ${FASTA}

# Align the reads to the genome
align: index fastq-ebi
	mkdir -p results
	bwa mem -t 4 ${FASTA} ${R1} ${R2} | \
		samtools sort --write-index -o ${BAM}
	samtools index -b ${BAM}
	samtools flagstat ${BAM}

# Show alignment statistics
stats:
	samtools flagstat ${BAM}
	samtools idxstats ${BAM}

# Filter: keep properly paired mapped reads with mapping quality >= 20
filter: align
	samtools view -b -f 2 -F 4 -q 20 ${BAM} > ${FILTERED}
	samtools index ${FILTERED}
	samtools flagstat ${FILTERED}

# Call variants with bcftools (pileup -> call -> normalize -> sort)
call: align
	mkdir -p vcf
	bcftools mpileup ${PILEUP_FLAGS} -O u -f ${FASTA} ${BAM} | \
	  bcftools call ${CALL_FLAGS} -mv -O u | \
	  bcftools norm -f ${FASTA} -d all -O u | \
	  bcftools sort -O z > ${VCF}
	bcftools index ${VCF}
	bcftools stats ${VCF} | grep "^SN"

# Open the alignment in IGV
igv:
	igv igv_session.xml &

# Remove all the derived files
clean:
	rm -rf reads results refs vcf

# Targets that are not files.
.PHONY: all genome fastq fastq-ebi index align stats filter call igv clean
