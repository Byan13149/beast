#!/bin/bash
#SBATCH -J train_ae
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=train_ae_left_ecb5520d_%j.out
#SBATCH --error=train_ae_left_ecb5520d_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --time=02:00:00
#! Number of GPUs per node (1-4; must be 4 if nodes>1):
#SBATCH --gres=gpu:1

#! GPU partition:
#SBATCH -p ampere

#! Don't put any #SBATCH directives below this line

export PYTHONUNBUFFERED=1

module purge
module load rhel8/default-icl

source ~/.bashrc
conda activate beast-new

ROOT=~/rds/hpc-work/3d
cd $ROOT/beast

beast train --config configs/resnet_ae.yaml \
            --data /rds/user/bc654/hpc-work/3d/data/extracted_frames/finetune/leftCamera.video/_iblrig_leftCamera.downsampled.ecb5520d-1358-434c-95ec-93687ecd1396 \
            --output ../runs/resnet_ae_left_ecb5520d

conda deactivate
