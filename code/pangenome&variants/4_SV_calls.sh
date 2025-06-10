#!/bin/bash
#SBATCH --job-name=4_SV_call
#SBATCH --time=2-00:0:0
#SBATCH --nodes=1
#SBATCH --mem=500GB
#SBATCH --ntasks-per-node=8


echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/

module load miniconda3
module load samtools


###FULL RUN USES APPROX 400GB RAM, and takes 3 days, but deepvariant takes an additional 5 days
PREFIX=OG706
IN_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}_all5mC.bam
REF_PATH=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.fa
REF_MMI=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.mmi
SAM_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}.sam
BAM_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}.bam
BAM_SORT=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}_sorted.bam
VCF_SV=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/VCF/PBSV/${PREFIX}_align_SV.vcf
SVSIG_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/VCF/PBSV/${PREFIX}_align.svsig.gz

# PREFIX=SS_278
# IN_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}_all5mC.bam
# REF_PATH=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.fa
# REF_MMI=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.mmi
# SAM_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}.sam
# BAM_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}.bam
# BAM_SORT=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/Alignment/${PREFIX}_sorted.bam
# VCF_SV=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/VCF/PBSV/${PREFIX}_align_SV.vcf
# SVSIG_PATH=/scratch3/dev093/2.School_shark/PACBIO/${PREFIX}/VCF/PBSV/${PREFIX}_align.svsig.gz


echo ">>Set DIR<<"
OUT_PATH=/scratch3/dev093/2.School_shark/PACBIO
cd $OUT_PATH
mkdir ${PREFIX}
cd ${OUT_PATH}/${PREFIX}


###################################################################################
echo ">>Align CSS<<"
### TAKES 2 days on 8 cores with 960GB RAM (MAX 400GB)
mkdir ${OUT_PATH}/${PREFIX}/Alignment
cd ${OUT_PATH}/${PREFIX}/Alignment
source activate /datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/pacbio

pbmm2 index ${REF_PATH} ${REF_MMI} --preset CCS -j 16 --log-level INFO
pbmm2 align --preset CCS --sort -j 14 -J 2 --log-level INFO ${REF_MMI} ${IN_PATH} ${BAM_SORT}


###################################################################################
echo ">>>>>Variant calling<<<<<<"
mkdir ${OUT_PATH}/${PREFIX}/VCF
cd ${OUT_PATH}/${PREFIX}/VCF
samtools faidx ${REF_PATH}
samtools index ${BAM_SORT}

echo ">>SV call<<"
source activate /datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/pacbio
mkdir ${OUT_PATH}/${PREFIX}/VCF/PBSV
cd ${OUT_PATH}/${PREFIX}/VCF/PBSV
pbsv discover --ccs ${BAM_SORT} ${SVSIG_PATH}
tabix -c '#' -s 3 -b 4 -e 4 ${SVSIG_PATH}

pbsv call -j 16 --ccs --gt-min-reads 3 --call-min-reads-one-sample 3 ${REF_PATH} ${SVSIG_PATH} ${VCF_SV}


echo ">>Combine SV files<<"
cd ${OUT_PATH}
SVSIG_PATH1=/scratch3/dev093/2.School_shark/PACBIO/OG706/VCF/PBSV/OG706_align.svsig.gz
SVSIG_PATH2=/scratch3/dev093/2.School_shark/PACBIO/SS_278/VCF/PBSV/SS_278_align.svsig.gz
VCF_SV1=/scratch3/dev093/2.School_shark/PACBIO/SS_COMBINED_align_SV.vcf
pbsv call -j 16 --ccs --gt-min-reads 3 --call-min-reads-one-sample 3 ${REF_PATH} ${SVSIG_PATH1} ${SVSIG_PATH2} ${VCF_SV1}



echo ">>Deactivate conda<<"
conda deactivate


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
