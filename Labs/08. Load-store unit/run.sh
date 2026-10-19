#!/usr/bin/env bash
# Lab 8: lsu vs the Made-up reference; waveform in build/wave.fst
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
pkg="../05. Main decoder"
sed -E '0,/^module lsu\b/s//module lsu_ref/' "../Made-up modules/lab_08.lsu.sv" > build/lsu_ref.sv
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  "$pkg/alu_opcodes_pkg.sv" "$pkg/csr_pkg.sv" "$pkg/decoder_pkg.sv" \
  lsu.sv build/lsu_ref.sv tb_lsu_vs_ref.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
