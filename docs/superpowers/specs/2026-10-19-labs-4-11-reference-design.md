# Reference solutions: APS labs 4–11

## Intent

Reference answers for the MIET APS RISC-V course labs 4, 5, 6, 7, 8, 9, 10, 11.
Labs 2–3 are already solved in place (e.g. `Labs/02. Arithmetic-logic unit/alu.sv`); continue that pattern.

## Goals

- One synthesizable SystemVerilog solution per lab, written exactly to the interface, names and behaviour its `README.md` specifies.
- Each lab passes its provided testbench (`lab_NN.tb_*.sv`) in simulation.
- A small `run.sh` in each lab folder (4–11) that simulates that lab's testbench and dumps an FST waveform.

## Non-goals

- Lab 4 individual task (CYBERcobra program per variant) — processor only.
- FPGA/board flow (`board files/`), Vivado projects.
- Lab 1 and labs 12+.
- Changing provided files (testbenches, `*_pkg.sv`, `program.mem`, READMEs).

## Anti-goals

- Using `Made-up modules/*` (obfuscated netlists) inside the solutions — every dependency comes from our own solved labs.
- Behaviour that passes the testbench but deviates from the README (students compare against this).

## Constraints

- Branch: `labs-4-11-reference` (from `master_aps`). Git needs `-c safe.directory=<repo>` (dubious-ownership error); do not change global git config.
- Tools available: Verilator and iverilog (`~/oss-cad-suite`), `wavepeek`, `codex`. No Vivado.
- Some testbenches are not self-checking (labs 4, 7, 9, 11: README says verify clock by clock against the program listing; lab 11 uses listing 1 of lab 10). For those, check the waveform manually, clock by clock against the listing (using `wavepeek` to read it), and record the result in that lab's commit message (my call). Lab 11 must get this manual check — a clean run is not a pass.

## Decided

- Solutions live in each lab's own folder, file names as the README names the modules (e.g. `cybercobra.sv` already exists empty in lab 4).
- Later labs reuse earlier solutions by referencing the files in earlier lab folders, not by copying (my call — keep one source of truth; each lab's `run.sh` lists the files).
- Lab 9 and lab 11 modify `processor_system`/`processor_core`. Each lab folder holds its own version of the changed top-level files, so labs 7, 9, 11 each still simulate as their README describes (my call).
- Per-lab `run.sh` (user's decision): plain bash, no shared helper. Verilator `--binary --timing --trace-fst` (iverilog's SV support is too weak for these testbenches) (my call). Run from the lab folder: `./run.sh`; writes the waveform into a build dir ignored by git.
- Implementation runs through the claudex loop: plan → Codex review → build → cross-inspection.

## Left to the builder

- Exact file list in each `run.sh`. Lab 9 has no testbench of its own: its `run.sh` uses lab 9's `processor_system` with lab 7's testbench and `program.mem` (as its README says).
- Package copies (`*_pkg.sv`) differ between lab folders only in whitespace and export style; each lab compiles against its own folder's copies.
- Commit granularity (suggest one commit per lab, matching existing `Lab N: ...` messages).
- Whether lab 3's existing files need fixes discovered while integrating (fix if the testbench of a later lab exposes a real bug; note it).
