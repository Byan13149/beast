#!/bin/bash
#SBATCH -J test_b
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=test_%j.out
#SBATCH --error=test_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=04:00:00
#! Number of GPUs per node (1-4; must be 4 if nodes>1):
#SBATCH --gres=gpu:1

#! GPU partition:
#SBATCH -p ampere

#! Don't put any #SBATCH directives below this line

export PYTHONUNBUFFERED=1

module purge
module load rhel8/default-icl

source ~/.bashrc
conda activate beast

cd ~/rds/hpc-work/3d/beast

eid=${1}
neural_input_dir=${2}
latent_input_dir=${3}
eval_task=${4}

python encoding_decoding/test.py \
  --eid "$eid" \
  --neural_input_dir "$neural_input_dir" \
  --latent_input_dir "$latent_input_dir" \
  --eval_task "$eval_task"

conda deactivate
