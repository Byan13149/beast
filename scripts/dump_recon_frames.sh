#!/bin/bash
# Post-process completed recon MP4s: build side-by-side MP4 + dump PNG galleries.
# Safe to re-run; skips models whose side-by-side already exists.
# No GPU needed, runs on login node or as a short CPU SLURM job.

set -eu

ROOT=~/rds/hpc-work/3d

EIDS=(
  4b00df29-3769-43be-bb40-128b1cba6d35
  72cb5550-43b4-4ef0-add5-e4adfdfb5e02
  781b35fd-e1f0-4d14-b2bb-95b7263082bb
  ecb5520d-1358-434c-95ec-93687ecd1396
  f312aaec-3b6f-44b3-86b4-3a0c119c0438
)
VIEWS=(left right)
STRIDE=${STRIDE:-60}   # dump every Nth frame (default 60)

FFMPEG=${FFMPEG:-}
if [[ -z "$FFMPEG" ]]; then
  if command -v ffmpeg >/dev/null 2>&1; then
    FFMPEG=ffmpeg
  elif [[ -x /rds/user/bc654/hpc-work/envs/beast/bin/ffmpeg ]]; then
    FFMPEG=/rds/user/bc654/hpc-work/envs/beast/bin/ffmpeg
  else
    echo "ffmpeg not found on PATH (set FFMPEG=... to override)" >&2; exit 1
  fi
fi
echo "using ffmpeg: $FFMPEG"

for eid in "${EIDS[@]}"; do
  for view in "${VIEWS[@]}"; do
    short=${eid%%-*}
    recon_dir=$ROOT/data/recon/resnet_ae_${view}_${short}
    video_file=$ROOT/data/finetune/${view}Camera.video/_iblrig_${view}Camera.downsampled.${eid}.mp4
    recon_mp4=$recon_dir/_iblrig_${view}Camera.downsampled.${eid}_reconstruction.mp4
    side_mp4=$recon_dir/_iblrig_${view}Camera.downsampled.${eid}_side_by_side.mp4

    echo "=== [$view / $short] ==="
    if [[ ! -f "$recon_mp4" ]]; then
      echo "  skip: no reconstruction mp4 yet ($recon_mp4)"; continue
    fi
    if [[ ! -f "$video_file" ]]; then
      echo "  skip: original video missing ($video_file)"; continue
    fi

    if [[ ! -f "$side_mp4" ]]; then
      echo "  building side-by-side mp4"
      "$FFMPEG" -y -loglevel error \
        -i "$video_file" -i "$recon_mp4" \
        -filter_complex "[0:v]scale=224:224[o];[o][1:v]hstack=inputs=2" \
        -c:v libx264 -pix_fmt yuv420p "$side_mp4"
    else
      echo "  side-by-side already exists"
    fi

    orig_png_dir=$recon_dir/frames_original
    recon_png_dir=$recon_dir/frames_reconstruction
    side_png_dir=$recon_dir/frames_side_by_side
    mkdir -p "$orig_png_dir" "$recon_png_dir" "$side_png_dir"

    echo "  dumping every ${STRIDE}th frame as PNG"
    "$FFMPEG" -y -loglevel error -i "$video_file" \
      -vf "select=not(mod(n\,${STRIDE})),scale=224:224" -vsync vfr \
      "$orig_png_dir/frame_%05d.png"
    "$FFMPEG" -y -loglevel error -i "$recon_mp4" \
      -vf "select=not(mod(n\,${STRIDE}))" -vsync vfr \
      "$recon_png_dir/frame_%05d.png"
    "$FFMPEG" -y -loglevel error -i "$side_mp4" \
      -vf "select=not(mod(n\,${STRIDE}))" -vsync vfr \
      "$side_png_dir/frame_%05d.png"

    n=$(ls "$side_png_dir" | wc -l)
    echo "  done ($n frames in frames_side_by_side)"
  done
done
