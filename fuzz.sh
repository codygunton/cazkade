#!/bin/bash

if [ ! -d ./corpus ]; then
  ./init_corpus.sh
fi

# On these parameters:
#  - mutate_cmd mutates our corpus examples, for us, it simply overwrites them with new example
#  - the RAYON number determins how many threads r0vm uses
#  - threads determiens how many examples honggfuzz executes at once
#  - the -r parameter (defaults = 6), which is the number of mutations per corpus element
#  - N is the number of executions before fuzzing should stop.
#
# I don't know what happens if N is set to 0 and r defaults to 6. Setting N to corpus size * 6 seems like
# a way to make sure we avoid re-executing the same examples (there _may_ be some small amount of this is
# Honggfuzz doens't always apply the mutator... investigation is needed here).
RAYON_NUM_THREADS=8 ./honggfuzz/honggfuzz \
  --threads 8 \
  --timeout 30 \
  --workspace /workspace/hfuzz_workdir \
  --crashdir /workspace/hfuzz_crashes \
  --mutate_cmd /workspace/generate.sh \
  --stackhash_bl .crashignore \
  -i /workspace/corpus \
  -x \
  -N 49152
-- /workspace/risc0/target/release/r0vm --test-elf ___FILE___
