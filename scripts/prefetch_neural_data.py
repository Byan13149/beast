from __future__ import annotations

import argparse
import logging
import sys

from one.api import ONE

from beast.data.ibl_data_utils import prepare_data

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

EIDS = [
    "4b00df29-3769-43be-bb40-128b1cba6d35",
    "ecb5520d-1358-434c-95ec-93687ecd1396",
    "f312aaec-3b6f-44b3-86b4-3a0c119c0438",
    "72cb5550-43b4-4ef0-add5-e4adfdfb5e02",
    "781b35fd-e1f0-4d14-b2bb-95b7263082bb",
]

PARAMS = {
    "interval_len": 1,
    "binsize": 1 / 60,
    "single_region": False,
    "fr_thresh": 0.2,
    "time_window": (-0.2, 0.8),
    "align_time": "stimOn_times",
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--one_cache_path", required=True)
    ap.add_argument("--n_workers", type=int, default=1)
    args = ap.parse_args()

    one = ONE(
        base_url="https://openalyx.internationalbrainlab.org",
        username="intbrainlab",
        password="international",
        silent=True,
        cache_dir=args.one_cache_path,
    )

    for eid in EIDS:
        logging.info("Prefetching EID %s", eid)
        try:
            neural_dict, *_ = prepare_data(one, eid, PARAMS, n_workers=args.n_workers)
            if neural_dict is None:
                logging.warning("EID %s returned no spike data", eid)
            else:
                logging.info("EID %s cached OK", eid)
        except Exception as exc:
            logging.exception("EID %s failed: %s", eid, exc)

    logging.info("Prefetch complete")


if __name__ == "__main__":
    main()