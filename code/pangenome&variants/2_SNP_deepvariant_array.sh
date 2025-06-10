#!/bin/sh
#SBATCH --job-name=2_deepvariant
#SBATCH --time=0-24:00:00
#SBATCH --nodes=1
#SBATCH --mem=200GB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --array=1-47


CHR="SUPER_$SLURM_ARRAY_TASK_ID"

echo $PATH
start=$(date)
echo $start
SECONDS=0


cd /datasets/work/ncmi-toa-rrbs/work/2.School_shark/


module load singularity
module load miniconda3/23.3.1
module load samtools
module load bcftools
module load htslib

# Set temporary directory with more available space
WORK_DIR="/datasets/work/ncmi-toa-rrbs/work/2.School_shark"
mkdir -p ${WORK_DIR}  
cd ${WORK_DIR}

BIN_VERSION="deepvariant-1.4.0"
singularity pull docker://google/deepvariant:"${BIN_VERSION}"
singularity build deepvariant_pangenome_aware.sif docker://google/deepvariant:"${BIN_VERSION}"
ulimit -u 10000
DEEPVARIANT_SIF=/datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/deepvariant_1.4.0.sif
CACTUS_SIF=/datasets/work/ncmi-toa-rrbs/work/13.Eels/genome_comparison/Cactus/cactus_latest.sif


PREFIX=School_shark_pan
OUT_DIR=/scratch3/dev093/2.School_shark/PACBIO

## DEEPVARIANT
REF=OG706
# REF=SS_278

DV_OUT_DIR=/scratch3/dev093/2.School_shark/PACBIO/${REF}/VCF/deepvariant_output
mkdir -p ${DV_OUT_DIR}

IN_PATH=/scratch3/dev093/2.School_shark/PACBIO/${REF}_all5mC.bam
BAM_SORT=/scratch3/dev093/2.School_shark/PACBIO/${REF}/Alignment/${REF}_sorted.bam
REF_PATH=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.fa
REF_MMI=/scratch3/dev093/2.School_shark/Bismark_NEW_genome_index/OG706_v240206.hic1.3.curated.hap1.chr_level.mmi
PANGENOME=/scratch3/dev093/2.School_shark/pangenome/Cactus/${PREFIX}/${PREFIX}.gbz
LOG_DIR=${DV_OUT_DIR}/log_${CHR}
VCF_DV=${DV_OUT_DIR}/${REF}_align_from_deepvariant_${CHR}.vcf.gz
VCF_G_DV=${DV_OUT_DIR}/${REF}_align_from_deepvariant_${CHR}.gvcf.gz



module load  seqkit/2.7.0
seqkit grep -n -p "SUPER_X" ${REF_PATH} -o SUPER_X.fa



export INTERMED_DIR=${DV_OUT_DIR}/INTERMED_$CHR
export TMPDIR=${DV_OUT_DIR}/tmp
export SINGULARITY_CACHEDIR=${WORK_DIR}/.singularity/cache
export SINGULARITY_TMPDIR=${WORK_DIR}/.singularity/temp
echo $PATH

mkdir -p ${OUT_PATH}/${PREFIX}/VCF/deepvariant_output
mkdir -p ${LOG_DIR}
mkdir -p ${INTERMED_DIR}
mkdir -p ${TMPDIR}

echo ">>Deepvariant call<<"

singularity exec -H /datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/.singularity/ \
	--bind $TMPDIR \
	${DEEPVARIANT_SIF} \
	/opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=${REF_PATH} \
  --reads=${BAM_SORT}\
  --output_vcf=${VCF_DV} \
  --output_gvcf=${VCF_G_DV} \
  --num_shards=${SLURM_CPUS_PER_TASK} \
  --regions=${CHR}\
  --intermediate_results_dir=${INTERMED_DIR} \
	--logging_dir=${LOG_DIR}

rsync -r --update ${DV_OUT_DIR}/ ${WORK_DIR}/PACBIO/${REF}/VCF/deepvariant_output/



###################################################################################
echo ">>concatenate vcf<<"
module load bcftools
bcftools concat ${DV_OUT_DIR}/${REF}_align_from_deepvariant_*.vcf.gz --output  ${DV_OUT_DIR}/${REF}_align_from_deepvariant.vcf.gz
bcftools concat ${DV_OUT_DIR}/${REF}_align_from_deepvariant_*.gvcf.gz --output  ${DV_OUT_DIR}/${REF}_align_from_deepvariant.gvcf.gz

###################################################################################
echo ">>merge vcf<<"

rsync -r /datasets/work/ncmi-toa-rrbs/work/3.Epaulette_Shark/GLnexus ${OUT_DIR}/

cd ${OUT_DIR}/GLnexus
rm -r ./GLnexus.DB

rm -r ./GLnexus.DB_old
rm ./all*
mkdir ${OUT_DIR}/GLnexus/All_gvcf
rsync -av ${OUT_DIR}/OG706/VCF/deepvariant_output/OG706_align_from_deepvariant.gvcf.gz \
    ${OUT_DIR}/SS_278/VCF/deepvariant_output/SS_278_align_from_deepvariant.gvcf.gz \
    ${OUT_DIR}/GLnexus/All_gvcf/
    

chmod +x glnexus_cli
./glnexus_cli \
  --config DeepVariant \
  --threads ${SLURM_CPUS_PER_TASK} \
   ./All_gvcf/*.gvcf.gz > all_deepvariants.bcf

module load htslib
bcftools view all_deepvariants.bcf | bgzip -@ 4 -c > SS_all_deepvariants.vcf.gz

rsync -r --update ${OUT_DIR}/ ${WORK_DIR}/PACBIO/


duration=$SECONDS
echo "$(($duration / 3600)) hours, $((($duration / 60) % 60)) minutes and $(($duration % 60)) seconds elapsed."
