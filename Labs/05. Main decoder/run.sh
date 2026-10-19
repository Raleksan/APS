#!/usr/bin/env bash
# Lab 5: decoder vs the Made-up reference; waveform in build/wave.fst
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
sed -E '0,/^module decoder\b/s//module decoder_ref/' "../Made-up modules/lab_05.decoder.sv" > build/decoder_ref.sv
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  alu_opcodes_pkg.sv csr_pkg.sv decoder_pkg.sv \
  decoder.sv build/decoder_ref.sv tb_decoder_vs_ref.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
