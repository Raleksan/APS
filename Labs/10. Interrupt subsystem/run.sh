#!/usr/bin/env bash
# Lab 10: csr_controller and interrupt_controller vs the Made-up references;
# waveforms in build/csr/wave.fst and build/irq/wave.fst
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")"
rm -rf build && mkdir -p build/csr build/irq
obj=$(mktemp -d)  # Verilator's make cannot build under paths with spaces
trap 'rm -rf "$obj"' EXIT
sed -E '0,/^module csr_controller\b/s//module csr_controller_ref/' "../Made-up modules/lab_10.csr.sv" > build/csr_controller_ref.sv
sed -E '0,/^module interrupt_controller\b/s//module interrupt_controller_ref/' "../Made-up modules/lab_10.irq.sv" > build/interrupt_controller_ref.sv
echo 'module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule' > build/dump.sv
flags=(--binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0)
verilator "${flags[@]}" --Mdir "$obj/csr" -o sim \
  csr_pkg.sv csr_controller.sv build/csr_controller_ref.sv tb_csr_vs_ref.sv build/dump.sv \
  > build/csr/verilator.log 2>&1 || { cat build/csr/verilator.log; exit 1; }
verilator "${flags[@]}" --Mdir "$obj/irq" -o sim \
  interrupt_controller.sv build/interrupt_controller_ref.sv tb_irq_vs_ref.sv build/dump.sv \
  > build/irq/verilator.log 2>&1 || { cat build/irq/verilator.log; exit 1; }
(cd build/csr && "$obj/csr/sim")
(cd build/irq && "$obj/irq/sim")
