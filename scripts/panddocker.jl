using CSV
using DataFrames

STB_DIR="book/src/"
MD_DIR = "$STB_DIR/sections/"
BIB_FILE = "$STB_DIR/data/stb.bib"
META_FILE = "$STB_DIR/data/stb-metadata.yaml"
OUT_DIR = "book/build/"
INCLUDE_DIR = "web/includes/"
PANDOC_DIR = "/home/graham_s/pandoc_data/"
NullableString = Union{Missing,AbstractString}

const DEFAULT_OPTS = Dict(
    "data-dir"          => PANDOC_DIR,
    "css"               =>
            [
                "/css/stb.css"
            ],
    "include-in-header" => [ "$INCLUDE_DIR/stb-js-headers.html" ],
    "from"              => "markdown+yaml_metadata_block",
    "section-divs"      => true,
    "standalone"        => true,
    # "number-sections"   => true,
    "bibliography"      => BIB_FILE,
    "metadata-file"     => META_FILE,
    "default-image-extension"=>"svg",
    "csl"               => "$PANDOC_DIR/chicago-note-bibliography.csl",
    "to"                => "html5",
    # FIXME this is broken "filter"            => "pandoc-citeproc",
    "template"          => "$INCLUDE_DIR/stb-template.html"

);

function makeoptarray( opts :: Dict, format=missing ) :: AbstractArray
    out = []
    oldformat = opts["to"]
    if ! ismissing(format)
         opts["to"] = format
    end
    s = ""
    for (k,v) in opts
        if v === true
            v = ""
        end
        if length(k) == 1
            k = "-$k"
        else
            k = "--$k"
        end
        if ! (typeof( v ) <: Array)
            v = [v]
        end
        for ve in v
            push!( out, k )
            if ve !== ""
                push!( out, ve )
            end
        end
    end
    # opts["to"] = oldformat
    out
end

function addone(
    pos,
    count,
    title::String,
    output :: NullableString,
    form::NullableString,
    content::AbstractString,
    model::NullableString,
    prev_content::NullableString,
    next_content::NullableString )

    opts = deepcopy( DEFAULT_OPTS )
    includes = []
    if ! ismissing(form)
        push!( includes, "$(INCLUDE_DIR)/$(form).html" )
    end
    if ! ismissing(output)
        push!( includes, "$(INCLUDE_DIR)/$(output).html" )
    end
    if ! ismissing(model)
        opts["include-after-body"] = [ "$(INCLUDE_DIR)/run-$model-js.html" ]
    end
    # if pos > 1
    #     opts["number-offset"]=(pos-1)
    # end
    opts["include-before-body"] = includes
    opts["o"] = "$(OUT_DIR)$(content).html"
    # opts["metadata"] = "title:$title"
    links = []

    if ! ismissing( prev_content )
        push!( links, "prev:$(prev_content).html")
    end
    if ! ismissing( next_content )
        push!( links, "next:$(next_content).html")
    end
    opts["variable"] = links
    optsarr = makeoptarray( opts )

    push!(optsarr, "$(MD_DIR)$(content).md" )
    push!(optsarr, "$(MD_DIR)footnotes.md" )


    cmd=`/usr/bin/pandoc $optsarr`
    println( cmd )
    # println( cmd )
    run( `$cmd` )
end

df = CSV.File( "$INCLUDE_DIR/stb-files.csv") |> DataFrame

# addone( 1, 2, "Introduction",missing,missing,"intro",missing,missing)

npages = size( df )[1]
outfile = "/home/graham_s/tmp/alltext.md"
outf = open( outfile,"w")
wholething = ""
for i in 1:npages
    prev = missing
    if i > 1
        prev = df[i-1,:content]
    end
    next = missing
    if i < npages
        next = df[i+1,:content]
    end
    page = df[i,:]
    addone( i, npages, page.title, page.output, page.form, page.content, page.model, prev, next )

    filecont = read("$(MD_DIR)$(page.content).md")
    write( outf, "##$(page.title)\n\n")
    write( outf, filecont )
end

close( outf )
