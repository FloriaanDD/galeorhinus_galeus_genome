#!/bin/bash
#SBATCH --job-name=7_egapx
#SBATCH --time=7-0:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1GB
#SBATCH --partition=io

echo $PATH
start=$(date)
echo $start
SECONDS=0

## For RNAseq
# Completed at: 29-Jul-2025 21:17:56
# Duration    : 13h 16m 56s
# CPU hours   : 697.8
# Succeeded   : 457

cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/

module load minimap2/2.29
module load miniconda3/23.3.1
module load git/2.50.1
module load python/3.11.0
module load apptainer/1.4.0
module load singularity/3.8.7
module load nextflow/24.04.2 

# cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/
# git clone https://github.com/ncbi/egapx.git
# cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/egapx
# python3 -m venv venv
# source venv/bin/activate
# pip install -r requirements.txt


# Project directories
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation"
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
EGAPX_PY=${WORK_DIR}/egapx/ui/egapx.py

# Output files
EGAPX_DIR="${RESULTS_DIR}/egapx_results"
mkdir -p $EGAPX_DIR
cd $EGAPX_DIR
MINIMAP_PATH=/apps/minimap2/2.29/bin

EGAPX_CONFIG1=${WORK_DIR}/egapx/slurm.config
EGAPX_CONFIG=${EGAPX_DIR}/slurm.config
rsync --update ${EGAPX_CONFIG1} ${EGAPX_CONFIG}

PREFIX=school_shark
EGAPX_YAML=${WORK_DIR}/egapx/school_shark.yaml
TMP_DIR=${EGAPX_DIR}/school_shark_tmp
OUT_DIR=${EGAPX_DIR}/school_shark_out
mkdir -p $TMP_DIR
mkdir -p $OUT_DIR


###Input files - in YAML file
###genome fasta file must have titles: 
# GENOME="/scratch3/dev093/2.School_shark/SS_annotation/data/OG706_curated.fa"
# GENOME2="/scratch3/dev093/2.School_shark/SS_annotation/data/OG706_curated_with_title.fa"
# sed '/^>/ s/$/ Galeorhinus galeus carcharias isolate sGalGal3, whole genome shotgun sequence/' ${GENOME} > ${GENOME2}
# cat ${GENOME2} | head
# TAXID=86063
# ISOSEQ=${RESULTS_DIR}/SRR32361312_1.fasta
# cat $ISOSEQ | head
# >SRR32361312.1.1


###short reads Mustelus: 
###SRA Toolkit to download locally
# module load sratoolkit/3.0.8
# SRA_DIR="${RESULTS_DIR}/sradir/"
# mkdir -p $SRA_DIR
# cd $SRA_DIR
# prefetch ERR13148280
# prefetch DRR400783
# prefetch DRR400782
# prefetch SRR3632060
# fasterq-dump --skip-technical --threads 6 --split-files --seq-defline ">\$ac.\$si.\$ri" --fasta -O ${SRA_DIR} ./ERR13148280
# fasterq-dump --skip-technical --threads 6 --split-files --seq-defline ">\$ac.\$si.\$ri" --fasta -O ${SRA_DIR} ./DRR400783
# fasterq-dump --skip-technical --threads 6 --split-files --seq-defline ">\$ac.\$si.\$ri" --fasta -O ${SRA_DIR} ./DRR400782
# fasterq-dump --skip-technical --threads 6 --split-files --seq-defline ">\$ac.\$si.\$ri" --fasta -O ${SRA_DIR} ./SRR3632060
####changing special symbols to underscores (such as +, (, ), and -)

echo -e "\n\n>>>> Run egapx <<<<<<\n\n"

# python3 ${EGAPX_PY} ${EGAPX_YAML} --output ${OUT_DIR}
python3 ${EGAPX_PY} ${EGAPX_YAML} --config-dir ${EGAPX_CONFIG} --report ${PREFIX} --executor slurm -w ${TMP_DIR} --output ${OUT_DIR}


echo -e "\n\n>>>> Sync results <<<<<<\n\n"

rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
