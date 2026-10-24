#!/bin/bash
# Rebuild ghcr.io/waxacabytes/dsv41-exl3-spark-ai-hub:63220db on a DGX Spark, the
# way vcruz305's recipe builds its serving image (scripts/fetch_base.sh, then
# scripts/build_image.sh), with one difference: CUTLASS DSL is NOT reinstalled
# into the base, so the result can be redistributed. Whoever runs the image
# installs CUTLASS DSL 4.7.1 from PyPI with the recipe's base/cutlass-dsl.lock.
#
# Needs docker, zstd, python3 with huggingface_hub, ~45 GB free disk.
set -euo pipefail

RECIPE_REF=63220db0a7cc62dd8b783f71c9cf28f909c9b09b
WORK="${WORK:-$PWD/work}"
mkdir -p "$WORK"

# 1. vcruz305's recipe at the pinned commit.
[ -d "$WORK/recipe" ] || git clone https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe "$WORK/recipe"
git -C "$WORK/recipe" checkout -q "$RECIPE_REF"
. "$WORK/recipe/scripts/env.sh"

# 2. His redistributable base from Hugging Face, checked as fetch_base.sh checks
#    it: archive sha256, the digest of its one layer, its label set.
python3 - "$BASE_HF_REPO" "$BASE_HF_REV" "$BASE_ARCHIVE" "$WORK" <<'PY'
import sys
from huggingface_hub import hf_hub_download
repo, rev, name, out = sys.argv[1:]
hf_hub_download(repo_id=repo, filename=name, revision=rev, local_dir=out)
PY
echo "$BASE_ARCHIVE_SHA256  $WORK/$BASE_ARCHIVE" | sha256sum -c
zstd -dc "$WORK/$BASE_ARCHIVE" | docker load
test "$(docker image inspect "$BASE_REDIST_IMAGE" --format '{{json .RootFS.Layers}}')" = "[\"$BASE_REDIST_LAYER\"]"
got=$(docker image inspect "$BASE_REDIST_IMAGE" --format '{{json .Config.Labels}}' | python3 -c '
import hashlib, json, sys
d = json.load(sys.stdin); d.pop("local.dsv41.redist", None)
print(hashlib.sha256("".join(f"{k}={v}\n" for k, v in sorted(d.items())).encode()).hexdigest())')
test "$got" = "$BASE_LABELS_SHA256"

# 3. His serving layer (docker/Dockerfile) with his build_image.sh arguments, on
#    that base.
docker build \
  -f "$WORK/recipe/docker/Dockerfile" \
  --build-arg "BASE_IMAGE=$BASE_REDIST_IMAGE" \
  --build-arg "PLUGIN_REPO=$PLUGIN_REPO" \
  --build-arg "PLUGIN_REF=$PLUGIN_REF" \
  --build-arg "FORK_REPO=$FORK_REPO" \
  --build-arg "FORK_REF=$FORK_REF" \
  --build-arg "MOE_TILESIZE_K=$MOE_TILESIZE_K" \
  -t ghcr.io/waxacabytes/dsv41-exl3-spark-ai-hub:63220db \
  "$WORK/recipe"
