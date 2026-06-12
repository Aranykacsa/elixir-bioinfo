#
# This makefile compares the various variant calls to the GIAB calls.
#

# The local reference fasta file.
REF = refs/chr22.fa.gz

# The NIST vcf file.
VCF_NIST = nist/HG008_NIST.vcf.gz

# The two vcf files to compare.
VCF_N = vcf/HG008-N.vcf.gz
VCF_T = vcf/HG008-T.vcf.gz

# Compare the two vcf files.
VCF_C = vcf/HG008-comp.vcf.gz

# Better defaults for the Makefile.
SHELL = bash
.ONESHELL:
.SHELLFLAGS = -eu -o pipefail -c
.DELETE_ON_ERROR:

MIN_DP = 20

help:
	@echo "# Use the source, Luke!"

# Perform merging
merge:

	# Create the directory for the bed files.
	mkdir -p results

	# Merge the two vcf files.
	bcftools merge -W -m all ${VCF_T} ${VCF_N} ${VCF_NIST} -o ${VCF_C}

	# The bed file for the NIST vcf file.
	bcftools query -f '%CHROM\t%POS\t%POS\n' ${VCF_NIST} > results/HG008-NIST.bed

	# Get the bed files for the normal sample.
	bcftools query -f '%CHROM\t%POS\t%POS\n' ${VCF_N} > results/HG008-N.bed
	
	# Get the bed files for the tumor sample.
	bcftools view -i 'INFO/DP >= 1' ${VCF_N} | \
		bcftools query -f '%CHROM\t%POS\t%POS\n' > results/HG008-N.bed
	
	bcftools view -i 'INFO/DP >= ${MIN_DP}' ${VCF_T} | \
		bcftools query -f '%CHROM\t%POS\t%POS\n' > results/HG008-T.bed
	
	# Subtract the normal samples from the tumor sample.
	bedtools subtract -a results/HG008-T.bed -b results/HG008-N.bed > results/HG008-mutations.bed

	# True positives.
	bedtools intersect -a results/HG008-mutations.bed -b results/HG008-NIST.bed > results/HG008-true-positives.bed

	# False positives.
	bedtools subtract -a results/HG008-mutations.bed -b results/HG008-NIST.bed > results/HG008-false-positives.bed

	# False negatives.
	bedtools subtract -a results/HG008-NIST.bed -b results/HG008-mutations.bed > results/HG008-false-negatives.bed

	# Print the number of true positives, false positives, and false negatives.
	@echo "Total variants:"
	cat results/HG008-T.bed | wc -l
	@echo "Tumor candidate mutations:"
	cat results/HG008-mutations.bed | wc -l
	@echo "True positives:"
	cat results/HG008-true-positives.bed | wc -l
	@echo "False positives:"
	cat results/HG008-false-positives.bed | wc -l
	@echo "False negatives:"
	cat results/HG008-false-negatives.bed | wc -l


run: merge

# Clean up the data.
clean:
	rm -f ${VCF_CMP} ${VCF_CMP}.* 
	rm -rf vcf/subs vcf/isec bed

.PHONY: help merge clean run 

