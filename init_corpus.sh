#!/bin/bash
set -eu

export USER=$(whoami)
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}

cd /workspace
source cascade-meta/env.sh
tmp=$(mktemp -d)
CASCADE_JOBS=48 python3 cascade-meta/fuzzer/do_genmanyelfs.py 8192 $tmp
mkdir -p corpus
cp $tmp/risc0_*.elf corpus/
