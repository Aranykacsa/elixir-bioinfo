# Variables
FASTA_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.fna.gz
GFF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/848/505/GCF_000848505.1_ViralProj14703/GCF_000848505.1_ViralProj14703_genomic.gff.gz

# Targets
GENOME := ebola-mayinga-genome.fasta
ANNOTATION := ebola-mayinga-annotation.gff

.PHONY: all clean

all: $(GENOME) $(ANNOTATION)

$(GENOME): $(GENOME).gz
	gunzip -f $(GENOME).gz

$(ANNOTATION): $(ANNOTATION).gz
	gunzip -f $(ANNOTATION).gz

$(GENOME).gz:
	curl -L $(FASTA_URL) -o $(GENOME).gz

$(ANNOTATION).gz:
	curl -L $(GFF_URL) -o $(ANNOTATION).gz

clean:
	rm -f $(GENOME) $(ANNOTATION) $(GENOME).gz $(ANNOTATION).gz
