#!/usr/bin/env bash
set -Eeuo pipefail # be strict and fail fast

fd_path="$1" # /dev/fd/<n> from honggfuzz
export USER=$(whoami)
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}

# -------- generate a fresh ELF ----------
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pushd /workspace/cascade-meta >/dev/null
source env.sh
CASCADE_DATADIR="$tmpdir" CASCADE_JOBS=1 \
  python3 fuzzer/do_genmanyelfs.py 1 "$tmpdir" &>/dev/null
elf="$tmpdir/risc0_0.elf"

# -------- copy the bytes into the HF FD atomically ----------
exec {out_fd}>"$fd_path" # open the honggfuzz file once
dd if="$elf" of=/proc/self/fd/$out_fd bs=64k conv=fsync status=none
exec {out_fd}>&- # close and flush
