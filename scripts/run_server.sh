#!/bin/sh
cd $STB_HOME
# --procs=auto
$JULIA/bin/julia --startup-file=yes src/web/server.jl
