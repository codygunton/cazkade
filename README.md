# Cazkade
A RISC-V ZKVM fuzzing component built from from [Cascade](https://comsec.ethz.ch/research/hardware-design-security/cascade-cpu-fuzzing-via-intricate-program-generation/) by Solt, Ceesay-Seitz and Razavi (see also the authors' [Dockerfile](https://github.com/comsec-group/cascade-artifacts) and [core library](https://github.com/cascade-artifacts-designs/cascade-meta)) and [Honggfuzz](https://github.com/google/honggfuzz).

Currently this is a proof of concept targeting RISC Zero's [r0vm](https://github.com/risc0/risc0/tree/main/risc0/r0vm).

## Build
Clone this repository and build the container from the top level:
```
docker build -t cazkade .
```

## Run
Run the container, mounting [workdir](./workdir/) and [crashes](./crashes/) for saving results outside of the container:
```
docker run --name r0fuzz -it \
  -v "./workdir":/workspace/workdir \
  -v "./crashes":/workspace/crashes \
  cazkade zsh
```

## Execute
Run the fuzzing script. You may want to adjust parameters in [init_corpus.sh](./init_corpus.sh) (number of threads or corpus size) or in [fuzz.sh](./fuzz.sh) (2x number of threads); see the notes below for more on this.
```
./fuzz.sh
```

A report `HONGGFUZZ.REPORT.TXT` will be created in the [workdir](./workdir/). Any crashes listed in there will have the problematic examples saved in the [crashes](./crashes/) for investigation.

# Notes
## Validation
A quick way to generate crashes is to break r0vm by changing the match instruction in [rv32im.rs](https://github.com/risc0/risc0/blob/bef7bf580eb13d5467074b5f6075a986734d3fe5/risc0/circuit/rv32im/src/execute/rv32im.rs#L350) to break the implementation of an opcode. For instance, changing
```
        let out = match kind {
            InsnKind::Add => rs1.wrapping_add(rs2),
            InsnKind::Sub => rs1.wrapping_sub(rs2),
```
to
```
        let out = match kind {
            InsnKind::Add => rs1.wrapping_sub(rs2), // NOPE
            InsnKind::Sub => rs1.wrapping_sub(rs2),
```
will produce crashes (possibly fewer than you might expect, since `addi `is more common then `add` in Cascade-generated examples).

## Regarding our fork
We are generating targets with a fork of the original Cascade library, which is geared toward fuzzing executable hardware specs. We only use a small part of that library, the test case generation. The fork makes several changes, chiefly: shutting off privileged instructions and fence instructions, which are both currently not supported in RISC Zero.

## Parallel execution
There are parallelism parameters in the shell scripts that should be set for your platform.

The library has its own parallel generation strategy. Our goal is to use Honggfuzz for crash logging and potentially other features. To do this without having to write custom orchestration logic to periodically halt fuzzing to repopulate a corpus, we use the custom mutation framework to simply overwrite an existing example with a new one (see `mutate_cmd` in [fuzz.sh](./fuzz.sh)). This is clunky and has high overhead. There is also a race condition that triggers infrequently with good parameters (too many Honggfuzz threads will lead to more errors). We use two mechanisms to deal with this: 
1) We generate a large initial corpus (8192 examples, total size approximately 4GB). This resolves most false positives. 
2) We filter out errors due to this race condition by listing the corresponding call stack hash in [.crashignore](./.crashignore). Crashes with that call stack hash are still under `blocklist`, but the crashes are not saved.

# Future work
Many improvements are possible here. Among those are: coverage measurement; use of "persistent mode"; changes to Cascade to make it more friendly to the sort of parallelism we use; stripping away of unneeded parts of Cascade; a more optimized rewrite of the Cascade generator; augmentation of the generation to support coverage guidance (the randomness in the test binaries could be surfaced to allow the fuzzer to drive example generation in a continuous way).

Possible extensions of course involve running the fuzzer on more targets and extending the execution to include proof construction and verification.
