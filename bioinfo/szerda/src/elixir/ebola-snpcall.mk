#
# Soundtrack: https://www.youtube.com/watch?v=JtyByefOvgQ
#

# NCBI accession number.
ACC = AF086833

# SRA IDs.
DESIGN = design.csv

# Reference sequence.
REF = refs/${ACC}.fa

# Annotation sequence
GFF = refs/${ACC}.gff

# Merged BAM file.
BAM = all/${ACC}-alignments.bam

# Merged VCF file
VCF = all/${ACC}-variants.vcf.gz

# Additional bcf flags for pileup annotation.
PILE_FLAGS =  -d 100 --annotate 'INFO/AD,FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/SP'

# Additional bcf flags for calling process.
CALL_FLAGS = --ploidy 2 --annotate 'FORMAT/GQ' 

# Parallel flags.
PF = --header : --colsep ',' --eta --halt now,fail=1

# Makefile settings
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory

# Programs required to run pipeline
TOOLS = iqtree mafft bwa samtools bcftools bio

help: 
	@echo "#"
	@echo "# MISSION IMPOSSIBLE: EBOLA VARIANT DETECTION"
	@echo "#"
	@echo "# Your mission, should you choose to accept it,"
	@echo "# is to call the variants on the Ebola virus genome."
	@echo "#"
	@echo "# You have 60 seconds to complete your mission."
	@echo "#"
	@echo "# This pipeline will self-destruct in 5 seconds..."
	@echo "#"
	@echo "# make all"
	@echo "#"
	@echo "# Good luck, Agent."
	@echo "#"

	@for tool in $(TOOLS); do \
		if ! command -v $$tool > /dev/null; then \
			echo "# Error: $$tool is not installed"; \
			echo "#"
			echo "# Try: micromamba install iqtree mafft bwa samtools bcftools; pip install bio"; \
			echo "#"
			exit 1; \
		fi; \
	done

${DESIGN}:
	@cat << EOF > ${DESIGN}
	SRR,Name
	SRR1553426,EM110.FCH9
	SRR1553480,G3724.FCH9
	SRR1553479,G3724_r1.ADXX
	SRR1972741,G4254.1.l1
	SRR1553442,EM124.1.FCH9
	SRR1972718,G4151.1.l1
	SRR1553474,G3713.2.FCH9
	SRR1553473,G3713.2_r1.ADXX
	SRR1553475,G3713.3_r1.ADXX
	SRR1553477,G3713.4_r1.ADXX
	SRR1553478,G3713.4.FCH9
	SRR1553476,G3713.3.FCH9
	SRR1553589,G3845_r1.ADXX
	SRR1972731,G4217.1.l1
	SRR1972966,G6060.1.l2
	SRR1553590,G3845.FCH9
	EOF

# Shortcut to generating the ids.txt file.
design: ${DESIGN}
	ls -l ${DESIGN}

# Fetch the reference sequence.
${REF}:
	# Create the directory.
	mkdir -p $(dir ${REF})
	
	# Fetch the reference sequence.
	bio fetch ${ACC} --format fasta > ${REF}

	# Fetch the annotation sequence.
	bio fetch ${ACC} --format gff > ${GFF}

	# samtools index of the reference sequence.
	samtools faidx ${REF}

# Shortcut to generating the reference sequence.
refs: ${REF} ${DESIGN}
	ls -l ${REF} ${GFF}

# Shortcut to generating the fastq files.
fastq: ${DESIGN}
	cat ${DESIGN} | parallel ${PF} fastq-dump -X 15000 -O reads --split-files {SRR} 1> /dev/null
	
# Shortcut to generating the bam files.
bam: ${REF} ${DESIGN}
	mkdir -p bam all

	# bwa index the reference sequence.
	bwa index ${REF}

	# Align the reads to the reference sequence.
	cat ${DESIGN} | parallel ${PF} "bwa mem -R '@RG\tID:{SRR}\tSM:{Name}\tLB:{Name}' ${REF} reads/{SRR}_1.fastq reads/{SRR}_2.fastq | samtools sort --write-index -o bam/{Name}.bam"

	# Merge all BAM files into a single BAM file.
	samtools merge -f --write-index -o ${BAM} bam/*.bam

# Shortcut to generating the vcf files.
vcf: ${REF} ${DESIGN}
	mkdir -p vcf all

	# Call variants for each sample separately
	cat ${DESIGN} | parallel ${PF} "bcftools mpileup ${PILE_FLAGS} -O u -f ${REF} bam/{Name}.bam | \
		bcftools call ${CALL_FLAGS} -mv -O u | \
		bcftools norm -f ${REF} -d all -O u | \
		bcftools sort -W -O z -o vcf/{Name}.vcf.gz"

	# Merge all VCF files
	bcftools merge -W -O z vcf/*.vcf.gz -o ${VCF}

# Shortcut to generating the consensus sequence.
cons:
	mkdir -p genomes tree
	cat ${DESIGN} | parallel ${PF} "samtools consensus bam/{Name}.bam | bio fasta --rename {Name}  > genomes/{Name}.fa"

# Shortcut to generating the tree.
tree:
	cat ${REF} genomes/*.fa > tree/combined.fa	
	mafft --auto tree/combined.fa > tree/aligned.fa
	iqtree2 -s tree/aligned.fa --redo --prefix tree/evolution

	# Show the tree on the screen.
	cat tree/evolution.iqtree | tail -64 | head -38

# Shortcut to populating IGV.
igv:
	echo "genome $$PWD/${REF}" | nc localhost 60151
	echo "load $$PWD/${GFF}" | nc localhost 60151
	echo "load $$PWD/${VCF}" | nc localhost 60151
	echo "load $$PWD/${BAM}" | nc localhost 60151

# Shortcut to running the pipeline.
all: refs fastq bam vcf cons igv tree 

# Shortcut to cleaning up the files.
clean:
	rm -rf ${REF} ${GFF} ${DESIGN} bam vcf refs reads tree tmp genomes all 

.PHONY: help ids refs fastq bam vcf igv clean cons tree all