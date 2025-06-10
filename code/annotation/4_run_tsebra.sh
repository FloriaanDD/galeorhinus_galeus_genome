#!/bin/bash
#SBATCH --job-name=4_tsebra
#SBATCH --time=0-02:0:0
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
module load tsebra/1.1.2.5
module load braker/3.0.7
module load augustus/3.4.0
module load galba
module load miniprot/0.11
module load miniprot_boundary_scorer/1.0.0
module load miniprothint/230915
module load genomethreader/1.7.4
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
SPECIES_NAME="OG706_curated"

# Input directories
BRAKER_DIR="${RESULTS_DIR}/braker_ETP"
GALBA_DIR="${RESULTS_DIR}/galba"
TSEBRA_DIR="${RESULTS_DIR}/tsebra"
BUSCO_DATASET_DIR="${PROJECT_DIR}/busco_datasets"
BRAKER_CONTAINER="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/containers/braker3_lr.sif"


# Input files
MASKED_GENOME="${RESULTS_DIR}/RepeatMasker/${SPECIES_NAME}.masked.fa"
AUG_GTF="${BRAKER_DIR}/workdir/Augustus/augustus.hints.gtf"
GM_GTF="${BRAKER_DIR}/workdir/GeneMark-ET/genemark.gtf"
BRAKER_GTF="${BRAKER_DIR}/workdir/braker.gtf"
GALBA_GTF="${GALBA_DIR}/workdir/galba.gtf"
BRAKER_HINTS="${BRAKER_DIR}/workdir/hintsfile.gff"
GALBA_HINTS="${GALBA_DIR}/workdir/hintsfile.gff"

# Output files
RUN_ID="01-default"
TSEBRA_OUT_DIR="${TSEBRA_DIR}/${RUN_ID}"
MERGED_GTF="${TSEBRA_OUT_DIR}/braker_galba.gtf"
LOG_FILE="${TSEBRA_OUT_DIR}/errors/tsebra.stderr"

# Create directories
echo "Creating output directories..."
for dir in "${TSEBRA_DIR}" "${TSEBRA_OUT_DIR}" "${TSEBRA_OUT_DIR}/errors"; do
    mkdir -p "$dir"
done

# Tsebra combined output
COMBINED_OUT_DIR="${TSEBRA_OUT_DIR}/braker_galba"
mkdir -p "${COMBINED_OUT_DIR}"

echo "Starting TSEBRA merge at $(date)"

# Run TSEBRA
apptainer exec --bind ${PROJECT_DIR}:${PROJECT_DIR} \
    ${BRAKER_CONTAINER} /opt/TSEBRA/bin/tsebra.py \
    --gtf ${BRAKER_GTF},${GALBA_GTF},${AUG_GTF},${GM_GTF} \
    --hintfiles ${GALBA_HINTS},${BRAKER_HINTS} \
    --filter_single_exon_genes \
    --ignore_tx_phase \
    --out ${MERGED_GTF} \
    --verbose 1 2> ${LOG_FILE}

# Check TSEBRA output
if [ ! -f "${MERGED_GTF}" ]; then
    echo "Error: TSEBRA failed to create output file: ${MERGED_GTF}" >&2
    if [ -f "${LOG_FILE}" ]; then
        echo "TSEBRA error log:"
        cat "${LOG_FILE}"
    fi
    exit 1
fi

echo "TSEBRA merge completed successfully at $(date)"

# Generate protein and coding sequences
echo "Generating protein and coding sequences..."
apptainer exec --bind ${PROJECT_DIR}:${PROJECT_DIR} \
    ${BRAKER_CONTAINER} /opt/conda/bin/python3 \
    /opt/Augustus/scripts/getAnnoFastaFromJoingenes.py \
    -g ${MASKED_GENOME} \
    -f ${MERGED_GTF} \
    -o ${COMBINED_OUT_DIR}



rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/



if [ $? -ne 0 ]; then
    echo "Sequence generation failed at $(date)" >&2
    exit 1
fi

echo "Pipeline completed successfully at $(date)"
echo "Results can be found in: ${TSEBRA_OUT_DIR}"

duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
