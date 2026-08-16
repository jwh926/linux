FROM ubuntu:26.04

RUN apt update

# kernel build dependencies
RUN apt install -y --no-install-recommends \
      build-essential flex bison bc libssl-dev libelf-dev libncurses-dev \
      dwarves kmod cpio zstd ccache git python3

# documentation build dependencies
RUN apt install -y --no-install-recommends \
      dvipng fonts-dejavu fonts-noto-cjk graphviz imagemagick latexmk librsvg2-bin \
      python3-venv python3-yaml python3-sphinx tex-gyre texlive-fonts-recommended \
      texlive-lang-chinese texlive-xetex

# Cross toolchain: the VM is arm64, so x86_64 builds need a cross compiler.
RUN apt install -y --no-install-recommends \
      gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu

WORKDIR /out

