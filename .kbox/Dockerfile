FROM ubuntu:26.04

# `apt update` must run in the same layer as each install: as its own layer
# it gets cached, and the stale package lists later 404 against the archive.

# kernel build dependencies
RUN apt update && apt install -y --no-install-recommends \
      build-essential flex bison bc libssl-dev libelf-dev libncurses-dev \
      dwarves kmod cpio zstd git python3

# documentation build dependencies
RUN apt update && apt install -y --no-install-recommends \
      dvipng fonts-dejavu fonts-noto-cjk graphviz imagemagick latexmk librsvg2-bin \
      python3-venv python3-yaml python3-sphinx tex-gyre texlive-fonts-recommended \
      texlive-lang-chinese texlive-xetex

# Cross toolchain: the VM is arm64, so x86_64 builds need a cross compiler.
RUN apt update && apt install -y --no-install-recommends \
      gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu

WORKDIR /src

