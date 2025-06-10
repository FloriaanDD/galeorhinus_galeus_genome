#!/bin/bash
#SBATCH --job-name=0_repeat_masking
#SBATCH --time=2-00:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=7GB

echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts

# Variables
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation"
DATA_DIR="${PROJECT_DIR}/data"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
SCRIPTS_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts"

SPECIES_NAME="OG706_curated"

# Create species-specific results directory
DATABASE_DIR="${RESULTS_DIR}/RMdatabase"
REPEATMODELER_DIR="${RESULTS_DIR}/RepeatModeler"
REPEATMASKER_DIR="${RESULTS_DIR}/RepeatMasker"
mkdir -p "${DATABASE_DIR}"
mkdir -p "${REPEATMODELER_DIR}"
mkdir -p "${REPEATMASKER_DIR}"


# Load necessary modules
module load singularity
module load repeatmasker #4.1
module load repeatmodeler #2.0.2
module load repeatscout/1.0.6
module load trf/4.09.1
module load recon/1.08
module load perl/5.32.1
module load rmblast/2.11.0
module load ltr_retriever/2.9.0
module load genometools/1.6.2
module load cd-hit/4.8.1 
module load ninja/1.11.1
module load parallel
module load bedtools
module load ucsctools


# Run specific variables
THREADS="${SLURM_CPUS_PER_TASK}"
GENOME_NAME="${SPECIES_NAME}"
GENOME="${DATA_DIR}/${GENOME_NAME}.fa"
DB="${DATA_DIR}/${SPECIES_NAME}_db"

# TETools image
DFAM_TETOOLS="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/containers/dfam-tetools-latest.sif"

# Get the path
TRF_PATH=$(which trf)
MAFFT_PATH=/apps/mafft/7.526/bin/





cd ${DATA_DIR}
RepeatMasker -pa ${SLURM_CPUS_PER_TASK} -noint -dir ${DATA_DIR} ${GENOME_FILE}

# rm -r ${DB}*

###Step1: Build Repeats Database
BuildDatabase -name ${DB} ${DATA_DIR}/${GENOME}.masked
if [ $? -ne 0 ]; then
    echo "Database building failed." >&2
    exit 1
fi

# Move all database files to the results directory
mv ${DB}* ${DATABASE_DIR}/


####Step 2: RepeatModeler 
### only takes 10G RAM, but requires 14h
### do not run -LTRStruct if you have large genomes with low complex regions

RECOV_DIR=${REPEATMODELER_DIR}/RM_65036.TueApr151318352025/
mkdir -p ${RECOV_DIR}

cd ${REPEATMODELER_DIR}
RepeatModeler -database ${DATABASE_DIR}/${SPECIES_NAME}_db \
      -pa ${THREADS} \
      -mafft_dir ${MAFFT_PATH}
 
###Move RepeatModeler outputs (RM_* files) to the RepeatModeler directory ## should read be there
mv ${DATABASE_DIR}/RM_* ${REPEATMODELER_DIR}/

# Step 3: RepeatMasker

# cd ${REPEATMASKER_DIR}
RepeatMasker $GENOME_FILE -lib ${DATABASE_DIR}/${SPECIES_NAME}_db-families.fa \
      -engine rmblast -gff \
      -pa $THREADS -a -noisy -xsmall ${GENOME} -dir ${REPEATMASKER_DIR}


# Step 4: TRF
# Create directory structure
TRF_DIR="${RESULTS_DIR}/TRF"
SPLIT_DIR="${TRF_DIR}/01_split"
TRF_OUT_DIR="${TRF_DIR}/02_trf_output"
PARSED_DIR="${TRF_DIR}/03_parsed_output"
SORTED_DIR="${TRF_DIR}/04_sorted"
MERGED_DIR="${TRF_DIR}/05_merged"
MASKED_DIR="${TRF_DIR}/06_masked"


chmod +x /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/splitMfasta.pl
chmod +x /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/parseTrfOutput.py

# Create all directories
for dir in "$SPLIT_DIR" "$TRF_OUT_DIR" "$PARSED_DIR" "$SORTED_DIR" "$MERGED_DIR" "$MASKED_DIR"; do
    mkdir -p "$dir"
done

# Step 4.1: Split the genome
echo -e "\n\n>>>>>>>Split the genome<<<<<<<<\n\n"
cd "$SPLIT_DIR"
${SCRIPTS_DIR}/splitMfasta.pl --minsize=25000000 "${REPEATMASKER_DIR}/${GENOME_NAME}.fa.masked"


# Step 4.2: Run TRF
### ADJUST THIS TO RUN AS ARRAY!
echo -e "\n\n>>>>>>>Run TRF<<<<<<<<\n\n"
cd "$TRF_OUT_DIR"
for fa in "${SPLIT_DIR}"/${GENOME_NAME}.fa.masked.split.*.fa; do
    trf "$fa" 2 7 7 80 10 50 500 -d -m -h
done

# Step 4.3: Parse TRF output
echo -e "\n\n>>>>>>>Parse TRF output<<<<<<<<\n\n"
cd "$PARSED_DIR"
for dat in "${TRF_OUT_DIR}"/*.dat; do
    base=$(basename "$dat")
    ${SCRIPTS_DIR}/parseTrfOutput.py "$dat" --minCopies 1 \
        --statistics "${base}.STATS" > "${base}.raw.gff" 2> "${base}.parsedLog"
done

# Step 4.4: Sort parsed output
echo -e "\n\n>>>>>>>Sort parsed output<<<<<<<<\n\n"
cd "$SORTED_DIR"
for gff in "${PARSED_DIR}"/*.raw.gff; do
    base=$(basename "$gff")
    sort -k1,1 -k4,4n -k5,5n "$gff" > "${base}.sorted" 2> "${base}.sortLog"
done

# Step 4.5: Merge gff files
echo -e "\n\n>>>>>>>Merge gff files<<<<<<<<\n\n"
cd "$MERGED_DIR"
for sorted in "${SORTED_DIR}"/*.raw.gff.sorted; do
    base=$(basename "$sorted")
    bedtools merge -i "$sorted" | \
    awk 'BEGIN{OFS="\t"} {print $1,"trf","repeat",$2+1,$3,".",".",".","."}' \
    > "${base}.merged.gff" 2> "${base}.bedtools_merge.log"
done

# Step 4.6: Mask FASTA chunks
echo -e "\n\n>>>>>>>Mask FASTA chunks<<<<<<<<\n\n"
cd "$MASKED_DIR"
for fa in "${SPLIT_DIR}"/${GENOME_NAME}.fa.masked.split.*.fa; do
    base=$(basename "$fa")
    merged_gff="${MERGED_DIR}/$(basename "$fa").2.7.7.80.10.50.500.dat.raw.gff.sorted.merged.gff"
    bedtools maskfasta \
        -fi "$fa" \
        -bed "$merged_gff" \
        -fo "${base}.trf.masked" \
        -soft 2> "${base}.bedtools_mask.log"
done

# Step 4.7: Concatenate final output
echo -e "\n\n>>>>>>>Concatenate final output<<<<<<<<\n\n"
cd "$TRF_DIR"
cat "${MASKED_DIR}"/*.trf.masked > "${SPECIES_NAME}_trf.masked"


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
