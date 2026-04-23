#!/bin/bash
#SBATCH -J enc_72cb5550
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=encode_72cb5550_%j.out
#SBATCH --error=encode_72cb5550_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=00:30:00
#SBATCH --gres=gpu:1
#SBATCH -p ampere

export PYTHONUNBUFFERED=1

module purge
module load rhel8/default-icl

source ~/.bashrc
conda activate beast-new

set -eo pipefail

eid=72cb5550-43b4-4ef0-add5-e4adfdfb5e02

ROOT=~/rds/hpc-work/3d
cd $ROOT/beast

neural_input_dir=$ROOT/data/neural

for view in left right; do
  latent_input_dir=$ROOT/data/latents_${view}
  echo "=== Encoding (${view}) for $eid ==="
  python encoding_decoding/test.py \
    --eid "$eid" \
    --neural_input_dir "$neural_input_dir" \
    --latent_input_dir "$latent_input_dir" \
    --eval_task encoding
done

conda deactivate
