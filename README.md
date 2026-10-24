# DeepSeek-V4.1-Flash-1017 EXL3 engine for Spark AI Hub

The serving engine of [vcruz305's one-Spark recipe](https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe)
for **DeepSeek-V4.1-Flash-1017** on one NVIDIA DGX Spark (aarch64, GB10 sm_121), as a pre-built image for
[Spark AI Hub](https://github.com/WaxacaBytes/spark-ai-hub).

His recipe builds this image on every machine that runs it (`scripts/build_image.sh`); this repository builds it
once, with his steps and his pins, and publishes it, so the Hub's recipes pull it.

| Tag | Built from |
|---|---|
| `63220db` | vcruz305's recipe at commit [`63220db`](https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe/tree/63220db0a7cc62dd8b783f71c9cf28f909c9b09b) |

What is in it, all from that commit's `scripts/env.sh`:

- **Base:** his redistributable base, [vcruz305/DSV4.1-Flash-1017-Spark-base-image](https://huggingface.co/vcruz305/DSV4.1-Flash-1017-Spark-base-image)
  at revision `17ed4336`, checked by archive sha256, layer digest and label set. It is Christopher Owen's
  [spark-ds41f](https://github.com/christopherowen/spark-ds41f) r6w built from his recipe's `base/`.
- **His serving layer** (`docker/Dockerfile`): [vllm-exl3](https://github.com/vcruz305/vllm-exl3) `30e8b941`,
  [exllamav3](https://github.com/vcruz305/exllamav3) `909ad856` (warp-private MoE pipeline stages, MoE tile-K 16),
  the TP1 decode tiles, and his shim `dsv41_exl3_shim` (quant-config, DSML tool-call stop and parameter repair,
  RoPE trim, cold-expert alias, memory probe).

**Not in it: NVIDIA CUTLASS DSL.** Its licence allows redistributing only its Python source, so, exactly as in
vcruz305's published base, the image ships without it. Every Hub recipe that uses this image installs
CUTLASS DSL 4.7.1 from NVIDIA's PyPI release at build time with his `base/cutlass-dsl.lock` (five wheels, pinned by
URL and sha256), which is his `base/Dockerfile.cutlass-dsl` step.

**No weights in it.** The Hub recipes bake a pack in on top, build the cold-expert side file with his
`tools/ats_build_alias.py` and his `configs/cold-alias-selection.json`, and serve with his `scripts/serve_inner.sh`
invocation:

| Hub recipe | Pack |
|---|---|
| `vllm-deepseek-v41-flash-1017-sage-exl3` | [SAGE-EXL3 1.62 bpw](https://huggingface.co/vcruz305/DSV4.1-Flash-1017-SAGE-EXL3-1.62bpw) |
| `vllm-deepseek-v41-flash-1017-derisked-exl3` | [DERISKED-EXL3 1.61 bpw](https://huggingface.co/vcruz305/DSV4.1-Flash-1017-DERISKED-EXL3-1.61bpw) |

## How it is built

`build.sh` here: it clones his recipe at the pinned commit, fetches and checks his base as his
`scripts/fetch_base.sh` does (without the CUTLASS DSL reinstall), and runs his `docker/Dockerfile` with his
`build_image.sh` arguments. Compiling the kernels needs a DGX Spark-class machine (about 30 minutes, ~45 GB of disk),
beyond GitHub's hosted runners, so it is built on a Spark and pushed from there.

## Licenses

Each component keeps its own licence:

- [vllm-exl3](https://github.com/vcruz305/vllm-exl3) at `30e8b941376ce2d43bc8438439937c4809106635`: **AGPL-3.0-only**,
  with MIT-licensed material from Mia's AI Lab and Turboderp (its NOTICE and THIRD_PARTY_NOTICES). Its complete source
  is the public repository at that commit.
- [exllamav3](https://github.com/vcruz305/exllamav3) at `909ad8564fcb9e070caca8a65d380c741681e79c`: MIT.
- vcruz305's [recipe](https://github.com/vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe) (shim, decode tiles): MIT.
- The base: spark-ds41f (Christopher Owen), justincasey's build files and vLLM, Apache-2.0; his recipe's
  `base/NOTICE` lists every other component the base build fetches, and its licence.

This repository's own files are Apache-2.0. The model weights are not in the image; DeepSeek publishes them under the
MIT license.
