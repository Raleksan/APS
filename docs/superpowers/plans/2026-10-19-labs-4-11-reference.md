# Labs 4–11 Reference Solutions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reference SystemVerilog solutions for APS labs 4–11, each with a `run.sh` that simulates it in Verilator and dumps an FST waveform.

**Architecture:** One solution per lab folder, written to that lab's `README.md`. Later labs compile earlier labs' files in place (no copies). Labs 5/6/8/10 are checked by new compare-testbenches against the obfuscated `Made-up modules/` references; labs 4/7/9/11 by a manual, clock-by-clock waveform check of the provided testbench run.

**Tech Stack:** SystemVerilog, Verilator 5.037 (`~/oss-cad-suite/bin`), `wavepeek`, bash.

**Spec:** `docs/superpowers/specs/2026-10-19-labs-4-11-reference-design.md`

## Global Constraints

- Never edit provided files: `lab_NN.tb_*.sv`, `*_pkg.sv`, `program.mem`, `README.md`, `Made-up modules/*`, `board files/*`.
- No `Made-up modules/*` inside solutions, except `Made-up modules/lab_01.fulladder32.sv` in lab 4.
- Module/port/instance names exactly as the lab README states (they are case-sensitive: `CYBERcobra`).
- Git: always `git -c safe.directory="$REPO" ...`; never change global git config. Commit messages `Lab N: ...` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Every `run.sh`: plain bash, no shared helper, `set -euo pipefail`, runs from its own folder, builds into `./build/`, exits non-zero on build failure or test failure.
- Simulator command (verified in this session on the lab 10 irq tb): `verilator --binary --timing --trace-fst -Wno-fatal -Wno-lint -Wno-style -Wno-MULTITOP -j 0 --Mdir build -o sim <files…> build/dump.sv`, with **no** `--top-module`. `run.sh` first writes `build/dump.sv` = `module dump; initial begin $dumpfile("wave.fst"); $dumpvars; end endmodule`; Verilator treats it as a second top and dumps the whole design. Run `./sim` with `build/` as cwd; the waveform is `build/wave.fst`. Testbench files are never edited to add dumping.
- The simulation binary runs with `build/` as cwd; `run.sh` copies the needed `program.mem` into `build/` first (`$readmemh("program.mem")` is cwd-relative).

- Individual-assignment programs (lab 4 and lab 7 step 6) are out of scope.

## Review Focus

1. Outputs that are X/don't-care in the reference (e.g. decoder outputs on illegal instructions, `read_data_o` when `mem_req_i=0`): a compare-tb that uses `!==` blindly will fail on legitimate don't-cares — mask only what the README says is unspecified, and cite the README line in a comment.
2. Reset/first-cycle behaviour: compare-tbs must hold reset long enough for both DUT and reference to leave X state before comparing.
3. Misaligned/odd addresses and every `mem_size` (B/H/W/BU/HU) in the LSU and data memory, including the top address of `DATA_MEM_SIZE_WORDS`.
4. Back-to-back memory instructions and stall timing in labs 7/9 (the lab 7 tb asserts `stall` rises with `mem_req` and falls exactly one cycle later).
5. Interrupt arriving while a trap/`mret` is in flight, and `mie` masking, in lab 10 irq and lab 11 integration.

Each line above is pinned by a directed case in the owning task's compare-tb (Tasks 2, 3, 5, 7) or by a waveform checkpoint (Tasks 4, 6, 8).

---

### Task 0: Ignore build dirs; repair the lab 3 register file

Codex review R1: `Labs/03. Register file and memory/register_file.sv` assigns `read_data1_o` twice (line 31, `read_data2_o` undriven) and allows writes to x0 (line 25). Labs 4, 7, 9, 11 depend on it. The official lab 3 tb fails even against the Made-up reference under Verilator, so verify with a compare-tb.

**Files:**
- Create: `.gitignore` (line `Labs/*/build/`)
- Modify: `Labs/03. Register file and memory/register_file.sv:23-32`
- Create: `Labs/03. Register file and memory/tb_register_file_vs_ref.sv`, `Labs/03. Register file and memory/run.sh`

