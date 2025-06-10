#!/bin/sh
#SBATCH --job-name=1_cactus
#SBATCH --time=0-24:00:00
#SBATCH --nodes=1
#SBATCH --mem=500GB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --account=OD-220670
#SBATCH --mail-user=dev093@csiro.au
#SBATCH --mail-type=END,FAIL
#SBATCH --error=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/pangenome/log/4_cactus_%A_%a.err
#SBATCH --out=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/pangenome/log/4_cactus_%A_%a.out
##SBATCH --partition=io

echo $PATH
start=$(date)
echo $start
SECONDS=0

cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/


module load singularity
module load miniconda3/23.3.1
module load ucsctools
module load samtools


# Set temporary directory with more available space
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark"
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

export TMPDIR=/scratch3/dev093/2.School_shark/pangenome/TMP
mkdir -p $TMPDIR

####Pull the Cactus container if not already pulled
# singularity pull docker://quay.io/comparative-genomics-toolkit/cactus:latest
# singularity build docker://quay.io/comparative-genomics-toolkit/cactus:latest
# ulimit -u 10000 # https://stackoverflow.com/questions/52026652/openblas-blas-thread-init-pthread-create-resource-temporarily-unavailable/54746150#54746150


export SINGULARITY_CACHEDIR=${WORK_DIR}/.singularity/cache
export SINGULARITY_TMPDIR=${WORK_DIR}/.singularity/temp
echo $PATH



PREFIX=School_shark_pan_trikidae
seqFiles=/datasets/work/ncmi-toa-rrbs/work/2.School_shark/pangenome/seqFile_mustelus.txt
REF="OG706"
jobStorePath="/scratch3/dev093/2.School_shark/pangenome/Cactus/js_trikidae"

OUT_DIR=/scratch3/dev093/2.School_shark/pangenome/Cactus/${PREFIX}
mkdir -p ${OUT_DIR}

tmp="/scratch3/dev093/2.School_shark/pangenome/tmp_cactus"


CACTUS_SIF=/datasets/work/ncmi-toa-rrbs/work/13.Eels/genome_comparison/Cactus/cactus_latest.sif
mkdir -p /scratch3/dev093/2.School_shark/pangenome/Cactus
# Run Cactus hal2maf with a bounded temporary directory
rm -r ${jobStorePath} ###JobStoreExistsException
mkdir -p ${tmp}


echo -e "\n\n>>>>>> cactus-pangenome <<<<<<<<\n\n"
### TAKES 1 days on 64 cores with 145 Gb RAM for 3 genomes 
singularity exec -H ${WORK_DIR}/.singularity/ \
  --bind $TMPDIR:/tmp \
  ${CACTUS_SIF} \
  cactus-pangenome \
  ${jobStorePath} \
  ${seqFiles} \
  --outDir ${OUT_DIR} \
  --outName ${PREFIX} \
   --reference ${REF} \
  --logFile ${WORK_DIR}/cactus.log \
  --maxMemory 110G --mgMemory 100G --consMemory 100G --indexMemory 100G \
  --maxCores 64 --mgCores 64 --mapCores 16 --consCores 64 --indexCores 64 \
  --giraffe filter --viz --odgi --chrom-vg clip filter \
  --chrom-og --gbz clip filter full \
  --gfa clip full --vcf --filter 2
#   
rsync --update ${OUT_DIR} ${WORK_DIR}/pangenome/cactus/



### Synteny
### TAKES 30min & 134G RAM on 64 cores
REF="OG706"
QUERIES=(
  "Mustelus_asterias"
  "OG906")

REF="REF_OG706"
echo -e "Synteny"
for TARGET in "${QUERIES[@]}"; do
  echo "[$(date)] Starting: $TARGET vs $REF"
  singularity exec -H ${WORK_DIR}/.singularity/ \
    --bind $TMPDIR:/tmp \
    ${CACTUS_SIF} \
    halSynteny \
      --queryGenome $TARGET \
      --targetGenome $REF \
      ${OUT_DIR}/${PREFIX}.full.hal \
      ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}.psl

      pslToBed ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}.psl ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}.bed
      awk 'BEGIN{OFS="\t"} {print $1, $2, $3, $4, $7, $8}' ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}.bed > ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}_links.txt
    echo "[$(date)] Finished: $TARGET vs $REF" &
done


### Karyotype
DIR1=/scratch3/dev093/2.School_shark/pangenome/NCBI_genomes/raw_fa
REF="Carcharhiniformes_Triakidae_Galeorhinus_galeus_OG706"
QUERIES=(
  "Carcharhiniformes_Triakidae_Mustelus_asterias_GCA_964213995"
  "Carcharhiniformes_Triakidae_Galeorhinus_galeus_OG906"
)

######Index the genome FASTA files
samtools faidx ${DIR1}/${REF}.fa
awk -v species="${REF}" 'BEGIN{OFS="\t"} {print "chr", "-", species NR, $1, 0, $2, "blue"}' \
${DIR1}/${REF}.fa.fai > ${OUT_DIR}/${REF}.karyotype.txt


for TARGET in "${QUERIES[@]}"; do
  echo "[$(date)] Starting: $TARGET"
  samtools faidx ${DIR1}/${TARGET}.fa
  awk -v species="${TARGET}" 'BEGIN{OFS="\t"} {print "chr", "-", species NR, $1, 0, $2, "red"}' \
  ${DIR1}/${TARGET}.fa.fai > ${OUT_DIR}/${TARGET}.karyotype.txt
  cat ${OUT_DIR}/${REF}.karyotype.txt ${OUT_DIR}/${TARGET}.karyotype.txt > ${OUT_DIR}/${PREFIX}.${TARGET}_vs_${REF}_karyotype.txt
  echo "[$(date)] Finished: $TARGET" &
done


rsync -r --update ${OUT_DIR} ${WORK_DIR}/pangenome/cactus/


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
