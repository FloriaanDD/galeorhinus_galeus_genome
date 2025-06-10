#!/bin/bash
#SBATCH --job-name=3_galba
#SBATCH --time=6-02:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=5GB


echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/


module load apptainer
module load galba
module load miniprot/0.11
module load miniprot_boundary_scorer/1.0.0
module load miniprothint/230915
module load genomethreader/1.7.4
module load tsebra/1.1.2.5
module load diamond/2.0.15
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
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"

# Species name and specific directories
SPECIES_NAME="OG706_curated"
GALBA_DIR="${RESULTS_DIR}/galba"



# Input files
# MASKED_GENOME="${RESULTS_DIR}/TRF/${SPECIES_NAME}_trf.masked"
MASKED_GENOME="${RESULTS_DIR}/RepeatMasker/${SPECIES_NAME}.masked.fa"
PROTEIN_FILE="${RESULTS_DIR}/Vertebrata.fa"

# Create output directory
mkdir -p "${GALBA_DIR}"

# Create working directory for GALBA
GALBA_WORKDIR="${GALBA_DIR}/workdir"
mkdir -p "${GALBA_WORKDIR}"

# Container path (adjust as needed)
GALBA_CONTAINER="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/containers/galba.sif"

CDBTOOLS_PATH=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/cdbfasta
DIAMOND_PATH=/apps/diamond/2.0.15/bin
MINIPROT_PATH=/apps/miniprot/0.11/bin
SCORER_PATH=/apps/miniprot_boundary_scorer/1.0.0/bin
MINIPROTHINT_PATH=/apps/miniprothint/230915
GENOMETHREADER_PATH=/apps/genomethreader/1.7.4/bin
AUGUSTUS_PATH=/scratch3/dev093/2.School_shark/SS_annotation/Augustus/3.4.0
export AUGUSTUS_BIN_PATH=$AUGUSTUS_PATH/bin
export AUGUSTUS_SCRIPTS_PATH=$AUGUSTUS_PATH/scripts
export AUGUSTUS_CONFIG_PATH=$AUGUSTUS_PATH/config
export GENEMARK_PATH=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/GeneMark-ETP
export TMPDIR=/scratch3/dev093/2.School_shark/SS_annotation/tmp
export PYTHON3_PATH=/apps/python/3.9.4/bin
export COMPLEASM_PATH=/apps/compleasm/0.2.2/bin
export TSEBRA_PATH=/apps/braker/3.0.7/TSEBRA/bin


# Run GALBA with protein evidence
echo "Starting GALBA analysis at $(date)"
chmod +x ${AUGUSTUS_BIN_PATH}/augustus
rm -r /scratch3/dev093/2.School_shark/SS_annotation/Augustus/3.4.0/config/species/OG706_curated_galba

galba.pl \
    --genome="${MASKED_GENOME}" \
    --prot_seq="${PROTEIN_FILE}" \
    --species="${SPECIES_NAME}_galba" \
    --workingdir="${GALBA_WORKDIR}" \
    --threads="${SLURM_CPUS_PER_TASK}" \
    --CDBTOOLS_PATH=$CDBTOOLS_PATH \
    --TSEBRA_PATH=$TSEBRA_PATH \
    --DIAMOND_PATH=$DIAMOND_PATH \
    --MINIPROT_PATH=$MINIPROT_PATH \
    --SCORER_PATH=$SCORER_PATH \
    --MINIPROTHINT_PATH=$MINIPROTHINT_PATH \
    --GENOMETHREADER_PATH=$GENOMETHREADER_PATH \
    --AUGUSTUS_CONFIG_PATH=$AUGUSTUS_CONFIG_PATH \
    --AUGUSTUS_BIN_PATH=$AUGUSTUS_BIN_PATH \
    --AUGUSTUS_SCRIPTS_PATH=$AUGUSTUS_SCRIPTS_PATH \
    --AUGUSTUS_ab_initio

rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/


# Check if GALBA completed successfully
if [ $? -eq 0 ]; then
    echo "GALBA analysis completed successfully at $(date)"
else
    echo "GALBA analysis failed at $(date)" >&2
    exit 1
fi


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."