- [ ] **Step 1:** Write `.gitignore`.
- [ ] **Step 2:** Compare-tb (Task 2 shape, clocked): our `register_file` vs `register_file_ref` (renamed copy of `../Made-up modules/lab_03.register_file.sv`). Directed: write then read every register on both ports with distinct `read_addr1_i != read_addr2_i`, write to x0 then read x0 on both ports (expect 0), `write_enable_i=0` writes; then 10 000 random cycles. Compare both read outputs every cycle.
- [ ] **Step 3:** Ref-vs-ref sanity → `PASS`; current code → `FAIL` (proves the tb catches R1).
- [ ] **Step 4:** Fix: line 31 → `read_data2_o = rf_mem[read_addr2_i];`; writes only when `write_enable_i && write_addr_i != 0` (keep the zero-init `initial` block so x0 reads 0).
- [ ] **Step 5:** `./run.sh` → `PASS`.
- [ ] **Step 6:** Commit `.gitignore` and the lab 3 files as `Lab 3: fix register file read port 2 and x0 writes`.

### Task 1: Lab 4 — CYBERcobra

**Files:**
- Modify: `Labs/04. Primitive programmable device/cybercobra.sv` (empty now)
- Create: `Labs/04. Primitive programmable device/run.sh`

**Interfaces:**
- Consumes: `Labs/02. Arithmetic-logic unit/{alu_opcodes_pkg.sv,alu.sv}` (`alu(a_i,b_i,alu_op_i,flag_o,result_o)`), `Labs/03. Register file and memory/{memory_pkg.sv,instr_mem.sv,register_file.sv}`, `Made-up modules/lab_01.fulladder32.sv` (`fulladder32(a_i,b_i,carry_i,sum_o,carry_o)`).
- Produces: `module CYBERcobra(input clk_i, rst_i, input [15:0] sw_i, output [31:0] out_o)`; instr memory instance named `imem`.

- [ ] **Step 1:** Write `run.sh`: copy `program.mem` to `build/`, compile the files above + `lab_04.tb_cybercobra.sv` (top `lab_04_tb_CYBERcobra`), run.
- [ ] **Step 2:** `./run.sh` → expected: build fails (`CYBERcobra` not found).
- [ ] **Step 3:** Implement `CYBERcobra` per README "Архитектура CYBERcobra 3000 Pro 2.1" and "Задание": PC register reset on `rst_i`, adder carry-in tied to 0, PC increment select, `gpr_we`, write-back mux (const / sw_i / ALU), `out_o` per README.
- [ ] **Step 4:** `./run.sh` → expected: prints `The test is over.`, exit 0, `build/wave.fst` exists.
- [ ] **Step 5:** Manual check with `wavepeek`: decode `program.mem` (Listing 1 in README) and for each executed instruction confirm PC, the register written and its value, and the next PC, clock by clock, until the program loops. Note `sw_i` value from the tb run.
- [ ] **Step 6:** Commit `Lab 4: CYBERcobra` with the checked trace summary (instr count checked, any deviation) in the message body.

### Task 2: Lab 5 — main decoder

**Files:**
- Create: `Labs/05. Main decoder/decoder.sv`, `Labs/05. Main decoder/tb_decoder_vs_ref.sv`, `Labs/05. Main decoder/run.sh`

**Interfaces:**
- Consumes: lab 5 folder packages `alu_opcodes_pkg.sv csr_pkg.sv decoder_pkg.sv` (that order).
- Produces: `module decoder` with the 16 ports exactly as in README (`fetched_instr_i` … `mret_o`), `import decoder_pkg::*;`.

- [ ] **Step 1:** Write `tb_decoder_vs_ref.sv` (top `tb_decoder_vs_ref`): instantiates `decoder dut(...)` and `decoder_ref gold(...)` (`ref` is a reserved word), drives `fetched_instr_i`; after each drive waits `#1` and compares `illegal_instr_o` always and every other output with `!==` under exactly the official masks in `lab_05.tb_decoder.sv:441-456` (e.g. `a_sel/b_sel/alu_op` only when opcode ∉ {MISC_MEM, SYSTEM}; `csr_op` only on SYSTEM with func3≠0; `mem_size` only on LOAD/STORE; `wb_sel` per line 451). Stimulus: one directed instruction per RV32I/Zicsr/`mret`/`ecall`/`ebreak`/`fence` encoding the README tables list, every opcode with low bits `!= 2'b11`, every unused opcode, random funct3/funct7 per opcode, then 100 000 random words. Ends with `$display("PASS")` or `$fatal(1, "FAIL: %0d mismatches")`; prints the first 10 mismatches with instr and signal name.
- [ ] **Step 2:** Write `run.sh`: `sed -E '0,/^module decoder\b/s//module decoder_ref/' "../Made-up modules/lab_05.decoder.sv" > build/decoder_ref.sv`, compile packages + `decoder.sv` + `build/decoder_ref.sv` + tb, run.
- [ ] **Step 3:** Sanity-check the tb itself: temporarily point the DUT file list at a second renamed copy of the reference (`decoder` from Made-up) → expected `PASS`. Then restore.
- [ ] **Step 4:** Implement `decoder.sv` per README (all tables, illegal-instruction rules, `csr_op`, `mem_size`).
- [ ] **Step 5:** `./run.sh` → expected `PASS`, exit 0.
- [ ] **Step 6:** Commit `Lab 5: decoder`.

