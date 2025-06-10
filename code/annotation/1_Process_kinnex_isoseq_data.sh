#!/bin/bash
#SBATCH --job-name=1_isoseq_process
#SBATCH --time=24:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=5GB


echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/

module load samtools
module load miniconda3


# Variables
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation"
PROJECT_DIR="/scratch3/dev093/2.School_shark/SS_annotation/"
DATA_DIR="${PROJECT_DIR}/data"
RESULTS_DIR="${PROJECT_DIR}/Annotation_results"
SCRIPTS_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Annotation_Test/scripts/"

# Specify the species name prefix
SPECIES_NAME="OG706_curated"


source activate /datasets/work/ncmi-toa-rrbs/work/2.School_shark/ISOSEQ
# conda create --prefix /datasets/work/ncmi-toa-rrbs/work/2.School_shark/ISOSEQ
# conda install -c bioconda pbmm2 isoseq lima pbpigeon pbskera pbtk
# conda update --all
# conda deactivate

HIFI_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi.bam
PRIMERS=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/Annotation/Kinnex_IsoSeq_BC/IsoSeq_v2_primers_12.fasta
LIMA_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi_lima.bam
REFINE_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi_lima_refine.bam
CLUSTER_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi_lima_refine_cluster.bam
# MAPPED_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi_lima_refine_cluster_mapped.bam
MAPPED_BAM=${RESULTS_DIR}/School_shark_pool2_HiFi_lima_refine_cluster_mapped_masked.bam

COLLAPSE_GFF=${RESULTS_DIR}/School_shark_pool2.gff
COLLAPSE_SORT_GFF=${RESULTS_DIR}/School_shark_pool2.sorted.gff
FLNC_COUNT=${RESULTS_DIR}/School_shark_pool2.flnc_count.txt
ANNOTATION_GTF=${RESULTS_DIR}/School_shark.gtf

MASKED_GENOME="${RESULTS_DIR}/TRF/${SPECIES_NAME}_trf.masked"
MASKED_GENOME2="${RESULTS_DIR}/RepeatMasker/${SPECIES_NAME}.masked.fa"
cp ${MASKED_GENOME} ${MASKED_GENOME2}



cd ${RESULTS_DIR}

echo -e ">>>>>>>>>>>>>>>>>>>>ANNOTATION - CLUSTER<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
## Skera # DATA ALREADY SEGMENTED
# skera split $HIFI_BAM $PRIMERS segmented.bam

## lima	Remove cDNA primers	fl.bam
echo -e ">>LIMA<<"
lima --isoseq --peek-guess $HIFI_BAM $PRIMERS $LIMA_BAM
mv ${OUTPUT}/School_shark_pool2_HiFi_lima.IsoSeqX_bc01_5p--IsoSeqX_3p.bam ${LIMA_BAM}
mv ${OUTPUT}/School_shark_pool2_HiFi_lima.IsoSeqX_bc01_5p--IsoSeqX_3p.bam.pbi ${LIMA_BAM}.pbi
pbindex $LIMA_BAM

echo -e ">>isoseq refine<<"
# isoseq refine	Remove polyA tail and artificial concatemers	flnc.bam
isoseq refine --log-level INFO --require-polya $LIMA_BAM $PRIMERS $REFINE_BAM
pbindex $REFINE_BAM

echo -e ">>isoseq cluster2<<"
## isoseq cluster2	De novo isoform-level clustering scalable to large number of reads (e.g. 40-100M FLNC reads)	clustered.bam
isoseq cluster2 $REFINE_BAM $CLUSTER_BAM --use-qvs
pbindex $CLUSTER_BAM


echo -e ">>pbmm2 align<<"
pbmm2 index ${MASKED_GENOME2} ${MASKED_GENOME2}.mmi
pbmm2 align --preset ISOSEQ --sort -j ${SLURM_CPUS_PER_TASK} --log-level INFO $CLUSTER_BAM ${MASKED_GENOME2} $MAPPED_BAM
samtools index $MAPPED_BAM


rsync -r --update ${RESULTS_DIR} ${WORK_DIR}/


conda deactivate

duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
