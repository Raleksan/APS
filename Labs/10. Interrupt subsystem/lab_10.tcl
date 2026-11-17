# Lab 10 (interrupt subsystem) in Vivado non-project mode.
#
#   GUI:   vivado -mode gui   -source lab_10.tcl -tclargs sim
#   batch: vivado -mode batch -source lab_10.tcl -tclargs check sim
#
# With no stages the script only reads the sources.
# Stages:
#   check - xvlog syntax check + RTL elaboration of both modules (latches show up here)
#   sim   - xsim runs of lab_10_tb_csr and lab_10_tb_irq, waves in build/sim_{csr,irq}/tb.wdb
# No synth stage: the lab is not run on the board.
# Everything goes to build/ next to this script.

set lab   [file normalize [file dirname [info script]]]
set build [file join $lab build]
set part  xc7a100tcsg324-1

set stages $argv
set gui    [expr {$rdi::mode eq "gui"}]

# Packages first: the order matters for xvlog.
set rtl [list \
  [file join $lab csr_pkg.sv] \
  [file join $lab csr_controller.sv] \
  [file join $lab interrupt_controller.sv] \
]
# tb name, top module, run commands.
# lab_10_tb_csr does $stop at 0 ns waiting for 'Run All', so it is run twice.
set tbs {
  csr lab_10_tb_csr "run all\nrun all"
  irq lab_10_tb_irq "run all"
}

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
  xtool $d xvlog -sv {*}$rtl [file join $lab lab_10.tb_csr.sv] [file join $lab lab_10.tb_irq.sv]

  foreach top {csr_controller interrupt_controller} {
    puts "=== check: elaboration of $top ==="
    close_project -quiet
    load_rtl
    synth_design -rtl -top $top -part $part
    report_methodology -file [file join $d $top.methodology.rpt]
  }
  set w [get_msg_config -count -severity {CRITICAL WARNING}]
  puts "critical warnings so far: $w"
}

if {"sim" in $stages} {
  foreach {n top run} $tbs {
    puts "=== sim: $top ==="
    set d [file join $build sim_$n]
    file mkdir $d
    xtool $d xvlog -sv {*}$rtl [file join $lab lab_10.tb_$n.sv]
    xtool $d xelab -debug typical -top $top -snapshot tb
    set f [open [file join $d run.tcl] w]
    puts $f "log_wave -recursive *\n$run\nquit"
    close $f
    xtool $d xsim tb -wdb tb.wdb -tclbatch run.tcl
    puts "waves: [file join $d tb.wdb]"
    # Vivado non-project mode cannot show waves, open them in a separate xsim GUI.
    if {$gui} { exec sh -c "cd '$d' && xsim tb.wdb -gui" & }
  }
}
