#!/bin/bash

if [ ! -d ./corpus ]; then
  ./init_corpus.sh
fi

# On these parameters:
#  - mutate_cmd mutates our corpus examples, for us, it simply overwrites them with new example
#  - the RAYON number determins how many threads r0vm uses
#  - threads determiens how many examples honggfuzz executes at once
# Note: in practice, 30s is too slow for the largest examples on 4 threads per examle. This result
# in crashes because we supply the tmout_sigvalrm flag.

# The --statsfile flag seems broken, so we make our own flag to log metrics from the fuzzing run
stats_file="stats_$(date -u +%Y%m%d_%H%M%S).log"

RAYON_NUM_THREADS=4 ./honggfuzz/honggfuzz \
  --threads 48 \
  --timeout 30 \
  --workspace /workspace/workdir \
  --crashdir /workspace/crashes \
  --mutate_cmd /workspace/generate.sh \
  --stackhash_bl .crashignore \
  --input /workspace/corpus \
  --noinst \
  --tmout_sigvtalrm \
  --run_time 86400 \
  --mutations_per_run 128 \
  -- /workspace/risc0/target/release/r0vm --test-elf ___FILE___ \
  2>&1 | tee "$stats_file"
