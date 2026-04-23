"""Align per-frame video latents to neural train/val/test intervals.

Produces `<latent_input_dir>/<eid>/z_trials.npz` consumed by test.py with:
  - z_trials_time: (K, T, V, D)  K=trials in train+val+test order, T=bins/trial, V=views, D=latent dim
  - trial_split:  array of "train"/"val"/"test" labels per trial (length K)
"""
import argparse
import os
import numpy as np


def slice_trials(latents, timestamps, intervals, n_bins):
    """For each [t0, t1) interval, take n_bins consecutive frames starting at the
    first frame whose timestamp >= t0. Assumes timestamps are uniformly sampled
    at the same rate the neural data was binned."""
    out = np.empty((len(intervals), n_bins, latents.shape[1]), dtype=latents.dtype)
    starts = np.searchsorted(timestamps, intervals[:, 0], side="left")
    for i, s in enumerate(starts):
        e = s + n_bins
        if e > len(latents):
            raise ValueError(
                f"Interval {i} {intervals[i]} runs past end of video "
                f"(start frame {s}, need {n_bins}, have {len(latents)})"
            )
        out[i] = latents[s:e]
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--eid", required=True)
    p.add_argument("--latents", required=True, help="path to per-frame latents .npy")
    p.add_argument("--timestamps", required=True, help="path to per-frame timestamps .npy")
    p.add_argument("--neural_input_dir", required=True, help="dir holding <eid>_aligned.npz")
    p.add_argument("--out_dir", required=True, help="parent latent_input_dir; <eid>/ is appended")
    p.add_argument("--n_bins", type=int, default=60)
    args = p.parse_args()

    latents = np.load(args.latents)              # (N_frames, D)
    timestamps = np.load(args.timestamps)        # (N_frames,)
    if latents.shape[0] != timestamps.shape[0]:
        raise ValueError(
            f"latents/timestamps length mismatch: {latents.shape[0]} vs {timestamps.shape[0]}"
        )

    neural = np.load(
        os.path.join(args.neural_input_dir, f"{args.eid}_aligned.npz"), allow_pickle=True
    )
    train_iv = neural["train_intervals"]
    val_iv = neural["val_intervals"]
    test_iv = neural["test_intervals"]

    z_train = slice_trials(latents, timestamps, train_iv, args.n_bins)
    z_val = slice_trials(latents, timestamps, val_iv, args.n_bins)
    z_test = slice_trials(latents, timestamps, test_iv, args.n_bins)

    z_all = np.concatenate([z_train, z_val, z_test], axis=0)  # (K, T, D)
    z_trials_time = z_all[:, :, None, :]                      # (K, T, V=1, D)

    trial_split = np.array(
        ["train"] * len(train_iv) + ["val"] * len(val_iv) + ["test"] * len(test_iv)
    )

    out_dir = os.path.join(args.out_dir, args.eid)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "z_trials.npz")
    np.savez(out_path, z_trials_time=z_trials_time, trial_split=trial_split)
    print(f"Saved {out_path}  z_trials_time={z_trials_time.shape}  splits={len(trial_split)}")


if __name__ == "__main__":
    main()
