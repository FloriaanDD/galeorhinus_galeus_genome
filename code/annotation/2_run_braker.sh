#!/bin/bash
#SBATCH --job-name=2_braker
#SBATCH --time=6-00:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem-per-cpu=5GB


echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/


module load apptainer
module load braker/3.0.7
module load augustus/3.4.0
module load diamond/2.0.15
module load miniprot/0.11
module load miniprot_boundary_scorer/1.0.0
module load miniprothint/230915
module load genomethreader/1.7.4
module load bedtools/2.31.1
module load gffread/0.12.7
module load perl/5.32.1
module load bamtools
module load samtools
module load blast+/2.15.0
module load compleasm/0.2.2
module load stringtie
module load sratoolkit

# Project directories
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation"
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation"
DATA_DIR="${PROJECT_DIR}/data"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
SCRIPTS_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts"

# Species name and specific directories
SPECIES_NAME="OG706_curated"
BRAKER_DIR="${RESULTS_DIR}/braker_ETP"

# Input files
# MASKED_GENOME="${RESULTS_DIR}/RepeatMasker/${SPECIES_NAME}.fa.masked"
PROTEIN_FILE="${RESULTS_DIR}/Vertebrata.fa"
ISOSEQ=${RESULTS_DIR}/School_shark_pool2_HiFi_lima_refine_cluster_mapped_masked.bam

# Create output directory
mkdir -p "${BRAKER_DIR}"

# Create working directory for BRAKER
BRAKER_WORKDIR="${BRAKER_DIR}/workdir"
rm -r ${BRAKER_WORKDIR}
mkdir -p "${BRAKER_WORKDIR}"

# Container path 
BRAKER_CONTAINER="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/containers/braker3_lr.sif"

GENEMARK=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/GeneMark-ETP/bin
GM_KEY=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/gm_key_64
PROTHINT_PATH=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/ProtHint/bin
CDBTOOLS_PATH=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/cdbfasta
DIAMOND_PATH=/apps/diamond/2.0.15/bin


#### SETUP AUGUSTUS
# cp -r /apps/augustus/3.4.0/ /scratch3/dev093/2.School_shark/SS_annotation/Augustus/

AUGUSTUS_PATH=/scratch3/dev093/2.School_shark/SS_annotation/Augustus/3.4.0
export AUGUSTUS_BIN_PATH=$AUGUSTUS_PATH/bin
export AUGUSTUS_SCRIPTS_PATH=$AUGUSTUS_PATH/scripts
export AUGUSTUS_CONFIG_PATH=$AUGUSTUS_PATH/config
export GENEMARK_PATH=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/GeneMark-ETP
export TMPDIR=/scratch3/dev093/2.School_shark/SS_annotation/tmp
export PYTHON3_PATH=/apps/python/3.9.4/bin
export COMPLEASM_PATH=/apps/compleasm/0.2.2/bin
export TSEBRA_PATH=/apps/braker/3.0.7/TSEBRA/bin


# Run BRAKER with protein evidence
echo "Starting BRAKER analysis at $(date)"
braker.pl --genome ${MASKED_GENOME} \
     --bam ${ISOSEQ} \
     --prot_seq "${PROTEIN_FILE}" \
     --threads "${SLURM_CPUS_PER_TASK}" \
     --species="${SPECIES_NAME}" \
     --workingdir="${BRAKER_WORKDIR}" \
     --GENEMARK_PATH=$GENEMARK \
     --PROTHINT_PATH=$PROTHINT_PATH \
     --CDBTOOLS_PATH=$CDBTOOLS_PATH \
     --TSEBRA_PATH=$TSEBRA_PATH \
     --DIAMOND_PATH=$DIAMOND_PATH \
     --AUGUSTUS_CONFIG_PATH=$AUGUSTUS_CONFIG_PATH \
     --AUGUSTUS_BIN_PATH=$AUGUSTUS_BIN_PATH \
     --AUGUSTUS_SCRIPTS_PATH=$AUGUSTUS_SCRIPTS_PATH \
     --useexisting

rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/


rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/

# Check if BRAKER completed successfully
if [ $? -eq 0 ]; then
    echo "BRAKER analysis completed successfully at $(date)"
    
else
    echo "BRAKER analysis failed at $(date)" >&2
    exit 1
fi

echo "Pipeline completed at $(date)"


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
