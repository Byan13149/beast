#!/bin/bash
#SBATCH -J test_ae_v6
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=test_ae_left_4b00df29_v6_%j.out
#SBATCH --error=test_ae_left_4b00df29_v6_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --gres=gpu:1
#SBATCH -p ampere

# Test the 50-d (num_latents=50) ResNet-AE retrained on 4b00df29 left view.
# Uses a parallel "_v6" directory tree so 100-d artifacts are not overwritten.

export PYTHONUNBUFFERED=1

module purge
module load rhel8/default-icl

source ~/.bashrc
conda activate beast-new

eid=4b00df29-3769-43be-bb40-128b1cba6d35
view=left
tag=v6                # suffix keeps these runs separate from 100-d outputs

ROOT=~/rds/hpc-work/3d
cd $ROOT/beast

run_dir=$ROOT/runs/resnet_ae_${view}_${eid%%-*}_${tag}
video_file=$ROOT/data/finetune/${view}Camera.video/_iblrig_${view}Camera.downsampled.${eid}.mp4
latents_raw_dir=$ROOT/data/latents_raw/resnet_ae_${view}_${eid%%-*}_${tag}
latents_npy=$latents_raw_dir/_iblrig_${view}Camera.downsampled.${eid}.npy
timestamps=$ROOT/data/finetune/timestamps/_ibl_leftCamera.times.${eid}.npy
neural_input_dir=$ROOT/data/neural
latent_input_dir=$ROOT/data/latents_${view}_${tag}

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
