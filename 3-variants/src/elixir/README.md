

The complete pipeline has the following stages:

1. Get the data for the normal ductal, normal pancreatic, and pancreatic ductal adenocarcinoma.
2. Get the published variants and reference. 
3. Generate variants for all samples.
4. Identify cancer specific variants.

The pipeline can be executed with the following commands:

```
#
# Get the data for the normal ductal tissue.
#
make -f src/elixir/HG008-data.mk \
    BAM_URL=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/PacBio_Onso_20240415/HG008-N-D_Pacbio-onso_48x_GRCh38-GIABv3.bam \
    BAM=nist/HG008-N_NIST.bam \
    R1=reads/HG008-N_R1.fq.gz \
    R2=reads/HG008-N_R2.fq.gz \
    fastq

#
# Get the data for the tumor cell line.
#
make -f src/elixir/HG008-data.mk \
    BAM_URL=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/PacBio_Onso_20240415/HG008-T_Pacbio-onso_136x_GRCh38-GIABv3.bam \
    BAM=nist/HG008-T_NIST.bam \
    R1=reads/HG008-T_R1.fq.gz \
    R2=reads/HG008-T_R2.fq.gz \
    fastq

#
# Get the published variants and reference.
#
make -f src/elixir/HG008-data.mk \
    VCF_URL=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_somatic/HG008/Liss_lab/analysis/Ultima_DeepVariant-somatic-SNV-INDEL_20240822/HG008_edv_AF_recalibration.result.PASS.vcf.gz \
    VCF=nist/HG008_NIST.vcf.gz \
    vcf ref

#
# Align and call variants for the normal ductal tissue.
#
make -f src/elixir/HG008-call.mk \
    R1=reads/HG008-N_R1.fq.gz \
    R2=reads/HG008-N_R2.fq.gz \
    BAM=bam/HG008-N.bam \
    VCF=vcf/HG008-N.vcf.gz \
    run

#
# Align and call variants for the tumor cell line.
#
make -f src/elixir/HG008-call.mk \
    R1=reads/HG008-T_R1.fq.gz \
    R2=reads/HG008-T_R2.fq.gz \
    BAM=bam/HG008-T.bam \
    VCF=vcf/HG008-T.vcf.gz \
    run

#
# Compare the normal ductal and tumor cell line variants.
#
make -f src/elixir/HG008-compare.mk \
    VCF_N=vcf/HG008-N.vcf.gz \
    VCF_T=vcf/HG008-T.vcf.gz \
    run
```