### Task 3: Lab 6 — data memory

**Files:**
- Create: `Labs/06. Main memory/data_mem.sv`, `tb_data_mem_vs_ref.sv`, `run.sh` (same folder)

**Interfaces:**
- Produces: `module data_mem` with the README ports; storage array named `ram` (`logic [31:0] ram [DATA_MEM_SIZE_WORDS]`); `import memory_pkg::DATA_MEM_SIZE_BYTES; import memory_pkg::DATA_MEM_SIZE_WORDS;` as in README.

- [ ] **Step 1:** Compare-tb (same shape as Task 2, clocked): random and directed reads/writes with every `byte_enable_i` value, `mem_req_i=0` cycles, write without req, addresses 0, last word, and beyond size (wrap per README), comparing `read_data_o` and `ready_o` every cycle after `@(posedge clk)` + `#1` (mask `read_data_o` only where README says it is undefined).
- [ ] **Step 2:** `run.sh` with the renamed `data_mem_ref` (from `../Made-up modules/lab_06.data_mem.sv`), memory_pkg from this folder.
- [ ] **Step 3:** Ref-vs-ref sanity run → `PASS`.
- [ ] **Step 4:** Implement `data_mem.sv` per README (synchronous read, byte-enable writes, `ready_o`).
- [ ] **Step 5:** `./run.sh` → `PASS`.
- [ ] **Step 6:** Commit `Lab 6: data memory`.

### Task 4: Lab 7 — datapath

**Files:**
- Create: `Labs/07. Datapath/processor_core.sv`, `Labs/07. Datapath/processor_system.sv`, `Labs/07. Datapath/run.sh`

**Interfaces:**
- Consumes: `alu` (lab 2), `register_file`, `instr_mem` (lab 3), `decoder` (Task 2), `data_mem` (Task 3); packages from the lab 7 folder.
- Produces: `processor_core` (11 ports as in lab 7 README) and `processor_system(clk_i, rst_i)` with the core instance named `core` (tb references `DUT.core.*`); stall logic in `processor_system` per README.

- [ ] **Step 1:** `run.sh`: copy lab 7 `program.mem` into `build/`, compile, run `lab_07_tb_processor_system`.
- [ ] **Step 2:** `./run.sh` → build fails (modules missing).
- [ ] **Step 3:** Implement both modules per README "Микроархитектура" and "Задание" (PC logic incl. branch/jal/jalr, immediates I/S/B/U/J, write-back mux, stall register).
- [ ] **Step 4:** `./run.sh` → `The test is over`, exit 0, no `incorrect implementation of stall` / `stall must fall` errors.
- [ ] **Step 5:** Manual check with `wavepeek` against README Listing 1 (instruction by instruction: PC, rd value, memory writes, stall cycles on loads/stores — Review Focus 4).
- [ ] **Step 6:** Commit `Lab 7: datapath` with the trace summary.

### Task 5: Lab 8 — LSU

**Files:**
- Create: `Labs/08. Load-store unit/lsu.sv`, `tb_lsu_vs_ref.sv`, `run.sh`

**Interfaces:**
- Consumes: packages `../05. Main decoder/alu_opcodes_pkg.sv`, `../05. Main decoder/csr_pkg.sv`, `../05. Main decoder/decoder_pkg.sv`, in that order (Made-up lsu imports `decoder_pkg`, which imports `alu_opcodes_pkg` and `csr_pkg` — Codex review R2).
- Produces: `module lsu` with the 18 README ports.

- [ ] **Step 1:** Compare-tb: drives core side and a behavioural memory model answering `mem_rd_i`/`mem_ready_i` (both always-ready and random-latency ready). Compare all `core_*_o` and `mem_*_o` outputs every cycle. Directed: every `core_size_i` (B, H, W, BU, HU) × every byte offset 0–3, loads and stores, back-to-back requests, reset mid-request (Review Focus 3/4).
- [ ] **Step 2:** `run.sh` with renamed `lsu_ref`.
- [ ] **Step 3:** Ref-vs-ref sanity → `PASS`.
- [ ] **Step 4:** Implement `lsu.sv` per README (byte-enable, write-data replication, read-data extension, stall FSM).
- [ ] **Step 5:** `./run.sh` → `PASS`.
- [ ] **Step 6:** Commit `Lab 8: LSU`.

