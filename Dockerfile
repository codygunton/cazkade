# Copyright 2023 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

FROM rust:1.85 AS build
RUN mkdir /bootstrap && \
  cp -r /usr/local/cargo /bootstrap/cargo && \
  cp -r /usr/local/rustup /bootstrap/rustup

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y build-essential git curl wget ca-certificates vim \
  binutils-dev libunwind-dev libblocksruntime-dev clang \
  device-tree-compiler zsh python3-pip \
  binutils-riscv64-unknown-elf

# Install oh my zsh and some convenience plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' /root/.zshrc

# Copy Rust toolchain
COPY --from=build /bootstrap/cargo /usr/local/cargo
COPY --from=build /bootstrap/rustup /usr/local/rustup
ENV PATH="/usr/local/cargo/bin:$PATH"

WORKDIR /workspace
# Clone and build
RUN git clone https://github.com/codygunton/risc0.git -b fuzz
RUN git clone https://github.com/google/honggfuzz

RUN cd /workspace/honggfuzz && make

RUN cd /workspace/risc0 && cargo build --release -p risc0-r0vm

# Install spike (commit is recent but arbitrary)
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git
RUN cd riscv-isa-sim && git checkout ba54a6015f9ba8ee30dfd4885b5ba9e28aa2528e && mkdir build && cd build && ../configure --prefix=$RISCV && make -j
RUN cd riscv-isa-sim/build && make install

# Some environment variables
ENV PREFIX_CASCADE="$HOME/prefix-cascade"
ENV CARGO_HOME=$PREFIX_CASCADE/.cargo
ENV RUSTUP_HOME=$PREFIX_CASCADE/.rustup

ENV RUSTEXEC="$CARGO_HOME/bin/rustc"
ENV RUSTUPEXEC="$CARGO_HOME/bin/rustup"
ENV CARGOEXEC="$CARGO_HOME/bin/cargo"

# TODO: remove old rust install 
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install some Python dependencies for cascade
RUN pip3 install tqdm numpy filelock

# Install custom makeelf
RUN git clone https://github.com/flaviens/makeelf && cd makeelf && git checkout finercontrol && python3 setup.py install

# Clone my branch of cascasde
RUN git clone https://github.com/codygunton/cascade-meta -b cg/no-csrs

# Set the design repo locations correctly for the Docker environment
COPY design_repos.json /cascade-meta/design-processing/design_repos.json
COPY cascade-designs /workspace/cascade-designs

ENV PATH="$PATH:$PREFIX_CASCADE/bin"


WORKDIR /workspace
COPY init_corpus.sh .
COPY generate.sh .
COPY fuzz.sh .
COPY .crashignore .

RUN chmod +x generate.sh && chmod +x fuzz.sh && chmod +x init_corpus.sh \
  && mkdir -p /hfuzz_crashes /hfuzz_workdir


