# Lab 06 (data memory) in Vivado non-project mode.
#
#   GUI:   vivado -mode gui   -source lab_06.tcl -tclargs sim
#   batch: vivado -mode batch -source lab_06.tcl -tclargs check sim
#
# With no stages the script only reads the sources.
# Stages:
#   check - xvlog syntax check + RTL elaboration of data_mem (latches show up here)
#   sim   - xsim run of lab_06_tb_data_mem, waves in build/sim/tb.wdb
# No synth stage: the lab is not run on the board.
# Everything goes to build/ next to this script.

set lab   [file normalize [file dirname [info script]]]
set build [file join $lab build]
set part  xc7a100tcsg324-1

set stages $argv
set gui    [expr {$rdi::mode eq "gui"}]

# Packages first: the order matters for xvlog.
set rtl [list \
  [file join $lab memory_pkg.sv] \
  [file join $lab data_mem.sv] \
]
set tb [file join $lab lab_06.tb_data_mem.sv]

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
  global rtl
  read_verilog -sv $rtl
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

  puts "=== check: elaboration of data_mem ==="
  close_project -quiet
  load_rtl
  synth_design -rtl -top data_mem -part $part
  report_methodology -file [file join $d methodology.rpt]
  set w [get_msg_config -count -severity {CRITICAL WARNING}]
  puts "critical warnings so far: $w"
}

if {"sim" in $stages} {
  puts "=== sim: lab_06_tb_data_mem ==="
  set d [file join $build sim]
  file mkdir $d
  xtool $d xvlog -sv {*}$rtl $tb
  xtool $d xelab -debug typical -top lab_06_tb_data_mem -snapshot tb
  set f [open [file join $d run.tcl] w]
  puts $f "log_wave -recursive *\nrun all\nquit"
  close $f
  xtool $d xsim tb -wdb tb.wdb -tclbatch run.tcl
  puts "waves: [file join $d tb.wdb]"
  # Vivado non-project mode cannot show waves, open them in a separate xsim GUI.
  if {$gui} { exec sh -c "cd '$d' && xsim tb.wdb -gui" & }
}
