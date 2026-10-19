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
