using Revise

pathfile = joinpath( pwd(), "etc", "extra_paths.jl" )
if isfile( pathfile )
    include( pathfile )
end


