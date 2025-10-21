#!/usr/bin/env bash
set -euo pipefail
sudo apt update
sudo apt install -y build-essential protobuf-compiler libprotobuf-dev \
                    libssl-dev zlib1g-dev libmagic-dev

make -j"$(nproc)" || true
make -C sdhash-src -j"$(nproc)" || true

if [[ ! -x ./sdhash && ! -x sdhash-src/sdhash ]]; then
  g++ -O3 -std=c++17 -fopenmp -o sdhash \
    sdhash-src/sdhash.o sdhash-src/sdhash_threads.o sdbf/blooms.pb.o libsdbf.a \
    -Lexternal/stage/lib \
    -lboost_program_options -lboost_system -lboost_filesystem -lboost_thread \
    -lprotobuf -lssl -lcrypto -lz -lmagic -ldl -pthread
fi

sudo install -m 755 ./sdhash /usr/local/bin/sdhash
sdhash -v
