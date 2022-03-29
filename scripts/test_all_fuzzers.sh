#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/.."

# TODO: This should be rewritten in rust, a Makefile, or some platform-independent language

# restore timestamp of file and dir by git history
rev=HEAD
for f in $(git ls-tree -r -t --full-name --name-only "$rev") ; do
     touch -t $(git log --pretty=format:%cd --date=format:%Y%m%d%H%M.%S -1 "$rev" -- "$f") "$f"; 
done

# list fuzzers by time
fuzzers=$(ls -dt fuzzers/*/)
backtrace_fuzzers=$(find ./fuzzers/backtrace_baby_fuzzers -maxdepth 1 -type d)
extra_fuzzer_and_runtime="
./fuzzers/libfuzzer_stb_image_concolic/runtime
./fuzzers/libfuzzer_stb_image_concolic/fuzzer
"

libafl=$(pwd)

for fuzzer in $(echo $fuzzers $backtrace_fuzzers $extra_fuzzer_and_runtime);
do
    cd $fuzzer
    # Clippy checks
    if [ "$1" != "--no-fmt" ]; then
        
        echo "[*] Checking fmt for $fuzzer"
        cargo fmt --all -- --check || exit 1
        echo "[*] Running clippy for $fuzzer"
        cargo clippy || exit 1
    else
        echo "[+] Skipping fmt and clippy for $fuzzer (--no-fmt specified)"
    fi

    if [ -e ./Makefile.toml ]; then
        echo "[*] Testing $fuzzer"
        cargo make test || exit 1
	    echo "[+] Done testing $fuzzer"
    else
        echo "[*] Building $fuzzer"
        cargo build || exit 1
        echo "[+] Done building $fuzzer"
    fi

    # Save disk space
    cargo clean
    cd $libafl
    echo ""
done
