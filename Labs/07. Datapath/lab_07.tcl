# Lab 07 (RISC-V datapath) in Vivado non-project mode.
#
#   GUI:   vivado -mode gui   -source lab_07.tcl -tclargs sim
#   batch: vivado -mode batch -source lab_07.tcl -tclargs check sim synth
#
# With no stages the script only reads the sources, so you can run
# e.g. `synth_design -top nexys_processor_system -part $part` from the Tcl console.
# Stages:
#   check - xvlog syntax check + RTL elaboration of the board top
#   sim   - xsim run of lab_07_tb_processor_system, waves in build/sim/tb.wdb
#   synth - synthesis for Nexys A7-100T, reports in build/synth
# Everything goes to build/ next to this script.

set lab   [file normalize [file dirname [info script]]]
set labs  [file dirname $lab]
set build [file join $lab build]
set part  xc7a100tcsg324-1

set stages $argv
set gui    [expr {$rdi::mode eq "gui"}]

# Packages (this lab's copies) first: the order matters for xvlog.
# Modules come from the labs where they were written.
# decoder_pkg is lab 5's: this lab's `export alu_opcodes_pkg::*` re-exports
# nothing in xvlog (only used names are exported), so decoder.sv misses ALU_*.
set rtl [list \
  [file join $lab  alu_opcodes_pkg.sv] \
  [file join $lab  csr_pkg.sv] \
  [file join $labs "05. Main decoder"            decoder_pkg.sv] \
  [file join $lab  memory_pkg.sv] \
  [file join $labs "02. Arithmetic-logic unit"   alu.sv] \
  [file join $labs "03. Register file and memory" register_file.sv] \
  [file join $labs "03. Register file and memory" instr_mem.sv] \
  [file join $labs "05. Main decoder"            decoder.sv] \
  [file join $labs "06. Main memory"             data_mem.sv] \
  [file join $lab  processor_core.sv] \
  [file join $lab  processor_system.sv] \
]
set board [file join $lab "board files" nexys_riscv_unit.sv]
set xdc   [file join $lab "board files" nexys_a7_100t.xdc]
set tb    [file join $lab lab_07.tb_processor_system.sv]
set mem   [file join $lab program.mem]

file mkdir $build

# Run an xsim tool from dir, echo its output, fail the stage on error.
proc xtool {dir args} {
  set cwd [pwd]
  cd $dir
  set rc [catch {exec {*}$args 2>@1} out]
  cd $cwd
  puts $out
  if {$rc} { error "[lindex $args 0] failed, see [file join $dir [lindex $args 0].log]" }
}

proc load_rtl {} {
  global rtl board xdc mem
  read_verilog -sv [concat $rtl [list $board]]
  # Paths contain spaces: pass them as one-element lists, or Vivado splits them.
  read_mem [list $mem]
  read_xdc [list $xdc]
}

if {![llength $stages]} {
  load_rtl
  puts "sources loaded, part: $part"
}

if {"check" in $stages} {
  puts "=== check: syntax (xvlog) ==="
  set d [file join $build check]
  file mkdir $d
  xtool $d xvlog -sv {*}$rtl $board $tb

  puts "=== check: elaboration of nexys_processor_system ==="
  close_project -quiet
  load_rtl
  synth_design -rtl -top nexys_processor_system -part $part
  # Multi-driven nets, latches, width mismatches show up here.
  report_methodology -file [file join $d methodology.rpt]
  set w [get_msg_config -count -severity {CRITICAL WARNING}]
  puts "critical warnings so far: $w"
}

if {"sim" in $stages} {
  puts "=== sim: lab_07_tb_processor_system ==="
  set d [file join $build sim]
  file mkdir $d
  # $readmemh("program.mem") is resolved from the xsim working dir.
  file copy -force $mem $d
  xtool $d xvlog -sv {*}$rtl $tb
  xtool $d xelab -debug typical -top lab_07_tb_processor_system -snapshot tb
  set f [open [file join $d run.tcl] w]
  puts $f "log_wave -recursive *\nrun all\nquit"
  close $f
  xtool $d xsim tb -wdb tb.wdb -tclbatch run.tcl
  puts "waves: [file join $d tb.wdb]"
  # Look at the waves: open in a separate xsim GUI, Vivado non-project mode cannot show them.
  if {$gui} { exec sh -c "cd '$d' && xsim tb.wdb -gui" & }
}

if {"synth" in $stages} {
  puts "=== synth: nexys_processor_system on $part ==="
  set d [file join $build synth]
  file mkdir $d
  close_project -quiet
  load_rtl
  synth_design -top nexys_processor_system -part $part
  write_checkpoint -force [file join $d post_synth.dcp]
  report_utilization    -file [file join $d utilization.rpt]
  report_timing_summary -file [file join $d timing.rpt]
  report_drc            -file [file join $d drc.rpt]
  report_utilization
}
