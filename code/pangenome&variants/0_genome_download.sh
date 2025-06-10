#!/bin/bash
#SBATCH --job-name=0_genome_dwnld
#SBATCH --time=2:0:0
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=1GB
#SBATCH --ntasks-per-node=1
#SBATCH --partition=io
#SBATCH --array=1-47

module load miniconda3

cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/

WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/pangenome"
GENOME_DIR="${WORK_DIR}/NCBI_genomes"
GENOME_TABLE="${WORK_DIR}/chondrichthyes_edit2.tsv"
WGET=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $7}' $GENOME_TABLE)
ORDER=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $6}' $GENOME_TABLE)
FAMILY=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $5}' $GENOME_TABLE)
SPECIES=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $4}' $GENOME_TABLE)
ASSEMBLY=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $GENOME_TABLE)
ACCESSION=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $GENOME_TABLE)
ACCESSION2=$(echo "$ACCESSION" | sed "s/\..*//")


mkdir -p ${GENOME_DIR}
cd ${GENOME_DIR}
# conda create --prefix /datasets/work/ncmi-toa-rrbs/work/6.Shark_genomes/ncbi_datasets
source activate /datasets/work/ncmi-toa-rrbs/work/6.Shark_genomes/ncbi_datasets
# conda install -c conda-forge ncbi-datasets-cli

datasets download genome accession ${ACCESSION} --no-progressbar --include genome,rna,protein,cds,gff3,gtf,seq-report --filename ${SPECIES}_${ASSEMBLY}.zip
unzip ${SPECIES}_${ASSEMBLY}.zip -d ${SPECIES}_${ASSEMBLY}
datasets rehydrate --directory ${SPECIES}_${ASSEMBLY}/

mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/${ACCESSION}_${ASSEMBLY}.fasta ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}.fasta
mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/${ACCESSION}_${ASSEMBLY}_genomic.fna ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}.fasta
mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/${ACCESSION}_${ASSEMBLY}.gff ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}.gff
mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/genomic.gff ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}.gff
mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/${ACCESSION}_${ASSEMBLY}_protein.faa ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}_protein.faa
mv ${GENOME_DIR}/${SPECIES}_${ASSEMBLY}/ncbi_dataset/data/${ACCESSION}/protein.faa ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}_protein.faa

mv ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}.gff ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}.gff
mv ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_protein.faa ${GENOME_DIR}/${ORDER}_${FAMILY}_${SPECIES}_${ACCESSION2}_protein.faa

conda deactivate

