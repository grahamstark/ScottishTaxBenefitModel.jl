#=

Bulk upload all the various ScotBen data artifacts.

Hacked stand-alone version made to defeat F**ING Windows Defender.
No dependency on ScottishTaxBenefitModel.jl itself since
we're in a chicken/egg situation where ScotBen won't load without data
but we normally can't create artifacts without Scotben.

So load data artifacts into `artifact_server_url` and the artifact
thingy takes it from there. Pointless but there we are ...

=#
using ArtifactUtils
using Artifacts

#
# In the main version these are all derived from the model &
# Project.toml. So we need to update these manually.
#
const version = v"0.1.7" # get_data_version() # pkgversion(ScottishTaxBenefitModel) # get_version()
const artifact_server_upload = "c:/data/" # @load_preference( "local-artifact_server_upload_windows" )
const artifact_server_url = "file:///c:/data/" # @load_preference( "local-artifact_server_url_windows" )
const is_windows = true

function get_artifact_name( artname :: String )::Tuple   
   osname = if is_windows
      "windows"
   else
      "unix"
   end
   # println( "got version as |$version|")
   return "$(artname)-$(osname)-v$(version)", "$(artname)-v$(version)"
end

"""
return something like "augdata-v0.13", or, if "SCOTBEN_DATA_DEVELOPING" is set as
an env variable, the directory we build the artifacts in. 
"""
function qualified_artifact( artname :: String )
   @artifact_str(get_artifact_name( artname ))
end

"""
Given a directory in the artifacts directory (jammed on to /mnt/data/ScotBen/artifacts/) 
with some data in it, make a gzipped tar file, upload this to a server 
defined in Project.toml and add an entry to `Artifacts.toml`. Artifact
is set to lazy load. Uses `ArtifactUtils`.

main data files should contain: `people.tab` `households.tab` `README.md`, all top-level
other files can contain anything.

"""
function make_artifact(;
   artifact_name :: AbstractString,
   toml_file = "Artifacts.toml" )::Int 
   full_artifact_name, filename = get_artifact_name( artifact_name )
   # version = Pkg.project().version
   gzip_file_name = "$(filename).tar.gz"
   dest = "$(artifact_server_upload)/$(gzip_file_name)"
   url = "$(artifact_server_url)/$gzip_file_name"
   try
      add_artifact!( toml_file, full_artifact_name, url; force=true, lazy=true )
   catch e 
      println( "ERROR UPLOADING $e")
      return -1
   end
   return 0
end

LOCALS = [
    "scottish-frs-data", 
    "scottish-shs-data",
    "scottish-slab-legalaid", 
    "scottish-lcf-expenditure", 
    "scottish-was-wealth",
    "uk-frs-data", 
    "uk-lcf-expenditure", 
    "uk-was-wealth"]

PUBLICS = [
    "scottish-synthetic-data",
    "scottish-synthetic-expenditure",
    "scottish-synthetic-legalaid",
    "scottish-synthetic-wealth",
    "scottish-was-wealth",
    "uk-synthetic-data",
    "uk-synthetic-expenditure",
    "uk-synthetic-wealth",
    "uk-was-wealth",
    "augdata",
    "disability",
    "example_data",
]

function upload_all()
    for is_windows in [false, true]
        for name in union(PUBLICS,LOCALS)
            is_local = true
            make_artifact( ; artifact_name=name )
        end
    end
end