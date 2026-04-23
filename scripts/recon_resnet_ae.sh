#!/bin/bash
#SBATCH -J recon_ae
#SBATCH -A MPHIL-DIS-SL2-GPU
#SBATCH --output=recon_ae_%j.out
#SBATCH --error=recon_ae_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=02:00:00
#SBATCH --gres=gpu:1
#SBATCH -p ampere

# Reconstruct video frames from all 10 trained ResNet-AE models
# (5 sessions x {left, right}) and build side-by-side originalreconstruction
# MP4s for visual inspection.

export PYTHONUNBUFFERED=1

module purge
module load rhel8/default-icl

source ~/.bashrc
conda activate beast-new

ROOT=~/rds/hpc-work/3d
cd $ROOT/beast

EIDS=(
  4b00df29-3769-43be-bb40-128b1cba6d35
  72cb5550-43b4-4ef0-add5-e4adfdfb5e02
  781b35fd-e1f0-4d14-b2bb-95b7263082bb
  ecb5520d-1358-434c-95ec-93687ecd1396
  f312aaec-3b6f-44b3-86b4-3a0c119c0438
)
VIEWS=(left right)

for eid in "${EIDS[@]}"; do
  for view in "${VIEWS[@]}"; do
    short=${eid%%-*}
    run_dir=$ROOT/runs/resnet_ae_${view}_${short}
    video_file=$ROOT/data/finetune/${view}Camera.video/_iblrig_${view}Camera.downsampled.${eid}.mp4
    recon_dir=$ROOT/data/recon/resnet_ae_${view}_${short}
    recon_mp4=$recon_dir/_iblrig_${view}Camera.downsampled.${eid}_reconstruction.mp4
    side_mp4=$recon_dir/_iblrig_${view}Camera.downsampled.${eid}_side_by_side.mp4

    echo "=== [$view / $short] reconstructing ==="
    if [[ ! -d "$run_dir" ]]; then
      echo "  skip: no run dir $run_dir"; continue
    fi
    if [[ ! -f "$video_file" ]]; then
      echo "  skip: no video $video_file"; continue
    fi

    mkdir -p "$recon_dir"
    beast predict \
      --model  "$run_dir" \
      --input  "$video_file" \
      --output "$recon_dir" \
      --save_reconstructions

    if [[ -f "$recon_mp4" ]] && command -v ffmpeg >/dev/null 2>&1; then
      echo "  building side-by-side MP4"
      ffmpeg -y -loglevel error \
        -i "$video_file" -i "$recon_mp4" \
        -filter_complex "[0:v]scale=224:224[o];[o][1:v]hstack=inputs=2" \
        -c:v libx264 -pix_fmt yuv420p "$side_mp4"

      # dump a gallery of single frames (one every ~2 s at 30 fps -> every 60 frames)
      orig_png_dir=$recon_dir/frames_original
      recon_png_dir=$recon_dir/frames_reconstruction
      side_png_dir=$recon_dir/frames_side_by_side
      mkdir -p "$orig_png_dir" "$recon_png_dir" "$side_png_dir"

      echo "  dumping per-frame PNGs (every 60th frame)"
      ffmpeg -y -loglevel error -i "$video_file" \
        -vf "select=not(mod(n\,60)),scale=224:224" -vsync vfr \
        "$orig_png_dir/frame_%05d.png"
      ffmpeg -y -loglevel error -i "$recon_mp4" \
        -vf "select=not(mod(n\,60))" -vsync vfr \
        "$recon_png_dir/frame_%05d.png"
      ffmpeg -y -loglevel error -i "$side_mp4" \
        -vf "select=not(mod(n\,60))" -vsync vfr \
        "$side_png_dir/frame_%05d.png"
    fi
  done
done

conda deactivate
