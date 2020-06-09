# call each time on activating this package
using Revise

##  for Travis - must be a better way ...
if ! ( "src/" in LOAD_PATH )
    push!( LOAD_PATH, "src/")
#    push!( LOAD_PATH, "../src/")
end
