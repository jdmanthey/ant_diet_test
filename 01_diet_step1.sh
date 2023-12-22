#!/bin/bash
#SBATCH --chdir=./
#SBATCH --job-name=diet1
#SBATCH --partition quanah
#SBATCH --nodes=1 --ntasks=18
#SBATCH --time=48:00:00
#SBATCH --mem=90G
#SBATCH --array=1-31

# define main working directory
workdir=/lustre/scratch/jmanthey/01_ant_diet_test

# define the location of the reference host genome
refgenome=/home/jmanthey/denovo_genomes/camp_sp_genome_filtered.fasta

# define the location of the reference blochmannia
bloch=/home/jmanthey/blochmannia/C145_quercicola.fasta

# define the location of the reference mitogenomes
mito=/home/jmanthey/denovo_genomes/formicinae_mitogenomes.fasta

# base name of files for step 1
basename_array=$( head -n${SLURM_ARRAY_TASK_ID} ${workdir}/basenames1.txt | tail -n1 )

# run bbduk to clean / filter reads
/lustre/work/jmanthey/bbmap/bbduk.sh in1=${workdir}/00_fastq/${basename_array}_R1.fastq.gz in2=${workdir}/00_fastq/${basename_array}_R2.fastq.gz out1=${workdir}/01_cleaned/${basename_array}_R1.fastq.gz out2=${workdir}/01_cleaned/${basename_array}_R2.fastq.gz minlen=50 ftl=10 qtrim=rl trimq=10 ktrim=r k=25 mink=7 ref=/lustre/work/jmanthey/bbmap/resources/adapters.fa hdist=1 tbo tpe -Xmx80g

# change to directory that has blochmannia indexed
cd ${workdir}/10_scripts/bloch_ref

# run bbsplit for blochmannia
/lustre/work/jmanthey/bbmap/bbsplit.sh in=${workdir}/01_cleaned/${basename_array}_R1.fastq.gz ref=${bloch} basename=${workdir}/02_subset1/${basename_array}_%.fastq.gz outu=${workdir}/02_subset1/${basename_array}.fastq.gz -Xmx80g

# change to directory that has ant indexed
cd ${workdir}/10_scripts/ant_ref

# run bbsplit for reference
/lustre/work/jmanthey/bbmap/bbsplit.sh in=${workdir}/02_subset1/${basename_array}.fastq.gz ref=${refgenome} basename=${workdir}/03_subset2/${basename_array}_%.fastq.gz outu=${workdir}/03_subset2/${basename_array}.fastq.gz -Xmx80g

# change to directory that has mito indexed
cd ${workdir}/10_scripts/mito_ref

# run bbsplit for mtDNA
/lustre/work/jmanthey/bbmap/bbsplit.sh in=${workdir}/03_subset2/${basename_array}.fastq.gz ref=${mito} basename=${workdir}/04_subset3/${basename_array}_%.fastq.gz outu=${workdir}/04_subset3/${basename_array}.fastq.gz -Xmx80g

# change back to scripts directory
cd ${workdir}/10_scripts/

# unzip 
gunzip ${workdir}/04_subset3/${basename_array}.fastq.gz

# convert leftover reads to fasta
sed -n '1~4s/^@/>/p;2~4p' ${workdir}/04_subset3/${basename_array}.fastq > ${workdir}/05_fasta/${basename_array}.fasta

