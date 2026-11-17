# Lab 05 (instruction decoder) in Vivado non-project mode.
#
#   GUI:   vivado -mode gui   -source lab_05.tcl -tclargs sim
#   batch: vivado -mode batch -source lab_05.tcl -tclargs check sim
#
# With no stages the script only reads the sources.
# Stages:
#   check - xvlog syntax check + RTL elaboration of decoder (latches show up here)
#   sim   - xsim run of lab_05_tb_decoder, waves in build/sim/tb.wdb
# No synth stage: the lab is not run on the board.
# Everything goes to build/ next to this script.

set lab   [file normalize [file dirname [info script]]]
set build [file join $lab build]
set part  xc7a100tcsg324-1

set stages $argv
set gui    [expr {$rdi::mode eq "gui"}]

# Packages first: the order matters for xvlog.
set rtl [list \
  [file join $lab alu_opcodes_pkg.sv] \
  [file join $lab csr_pkg.sv] \
  [file join $lab decoder_pkg.sv] \
  [file join $lab decoder.sv] \
]
set tb [file join $lab lab_05.tb_decoder.sv]

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

  puts "=== check: elaboration of decoder ==="
  close_project -quiet
  load_rtl
  synth_design -rtl -top decoder -part $part
  report_methodology -file [file join $d methodology.rpt]
  set w [get_msg_config -count -severity {CRITICAL WARNING}]
  puts "critical warnings so far: $w"
}

if {"sim" in $stages} {
  puts "=== sim: lab_05_tb_decoder ==="
  set d [file join $build sim]
  file mkdir $d
  xtool $d xvlog -sv {*}$rtl $tb
  xtool $d xelab -debug typical -top lab_05_tb_decoder -snapshot tb
  set f [open [file join $d run.tcl] w]
  puts $f "log_wave -recursive *\nrun all\nquit"
  close $f
  xtool $d xsim tb -wdb tb.wdb -tclbatch run.tcl
  puts "waves: [file join $d tb.wdb]"
  # Vivado non-project mode cannot show waves, open them in a separate xsim GUI.
  if {$gui} { exec sh -c "cd '$d' && xsim tb.wdb -gui" & }
}
