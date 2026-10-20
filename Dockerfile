# DeepSeek-V4.1-Flash-1017 SAGE-EXL3 engine for Spark AI Hub, published as
# ghcr.io/waxacabytes/dsv41-exl3-spark-ai-hub.
#
# Built in three steps on a DGX Spark, each from a pinned upstream commit:
#   1. dsv41-1017-ds41f:r6w  justincasey/DeepSeek-V4.1-Flash-1017-4x-DGX-Spark
#                            @fa77c26, docker/Dockerfile (Christopher Owen's
#                            spark-ds41f r6w, everything pinned inside)
#   2. dsv41-1017-exl3:r6w   vcruz305/DSV4.1-Flash-1017-EXL3-Spark-recipe
#                            @5d54d4f, docker/Dockerfile (vllm-exl3 30e8b94,
#                            exllamav3 42981e6 at MoE tile-K 16, shim, TP1
#                            decode tiles)
#   3. this file, with that recipe repo as the context: its tools, the
#      measured cold-expert membership and SHA256SUMS under /opt/dsv41-recipe,
#      which the Hub recipe's build uses. No weights.
ARG EXL3_IMAGE=dsv41-1017-exl3:r6w
FROM ${EXL3_IMAGE}
COPY tools /opt/dsv41-recipe/tools
COPY configs /opt/dsv41-recipe/configs
COPY scripts/SHA256SUMS /opt/dsv41-recipe/scripts/SHA256SUMS
COPY LICENSE README.md /opt/dsv41-recipe/
LABEL org.opencontainers.image.source="https://github.com/WaxacaBytes/dsv41-exl3-spark-ai-hub" \
      org.opencontainers.image.description="DeepSeek-V4.1-Flash-1017 SAGE-EXL3 serving engine for one DGX Spark (spark-ds41f r6w + vcruz305 EXL3, recipe 5d54d4f). No weights." \
      org.opencontainers.image.licenses="Apache-2.0 AND MIT AND AGPL-3.0-only"
