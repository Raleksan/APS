#!/usr/bin/env bash
# Lab 11: processor_system with interrupts and the provided testbench; check build/wave.fst manually
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir build
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
lab7="../07. Datapath"
cp program.mem build/
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
verilator --binary --timing --trace-fst --assert -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir "$obj" -o sim \
  "$lab7/alu_opcodes_pkg.sv" "../10. Interrupt subsystem/csr_pkg.sv" "$lab7/decoder_pkg.sv" "$lab7/memory_pkg.sv" \
  "../02. Arithmetic-logic unit/alu.sv" "../03. Register file and memory/register_file.sv" \
  "../03. Register file and memory/instr_mem.sv" "../05. Main decoder/decoder.sv" "../06. Main memory/data_mem.sv" \
  "../08. Load-store unit/lsu.sv" "../10. Interrupt subsystem/csr_controller.sv" \
  "../10. Interrupt subsystem/interrupt_controller.sv" processor_core.sv processor_system.sv \
  lab_11.tb_processor_system.sv build/dump.sv > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }
(cd build && "$obj/sim")
