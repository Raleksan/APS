# Claudex loop log — labs 4–11

- Host/planner: Claude (Opus 5.5, Claude Code). Plan reviewer: Codex CLI 0.162.1 (config default model gpt-6.1-sol, effort medium; no override requested). Builder: Claude. Inspector: fresh Codex session.
- Plan: docs/superpowers/plans/2026-10-19-labs-4-11-reference.md; spec: docs/superpowers/specs/2026-10-19-labs-4-11-reference-design.md
- Mode: review. Max plan rounds 5, fix rounds 2, inspection rounds 2. Inspection on.
- Authorization: user asked to "start implementation with claudex review" — build authorized after approval.
- Codex runs with CODEX_HOME = session scratch copy of ~/.codex/config.toml with [mcp_servers.*] (node_repl, write-capable) removed; global config untouched.

## Round 1 — Codex: REVISE (session 01a153f9-d534-7623-95fb-2060bbe57f26, artifacts /tmp/claude-1000/-home-raleksan-work-miet-cad-edu-work-APS/d48684c0-3185-4da2-b4fc-403f3ec46f8b/scratchpad/claudex/review1/claudex-dfs2qm8k)
- R1 (high) register_file.sv read port 2 undriven, x0 writable — ACCEPTED
- R2 (medium) lab 8 missing csr_pkg — ACCEPTED
Round 1 dispositions (host: Claude):
- R1 ACCEPTED. Verified register_file.sv:31 double-assigns read_data1_o and line 25 allows x0 writes. Also verified the official lab 3 tb fails even against the Made-up reference under Verilator ("invalid memory size", 2 errors), so it cannot verify the fix. New Task 0: fix + compare-tb vs Made-up register_file, with a must-FAIL-before-fix step.
- R2 ACCEPTED. Task 5 now compiles alu_opcodes_pkg, csr_pkg, decoder_pkg from lab 5 in that order.
- Also tightened Task 2: the decoder compare-tb uses exactly the official don't-care masks from lab_05.tb_decoder.sv:441-456. Added global note that individual-assignment programs (lab 4, lab 7 step 6) are out of scope.

## Round 2 — Codex: APPROVED (same session; plan sha256 c154501f…; artifacts /tmp/claude-1000/-home-raleksan-work-miet-cad-edu-work-APS/d48684c0-3185-4da2-b4fc-403f3ec46f8b/scratchpad/claudex/review2/claudex-7nudbb2p/result.json)
- No findings. Limitations: static review only.

## Build (host: Claude), base dfffcd5 → 7948c0d
- Tasks 0–8 implemented by Claude, one commit each; all run.sh scripts pass (labs 3,5,6,8,10 compare-tbs PASS; labs 4,7,9,11 waveforms checked manually, results in commit messages).
- Deviation: Verilator's make cannot build under paths with spaces, so each run.sh compiles in a mktemp dir and keeps sources/waveform in ./build.

## Inspection 1 — fresh Codex session 01a15433-8892-78c1-a6ba-a9e84f5da762: REVISE
Run on a local clone of the branch (sshfs checkout made the runner's 30 s git diff time out); same commits, base dfffcd5.
- R1 (high) lab 11 csr write_enable not gated by trap — REJECTED (no code change). Made-up modules/lab_11.riscv_core.sv (the course reference core) wires decoder csr_we straight to csr_controller.write_enable_i, as does README fig. 1. Changing it would make the reference answer deviate from the course design (spec anti-goal). Reported to the user as a course-design limitation.
- R2 (high) store interrupted in its second cycle is replayed after mret — REJECTED (no code change). Reproduced with an IRQ injected in the store's second cycle: our core and the Made-up reference core give identical core-boundary traces (wavepeek output_diff EQUAL, 95 rows); both write on the first edge and replay. Same reasoning as R1; reported to the user.
- No code changed after inspection, so no reinspection round was needed.
