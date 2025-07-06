# Cazkade
A RISC-V ZKVM fuzzing component built from from Cascade ([overiew](https://comsec.ethz.ch/research/hardware-design-security/cascade-cpu-fuzzing-via-intricate-program-generation/); the authors' [Dockerfile](https://github.com/comsec-group/cascade-artifacts); [core library](https://github.com/cascade-artifacts-designs/cascade-meta)) and [Honggfuzz](https://github.com/google/honggfuzz).

Currently this is a proof of concept targeting RISC Zero's `r0vm`.

## Build
```
docker build -t cascade-r0 .
```

## Run
```
docker run --name cascade-r0-fuzz -dit \
  -v "$(pwd)/hfuzz_crashes":/hfuzz_crashes \
  -v "$(pwd)/hfuzz_workdir":/hfuzz_workdir \
  cascade-r0 zsh
```

## Execute
```
docker exec -it cascade-r0-fuzz zsh
# edit fuzz.sh with your desired threading parameters
./fuzz.sh
```

A report `HONGGFUZZ.REPORT.TXT` will be created in the Honggfuzz workdir. Any crashes listed in there will have the problematic examples saved in the crashes directory for investigation.

# Notes
We are generating targets with a fork of the original Cascade library. The fork makes several changes, chiefly: shutting off privileged instructions and fence instructions, which are both currently not supported in RISC Zero. 

The library has its own parallel generation strategy, but is geared toward testing hardware implementations of RISC-V, and so we only use the test generation pieces. Our goal is to use Honggfuzz for crash logging and potentially other features. To do this without having to to do custom orchestration logic to periodcally halt fuzzing to repopulate a corpus, we use the custom mutation framework to simply overwrite an existing example with a new one (see `mutate_cmd` in fuzz.sh). This is clunky and has high overhead. There is also a race condition that triggers infrequently with good parameters (too many honggfuzz threads will lead to more errors). We use two mechanisms to deal with the race condition. First, we generate a large initial corpus (8192 examples, total size approximately 4GB). This seems resolves most false positives, likely because of insafe concurrent accesses. Next, we filter out errors due to this race condition by listing the corresponding call stack hash in .crashignore--crashes are still counted but are listed under `blocklist`.

Many improvements are possible here. Among those are: coverage measurement; use of "persistent mode"; changes to Cascade to make it more friendly to the sort of parallelism we use; stripping away of unneeded parts of Cascade; a more optimized rewrite of the Cascade generator; augmentation of the generation to support coverage guidance (the randomness in the test binaries could be surfaced to allow the fuzzer to drive example generation in a continuous way).