### Task 6: Lab 9 — LSU integration

**Files:**
- Create: `Labs/09. LSU Integration/processor_system.sv`, `Labs/09. LSU Integration/run.sh`

**Interfaces:**
- Consumes: lab 7 `processor_core.sv` (unchanged), `lsu` (Task 5), `data_mem` (Task 3), lab 7 tb + `program.mem` + packages.
- Produces: `processor_system` with `lsu` and `data_mem` wired per lab 9 fig. 1; stall now from `lsu.core_stall_o`; core instance still `core`.

- [ ] **Step 1:** `run.sh` compiling lab 7 core + this folder's `processor_system.sv` + lab 7 tb; copies `../07. Datapath/program.mem`.
- [ ] **Step 2:** Implement `processor_system.sv`.
- [ ] **Step 3:** `./run.sh` → `The test is over`, exit 0, no stall assertion errors.
- [ ] **Step 4:** Manual `wavepeek` check of Listing 1, focusing on `sw/sh/sb/lw/lh/lb/lhu/lbu` (lab 9 README step 2.2).
- [ ] **Step 5:** Commit `Lab 9: LSU integration` with trace summary.

### Task 7: Lab 10 — CSR and interrupt controllers

**Files:**
- Create: `Labs/10. Interrupt subsystem/csr_controller.sv`, `interrupt_controller.sv`, `tb_csr_vs_ref.sv`, `tb_irq_vs_ref.sv`, `run.sh`

**Interfaces:**
- Produces: `csr_controller` (14 README ports, `import csr_pkg::*;`) and `interrupt_controller` (9 README ports).
- Consumes: Made-up references `lab_10.csr.sv` → `csr_controller_ref`, `lab_10.irq.sv` → `interrupt_controller_ref`.

- [ ] **Step 1:** `tb_csr_vs_ref.sv`: every CSR address in `csr_pkg` × every `opcode_i` (CSRRW/S/C and immediate forms), `write_enable_i` on/off, `trap_i` pulses with random `pc_i`/`mcause_i`, random cycles; compare all 4 outputs each cycle.
- [ ] **Step 2:** `tb_irq_vs_ref.sv`: all 32 combinations of `{exception_i, irq_req_i, mie_i, mret_i}` from each reachable state, irq during `mret`, random sequences (Review Focus 5); compare 3 outputs each cycle.
- [ ] **Step 3:** `run.sh` builds and runs both tbs (two `--Mdir`s: `build/csr`, `build/irq`); exits non-zero if either fails.
- [ ] **Step 4:** Ref-vs-ref sanity → both `PASS`.
- [ ] **Step 5:** Implement both modules per README.
- [ ] **Step 6:** `./run.sh` → both `PASS`.
- [ ] **Step 7:** Commit `Lab 10: CSR and interrupt controllers`.

### Task 8: Lab 11 — interrupt integration

**Files:**
- Create: `Labs/11. Interrupt integration/processor_core.sv`, `processor_system.sv`, `run.sh`

**Interfaces:**
- Consumes: `alu`, `register_file`, `instr_mem`, `decoder`, `data_mem`, `lsu`, `csr_controller`, `interrupt_controller`; packages from labs 7/10 folders (one copy each; csr_pkg from lab 10).
- Produces: `processor_core` (13 ports per lab 11 README), `processor_system` with signals named `irq_req` (driven only by the tb — leave undriven inside) and `irq_ret`, core instance `core`.

- [ ] **Step 1:** `run.sh` copying lab 11 `program.mem`, running `lab_11_tb_processor_system`.
- [ ] **Step 2:** Implement per lab 11 README (trap PC mux, mepc/mtvec, `illegal_instr` → exception, `mret`).
- [ ] **Step 3:** `./run.sh` → `The test is over`, exit 0, no watchdog `$fatal`.
- [ ] **Step 4:** Manual `wavepeek` check against lab 10 Listing 1: PC jumps to `mtvec` on `irq_req`, handler runs, `mret` returns to `mepc`, `irq_ret` pulses, illegal instruction trap if the program has one (Review Focus 5). A clean run alone is not a pass.
- [ ] **Step 5:** Commit `Lab 11: interrupt integration` with trace summary.
