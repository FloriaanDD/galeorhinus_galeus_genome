#!/bin/bash
#SBATCH --job-name=5_interproscan
#SBATCH --time=24:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=100GB


echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/


module load interproscan/5.65-97.0
module load agat/1.0.0


# Project directories
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation"
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
SPECIES_NAME="OG706_curated"

# Input directories
BRAKER_DIR="${RESULTS_DIR}/braker"
GALBA_DIR="${RESULTS_DIR}/galba"
TSEBRA_DIR="${RESULTS_DIR}/tsebra"
BUSCO_DATASET_DIR="${PROJECT_DIR}/busco_datasets"

# Input files
MASKED_GENOME="${RESULTS_DIR}/RepeatMasker/OG706_curated.masked.fa"

AUG_GTF="${BRAKER_DIR}/workdir/Augustus/augustus.hints.gtf"
GM_GTF="${BRAKER_DIR}/workdir/GeneMark-ES/genemark.gtf"
BRAKER_GTF="${BRAKER_DIR}/workdir/braker.gtf"
GALBA_GTF="${GALBA_DIR}/workdir/galba.gtf"
BRAKER_HINTS="${BRAKER_DIR}/workdir/hintsfile.gff"
GALBA_HINTS="${GALBA_DIR}/workdir/hintsfile.gff"

RUN_ID="01-default"
TSEBRA_OUT_DIR="${TSEBRA_DIR}/${RUN_ID}"
MERGED_GTF="${TSEBRA_OUT_DIR}/braker_galba.gtf"
MERGED_GFF="${TSEBRA_OUT_DIR}/OG706.gff3"
STATS_OUT="${TSEBRA_OUT_DIR}/agat_gff_stats.txt"
INPUT1="${TSEBRA_OUT_DIR}/braker_galba.aa"
INPUT="${TSEBRA_OUT_DIR}/braker_galba_edit.aa"
sed "s/\*//g" <  $INPUT1 > $INPUT


cd ${RESULTS_DIR}

agat_convert_sp_gxf2gxf.pl -g ${MERGED_GTF} -o ${MERGED_GFF}
agat_sp_statistics.pl --gff ${MERGED_GTF} -o ${STATS_OUT}



# Please strip out all asterix characters from your sequence and resubmit your search
python3 setup.py -f interproscan.properties
interproscan.sh -i ${INPUT} \
    -appl Pfam,FunFam,NCBIfam,SUPERFAMILY \
    --goterms --iprlookup \
    -dp -pa \
    -cpu ${SLURM_CPUS_PER_TASK} \
    --output-dir  ${TSEBRA_OUT_DIR}

INTERPRO="${TSEBRA_OUT_DIR}/braker_galba_edit.aa.tsv"

agat_sp_manage_functional_annotation.pl -f ${MERGED_GFF} \
    --interpro ${INTERPRO} \
    --id GalGal \
    --output ${TSEBRA_OUT_DIR}/sGalGal3_FINAL

  
    
rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
