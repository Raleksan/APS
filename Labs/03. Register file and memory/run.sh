#!/usr/bin/env bash
# Lab 3: register_file vs the Made-up reference; waveform in build/wave.fst
set -euo pipefail
ulimit -c 0  # $fatal aborts; no core files
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
sed -E '0,/^module register_file\b/s//module register_file_ref/' "../Made-up modules/lab_03.register_file.sv" > build/register_file_ref.sv
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  register_file.sv build/register_file_ref.sv tb_register_file_vs_ref.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
