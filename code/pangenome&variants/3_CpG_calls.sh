#!/bin/bash
#SBATCH --job-name=3_cpg_call
#SBATCH --time=24:0:0
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=10GB
#SBATCH --ntasks-per-node=16


echo $PATH
start=$(date)
echo $start
SECONDS=0

cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/


### Takes 1h on 16 cores with 160GB RAM total

module load miniconda3
source activate /datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/cpg


PREFIX=OG706
REF_PATH=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.fa
BAM_SORT=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}_sorted.bam
PY_PATH=/datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/pb-CpG-tools/aligned_bam_to_cpg_scores.py
MOD_PATH=/datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/pb-CpG-tools/pileup_calling_model
OUTPATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/CpG/

echo ">>Set DIR<<"
mkdir ${OUTPATH}
cd ${OUTPATH}

python $PY_PATH -b ${BAM_SORT} -f ${REF_PATH} -o ${PREFIX}_CpG --pileup_mode "model" -d ${MOD_PATH} --modsites "reference" --min_coverage 4 --threads 16


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
