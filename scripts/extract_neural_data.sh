#!/bin/bash
#SBATCH -A MPHIL-DIS-SL2-CPU
#SBATCH --job-name="extract"
#SBATCH --output=extract_%A_%a.out
#SBATCH --error=extract_%A_%a.err
#SBATCH --mem 200000
#SBATCH -t 0-00:30:00
#SBATCH --export=ALL
#SBATCH -p icelake

export PYTHONUNBUFFERED=1

# Load environment
. ~/.bashrc

module load ffmpeg

eid=${1}
one_cache_path=${2}
video_timestamps=${3}
output_path=${4}
# CPUs assigned to this task
n_workers="${SLURM_CPUS_PER_TASK:-1}"

echo "Output will be saved to: $output_path"

# Change to repo root
cd ..

# Activate environment
conda activate beast

python beast/extract_neural_data.py --eid "$eid" \
  --one_cache_path "$one_cache_path" \
  --video_timestamps "$video_timestamps" \
  --output_path "$output_path" \
  --n_workers "$n_workers"

# Deactivate environment
conda deactivate

# Return to scripts directory
cd scripts
