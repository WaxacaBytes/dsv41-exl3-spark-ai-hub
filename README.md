# DeepSeek-V4.1-Flash-1017 SAGE-EXL3 engine for Spark AI Hub

The serving engine for **DeepSeek-V4.1-Flash-1017** on one NVIDIA DGX Spark (aarch64, GB10 sm_121), as a
pre-built image for [Spark AI Hub](https://github.com/WaxacaBytes/spark-ai-hub).

It is the engine of [vcruz305's one-Spark recipe](https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe)
at commit `5d54d4f`, which serves [vcruz305's SAGE-EXL3 1.62 bpw pack](https://huggingface.co/vcruz305/DSV4.1-Flash-1017-SAGE-EXL3-1.62bpw):
Christopher Owen's [spark-ds41f](https://github.com/christopherowen/spark-ds41f) release r6w (a vLLM fork with
TileLang SM12x kernels), plus vcruz305's [vllm-exl3](https://github.com/vcruz305/vllm-exl3) and
[exllamav3](https://github.com/vcruz305/exllamav3) forks (MoE tile-K 16), the quant-config shim and the TP1 decode
tiles, with that recipe's tools under `/opt/dsv41-recipe`. Their recipe builds this on every machine that runs it;
this repo publishes it once, so the Hub's recipe pulls it.

| Tag | |
|---|---|
| `r6w-5d54d4f` | spark-ds41f r6w + vcruz305's recipe at `5d54d4f` |

**No weights in this image.** The Hub recipe `vllm-deepseek-v41-flash-1017-sage-exl3` bakes the pack in on top
(revision `2a605935`, checked against the recipe's `SHA256SUMS`) and builds the cold-expert side file with
`/opt/dsv41-recipe/tools/ats_build_alias.py`.

## How it is built

The build needs about 64 GiB of free memory and makes a 25.5 GB image, beyond GitHub's hosted arm64 runners, so it is
built on a DGX Spark and pushed from there. Every input is pinned by commit or digest.

`base/` is a copy of `docker/`, `LICENSE` and `NOTICE` from justincasey's
DeepSeek-V4.1-Flash-1017-4x-DGX-Spark at commit `fa77c26` (Apache-2.0), which this engine was built from; that
repository is no longer public. Its Dockerfile fetches every upstream at a pinned commit.

```sh
# 1. spark-ds41f r6w, per justincasey's 4x-Spark recipe (about 20 min on a Spark), from the copy in base/
docker build -f base/docker/Dockerfile -t dsv41-1017-ds41f:r6w base

# 2. vcruz305's EXL3 layer
git clone https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe recipe && git -C recipe checkout 5d54d4f
docker build -f recipe/docker/Dockerfile \
  --build-arg BASE_IMAGE=dsv41-1017-ds41f:r6w \
  --build-arg PLUGIN_REF=30e8b941376ce2d43bc8438439937c4809106635 \
  --build-arg FORK_REF=42981e660d18bd893fb1bf732905fafa2a9fe97c \
  --build-arg MOE_TILESIZE_K=16 \
  -t dsv41-1017-exl3:r6w recipe

# 3. this repo's Dockerfile, with the recipe repo as the context
docker build -f Dockerfile -t ghcr.io/waxacabytes/dsv41-exl3-spark-ai-hub:r6w-5d54d4f recipe
```

## Licenses

This image contains software under several licenses; each component keeps its own:

- [vllm-exl3](https://github.com/vcruz305/vllm-exl3) at `30e8b941376ce2d43bc8438439937c4809106635`:
  **AGPL-3.0-only**, with MIT-licensed material from Mia's AI Lab and Turboderp (its NOTICE and THIRD_PARTY_NOTICES).
  Its complete source is the public repository at that commit.
- [exllamav3](https://github.com/vcruz305/exllamav3) at `42981e660d18bd893fb1bf732905fafa2a9fe97c`: MIT.
- vcruz305's [recipe](https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe) at `5d54d4f`: MIT; its LICENSE
  and README are in the image at `/opt/dsv41-recipe/`.
- spark-ds41f (Christopher Owen), justincasey's build and patches (`base/`), and vLLM: Apache-2.0. `base/NOTICE` lists
  every other component the base build fetches, and its license.

This repository's own files are Apache-2.0. The model weights are not in the image; DeepSeek publishes them under the
MIT license.
