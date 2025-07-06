#!/bin/bash

if [ ! -d ./corpus ]; then
  ./init_corpus.sh
fi

RAYON_NUM_THREADS=8 ./honggfuzz/honggfuzz \
  --threads 8 \
  --timeout 30 \
  --workspace /workspace/hfuzz_workdir \
  --crashdir /workspace/hfuzz_crashes \
  --mutate_cmd /workspace/generate.sh \
  --stackhash_bl .crashignore \
  -i /workspace/corpus \
  -x \
  -N 4096 \
  -- /workspace/risc0/target/release/r0vm --test-elf ___FILE___
