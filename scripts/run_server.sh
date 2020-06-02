#!/bin/sh
cd $OU_HOME
# --procs=auto
$JULIA/bin/julia --startup-file=yes src/web/server.jl
# --optimize=3 --track-allocation=none --check-bounds=no --code-coverage=none  
