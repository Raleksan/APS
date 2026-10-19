#!/usr/bin/env bash
# Lab 6: data_mem vs the Made-up reference; waveform in build/wave.fst
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
sed -E '0,/^module data_mem\b/s//module data_mem_ref/' "../Made-up modules/lab_06.data_mem.sv" > build/data_mem_ref.sv
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  memory_pkg.sv data_mem.sv build/data_mem_ref.sv tb_data_mem_vs_ref.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
