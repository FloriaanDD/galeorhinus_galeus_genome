#!/bin/bash
#SBATCH --job-name=8_busco
#SBATCH --time=24:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10GB
#SBATCH --partition=io

echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/

module load busco/5.4.7

# Project directories
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation"
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
EGAPX_PY=${WORK_DIR}/egapx/ui/egapx.py

# Output files
EGAPX_DIR="${RESULTS_DIR}/egapx_results"
PREFIX=school_shark
PROT_FILE=${EGAPX_DIR}/${PREFIX}_out/complete.proteins.faa
BUSCO_REPORT=sGalGal3_Busco_annot_report_vert
THREADS=${SLURM_CPUS_PER_TASK}

echo -e "\n\n>>>> Run busco <<<<<<\n\n"

cd $EGAPX_DIR
busco -i ${PROT_FILE} -m proteins -l vertebrata_odb10 --cpu $THREADS -o $BUSCO_REPORT

echo -e "\n\n>>>> Sync results <<<<<<\n\n"
rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/

duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
