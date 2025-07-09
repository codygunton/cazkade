#!/bin/bash
set -o pipefail

# Reexecute the crahes on more threads. Will show which crashes resulted from a timeout.
# Maybe we could use the built-in validation step in honggfuzz, but idk if you can
# adjust parameters like timeout length or thread count.

# Check if crashes directory exists
if [ ! -d "./crashes" ]; then
  echo "Error: ./crashes directory not found"
  exit 1
fi

# Iterate through all files in ./crashes
for file in ./crashes/*; do
  # Check if it's a regular file (not a directory)
  if [ -f "$file" ]; then
    # Print the filename
    echo "Processing: $(basename "$file")"

    # Execute r0vm --test-elf on the file
    /workspace/risc0/target/release/r0vm --test-elf "$file"
    exit_code=$?

    # Check if it panicked (SIGABRT = exit code 134)
    if [ $exit_code -eq 134 ]; then
      echo "*** PANIC DETECTED ***"
    elif [ $exit_code -eq 0 ]; then
      echo "Execution finished cleanly ✓"
    fi

    # Optional: Add a separator between files for clarity
    echo "----------------------------------------"
  fi
done
