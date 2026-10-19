#!/usr/bin/env bash
# Lab 4: CYBERcobra with the provided testbench; check build/wave.fst manually
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
cp program.mem build/
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
lab2="../02. Arithmetic-logic unit"
lab3="../03. Register file and memory"
verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  "$lab2/alu_opcodes_pkg.sv" "$lab3/memory_pkg.sv" \
  "$lab2/alu.sv" "$lab3/instr_mem.sv" "$lab3/register_file.sv" "../Made-up modules/lab_01.fulladder32.sv" \
  cybercobra.sv lab_04.tb_cybercobra.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
