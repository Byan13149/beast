#!/bin/bash
#SBATCH -J test_ae
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=test_ae_right_4b00df29_%j.out
#SBATCH --error=test_ae_right_4b00df29_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
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

eid=4b00df29-3769-43be-bb40-128b1cba6d35
view=right

ROOT=~/rds/hpc-work/3d
cd $ROOT/beast

run_dir=$ROOT/runs/resnet_ae_${view}_${eid%%-*}
video_file=$ROOT/data/finetune/${view}Camera.video/_iblrig_${view}Camera.downsampled.${eid}.mp4
latents_raw_dir=$ROOT/data/latents_raw/resnet_ae_${view}_${eid%%-*}
latents_npy=$latents_raw_dir/_iblrig_${view}Camera.downsampled.${eid}.npy
timestamps=$ROOT/data/finetune/timestamps/_ibl_leftCamera.times.${eid}.npy
neural_input_dir=$ROOT/data/neural
latent_input_dir=$ROOT/data/latents_${view}

echo "=== Step 1: extract per-frame latents ==="
beast predict \
  --model  "$run_dir" \
  --input  "$video_file" \
  --output "$latents_raw_dir" \
  --save_latents

echo "=== Step 2: align latents to trial intervals ==="
python encoding_decoding/align_latents.py \
  --eid "$eid" \
  --latents    "$latents_npy" \
  --timestamps "$timestamps" \
  --neural_input_dir "$neural_input_dir/$eid" \
  --out_dir    "$latent_input_dir" \
  --n_bins 60

echo "=== Step 3: encoding ==="
python encoding_decoding/test.py \
  --eid "$eid" \
  --neural_input_dir "$neural_input_dir" \
  --latent_input_dir "$latent_input_dir" \
  --eval_task encoding

echo "=== Step 4: decoding ==="
python encoding_decoding/test.py \
  --eid "$eid" \
  --neural_input_dir "$neural_input_dir" \
  --latent_input_dir "$latent_input_dir" \
  --eval_task decoding

conda deactivate
