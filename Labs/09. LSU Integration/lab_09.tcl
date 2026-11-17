# Lab 09 (LSU integration) in Vivado non-project mode.
#
#   GUI:   vivado -mode gui   -source lab_09.tcl -tclargs sim
#   batch: vivado -mode batch -source lab_09.tcl -tclargs check sim
#
# With no stages the script only reads the sources.
# Stages:
#   check - xvlog syntax check + RTL elaboration of processor_system
#   sim   - xsim run of lab 7's lab_07_tb_processor_system, waves in build/sim/tb.wdb
# No synth stage: the lab is not run on the board.
# Everything goes to build/ next to this script.

set lab   [file normalize [file dirname [info script]]]
set labs  [file dirname $lab]
set lab7  [file join $labs "07. Datapath"]
set build [file join $lab build]
set part  xc7a100tcsg324-1

set stages $argv
set gui    [expr {$rdi::mode eq "gui"}]

# Packages first: the order matters for xvlog.
# The lab has only processor_system: the core, testbench and program are lab 7's.
# decoder_pkg is lab 5's, see lab_07.tcl for why.
set rtl [list \
  [file join $lab7 alu_opcodes_pkg.sv] \
  [file join $lab7 csr_pkg.sv] \
  [file join $labs "05. Main decoder"            decoder_pkg.sv] \
  [file join $lab7 memory_pkg.sv] \
  [file join $labs "02. Arithmetic-logic unit"   alu.sv] \
  [file join $labs "03. Register file and memory" register_file.sv] \
  [file join $labs "03. Register file and memory" instr_mem.sv] \
  [file join $labs "05. Main decoder"            decoder.sv] \
  [file join $labs "06. Main memory"             data_mem.sv] \
  [file join $labs "08. Load-store unit"         lsu.sv] \
  [file join $lab7 processor_core.sv] \
  [file join $lab  processor_system.sv] \
]
set tb  [file join $lab7 lab_07.tb_processor_system.sv]
set mem [file join $lab7 program.mem]

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
  global rtl mem
  read_verilog -sv $rtl
  # Paths contain spaces: pass them as one-element lists, or Vivado splits them.
  read_mem [list $mem]
}

if {![llength $stages]} {
  load_rtl
  puts "sources loaded, part: $part"
}

if {"check" in $stages} {
  puts "=== check: syntax (xvlog) ==="
  set d [file join $build check]
  file mkdir $d
  xtool $d xvlog -sv {*}$rtl $tb

  puts "=== check: elaboration of processor_system ==="
  close_project -quiet
  load_rtl
  synth_design -rtl -top processor_system -part $part
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
  # Vivado non-project mode cannot show waves, open them in a separate xsim GUI.
  if {$gui} { exec sh -c "cd '$d' && xsim tb.wdb -gui" & }
}
