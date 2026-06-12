# RNA-Seq Analysis with the HiSat2 aligner

# The location for the data
DATA_URL=http://data.biostarhandbook.com/data/uhr-hbr.tar.gz

# The reference genome file
REF=refs/chr22.genome.fa

# The annotation file
GTF=refs/chr22.gtf

# The sample name
SAMPLE = HBR_1

# The path to the read file
R1=reads/${SAMPLE}_R1.fq

# Output alignment file
BAM = bam/${SAMPLE}.bam

# Output coverage file
BW  = bam/${SAMPLE}.bw

# Count files as text
COUNT_TXT = csv/counts.txt

# Count files as CSV
COUNT_CSV = csv/counts.csv

# Differential expression file
DE_CSV = csv/gene_expression.csv

# Design file
DESIGN = design.csv

# Transcript to gene mapping file
TX2GENE = csv/tx2gene.csv

# First target is the help.
help:
	@echo "# SAMPLE=${SAMPLE}"
	@echo "# REF=${REF}"
	@echo "# R1=${R1}"
	@echo "# BAM=${BAM}"
	@echo "# BW=${BW}"
	@echo "# "
	@echo "# make download"
	@echo "# make index"
	@echo "# make align"
	@echo "# make count"
	@echo "# make to_csv"
	@echo "# make add_names"
	@echo "# make edger"
	@echo "# make pca"
	@echo "# make heatmap"

# Download and unpack the data
download:
	curl ${DATA_URL} | tar xzvf -

# Index the genome
index:
	make -f src/run/hisat2.mk REF=${REF} index

# Align the reads to the genome
align:
	make -f src/run/hisat2.mk REF=${REF} R1=${R1} BAM=${BAM} run

# Count the alignments over the features
# The -s 2 flag specifies that the data is reverse-stranded
count:
	mkdir -p csv
	featureCounts -a ${GTF} -s 2 -o ${COUNT_TXT} \
			bam/HBR_1.bam \
			bam/HBR_2.bam \
			bam/HBR_3.bam \
			bam/UHR_1.bam \
			bam/UHR_2.bam \
			bam/UHR_3.bam

# Reformat the counts to a CSV file
to_csv:
	mkdir -p csv
	Rscript src/r/format_featurecounts.r -c ${COUNT_TXT} -o ${COUNT_CSV}

# Get the transcript to gene mapping file
${TX2GENE}:
	mkdir -p csv
	Rscript src/r/create_tx2gene.r -d hsapiens_gene_ensembl -o ${TX2GENE}

# Add gene names to the counts file
add_names: ${TX2GENE}
	Rscript src/r/format_featurecounts.r -t ${TX2GENE} -c ${COUNT_TXT} -o ${COUNT_CSV}

# Run the edgeR analysis
edger: ${DESIGN}
	Rscript src/r/edger.r -d ${DESIGN} -c ${COUNT_CSV} -o ${DE_CSV}

# Generate the PCA plot
pca: ${DESIGN}
	Rscript src/r/plot_pca.r -c ${COUNT_CSV} -d ${DESIGN} -o csv/pca.pdf

# Generate the heatmap
heatmap: ${DESIGN}
	Rscript src/r/plot_heatmap.r -c ${DE_CSV} -d ${DESIGN} -o csv/heatmap.pdf
	
# Show the design file
design: ${DESIGN}
	@ls -lh ${DESIGN}

# Generate the design file.
${DESIGN}:
	@cat << EOF > ${DESIGN}
	sample,group
	HBR_1,HBR
	HBR_2,HBR
	HBR_3,HBR
	UHR_1,UHR
	UHR_2,UHR
	UHR_3,UHR
	EOF

# Additional Makefile settings
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-print-directory
