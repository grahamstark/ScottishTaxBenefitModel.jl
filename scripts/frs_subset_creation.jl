#
# Stuff to read FRS and HBAI files into frames and merge them
# a lot of this is just to overcome the weird way I have these stored
# and would need adaption by anyone with a sensible layout who had all the
# files in the one format
#
using DataFrames
using StatFiles
using IterableTables
using IteratorInterfaceExtensions
using TableTraits
using CSV

global HBAI_DIR = "/mnt/data/hbai/UKDA-5828-stata11/stata11/"

global HBAIS = Dict(
        2015=>"hbai1516_g4.dta",
        2014=>"hbai1415_g4.dta",
        2013=>"hbai1314_g4.dta",
        2012=>"hbai1213_g4.dta",
        2011=>"hbai1112_g4.dta",
        2010=>"hbai1011_g4.dta",
        2009=>"hbai0910_g4.dta",
        2008=>"hbai0809_g4.dta",
        2007=>"hbai0708_g4.dta",
        2006=>"hbai0607_g4.dta",
        2005=>"hbai0506_g4.dta",
        2004=>"hbai0405_g4.dta",
        2003=>"hbai0304_g4.dta"
)

global FRS_DIR = "/mnt/data/frs/"
global DIRS = Dict(
        2015=>"/2015/UKDA-8171-stata11_se/stata11_se/",
        2014=>"/2014/UKDA-8013-stata11/stata11/",
        2013=>"/2013/UKDA-7753-stata11/stata11/",
        2012=>"/2012/UKDA-7556-stata11/stata11/",
        2011=>"/2011/UKDA-7368-stata9/stata9/",
        2010=>"/2010/UKDA-7085-spss/spss/spss14/",
        2009=>"/2009/UKDA-6886-spss/spss/spss14/",
        2008=>"/2008/tab/",
        2007=>"/2007/tab/",
        2006=>"/2006/tab/",
        2005=>"/2005/tab/",
        2004=>"/2004/tab/",
        2003=>"/2003/tab/"
)


function extn(year)
        if( year < 2011) && ( year > 2008)
                return ".sav"
        elseif( year <= 2008 )
                return ".tab"
        end
        ".dta"
end

function dfname( fname, year)
        string( FRS_DIR, DIRS[year],fname,extn(year))
end

function remapRegion( r :: Integer )
        if r == 112000001 # North East
                r = 1
        elseif r == 112000002 # North West
                r = 2
        # no region 3
        elseif r == 112000003 # Yorks and the Humber
                r = 4
        elseif r == 112000004 # East Midlands
                r = 5
        elseif r == 112000005 # West Midlands
                r = 6
        elseif r == 112000006
                r = 7  # East of England
        elseif r == 112000007 # | London
                r = 8
        elseif r == 112000008 # South East
                r = 9
        elseif r == 112000009 # South West
                r = 10
        elseif r == 399999999 #  wales
                r = 11
        elseif r == 299999999
                r = 12        # Scotland
        elseif r == 499999999 # Northern Ireland
                r = 13
        end
        return r
end

function initialiseMerged( n )

# .. example check
# select value,count(value),label from dictionaries.enums where dataset='frs' and tables='househol' and variable_name='hhcomps' group by value,label;

        merged = DataFrame(
                frs_year    = Vector{Union{Int64,Missing}}(missing,n),
                sernum  = Vector{Union{Int64,Missing}}(missing,n),
                benunit = Vector{Union{Int8,Missing}}(missing,n),
                person  = Vector{Union{Int8,Missing}}(missing,n),
                interview_year  = Vector{Union{Int64,Missing}}(missing,n),
                interview_month  = Vector{Union{Int8,Missing}}(missing,n),
                gvtregn  = Vector{Union{Int8,Missing}}(missing,n), # f reg change 2012
                tenure  = Vector{Union{Int8,Missing}}(missing,n), # f enums OK
                hhld_income = Vector{Union{Real,Missing}}(missing,n),
                gbhscost = Vector{Union{Real,Missing}}(missing,n),
                hhcomps = Vector{Union{Int8,Missing}}(missing,n), # full - check for differences (OK)
                num_children= Vector{Union{Int8,Missing}}(missing,n),
                num_adults = Vector{Union{Int8,Missing}}(missing,n),
                age_in_bands = Vector{Union{Int8,Missing}}(missing,n), # age80 - 2005-2012 ; iagegr2 full
                empstati = Vector{Union{Int8,Missing}}(missing,n),
                sex = Vector{Union{Int8,Missing}}(missing,n),     # full
                marital = Vector{Union{Int8,Missing}}(missing,n), # full
                ethgrp  = Vector{Union{Int8,Missing}}(missing,n), #
                ftwk =  Vector{Union{Int64,Missing}}(missing,n), #
                tea = Vector{Union{Int64,Missing}}(missing,n), #
                nssec = Vector{Union{Real,Missing}}(missing,n), # FIXME Really a Decimal
                hi2qual = Vector{Union{Int8,Missing}}(missing,n), # 2008-11
                sic = Vector{Union{Int64,Missing}}(missing,n),
                soc2010 = Vector{Union{Int64,Missing}}(missing,n),
                spcreg1 = Vector{Union{Int8,Missing}}(missing,n), # full years
                spcreg2 = Vector{Union{Int8,Missing}}(missing,n),
                spcreg3 = Vector{Union{Int8,Missing}}(missing,n),
                disdif1 = Vector{Union{Int8,Missing}}(missing,n), # 2003-11 only for these
                disdif2 = Vector{Union{Int8,Missing}}(missing,n),
                disdif3 = Vector{Union{Int8,Missing}}(missing,n),
                disdif4 = Vector{Union{Int8,Missing}}(missing,n),
                disdif5 = Vector{Union{Int8,Missing}}(missing,n),
                disdif6 = Vector{Union{Int8,Missing}}(missing,n),
                disdif7 = Vector{Union{Int8,Missing}}(missing,n),
                disdif8 = Vector{Union{Int8,Missing}}(missing,n),
                disdifp1 = Vector{Union{Int8,Missing}}(missing,n),
                hourcare = Vector{Union{Real,Missing}}(missing,n), # full

                #hourcb = Vector{Union{Real,Missing}}(missing,n), # full
                #hourch = Vector{Union{Real,Missing}}(missing,n), # full
                #hourcl = Vector{Union{Real,Missing}}(missing,n), # full
                #hourfr = Vector{Union{Real,Missing}}(missing,n), # full
                #hourot = Vector{Union{Real,Missing}}(missing,n), # f
                #hourre = Vector{Union{Real,Missing}}(missing,n), # f

                hourtot = Vector{Union{Real,Missing}}(missing,n), # f
                incseo2  = Vector{Union{Real,Missing}}(missing,n), # f
                tothours  = Vector{Union{Real,Missing}}(missing,n), # f
                indinc   = Vector{Union{Real,Missing}}(missing,n), # f
                indisben  = Vector{Union{Real,Missing}}(missing,n), # f
                inearns   = Vector{Union{Real,Missing}}(missing,n), # f
                ininv    = Vector{Union{Real,Missing}}(missing,n),  # f
                inirben   = Vector{Union{Real,Missing}}(missing,n), # f
                innirben  = Vector{Union{Real,Missing}}(missing,n), # f
                inothben  = Vector{Union{Real,Missing}}(missing,n),  # f
                inpeninc  = Vector{Union{Real,Missing}}(missing,n), # f
                inrinc   = Vector{Union{Real,Missing}}(missing,n), # f
                jobtype  = Vector{Union{Int8,Missing}}(missing,n),  # f - job
                etype = Vector{Union{Int8,Missing}}(missing,n), # 07-08 missing - job
                earnings = Vector{Union{Real,Missing}}(missing,n), # 07-08 missing
                usual_hours = Vector{Union{Real,Missing}}(missing,n), # 07-08 missing
                actual_hours = Vector{Union{Real,Missing}}(missing,n), # 07-08 missing
                hourly_wage = Vector{Union{Real,Missing}}(missing,n),
                jobsect = Vector{Union{Int8,Missing}}(missing,n), # 2010-2015
                pencont = Vector{Union{Real,Missing}}(missing,n), # f
                pays_union_contrib  = Vector{Union{Int8,Missing}}(missing,n), # 2010-2015
                cpi = Vector{Union{Real,Missing}}(missing,n),
                cpih = Vector{Union{Real,Missing}}(missing,n),
                gdpdeflator = Vector{Union{Real,Missing}}(missing,n) # f
                )
        merged
end

function mergeAll( year, hhld, adult, job, penprov, hbai, prices, gdpdef )
        @assert isiterabletable( hhld )
        @assert isiterabletable( adult )
        @assert isiterabletable( job )
        @assert isiterabletable( penprov )
        @assert isiterabletable( hbai )
        # another approach is ::AbstractDataFrame
        # .. and so on
        numadults = size(adult)[1]
        merged = initialiseMerged( numadults )
        adno = 0
        for ao in 1:numadults
                ad   = adult[ao,:]
                asn  = ad.sernum
                abu  = ad.benunit
                apn  = ad.person

                hh   = hhld[( hhld.sernum .== asn ),:]

                hba  = hbai[(( hbai.sernum .== asn ) .&
                             ( hbai.benunit .== abu )), :]

                nhh = size( hh )[1]
                nhba = size( hba )[1]
                @assert nhba <= 1
                @assert nhh  == 1
                gvtregn = remapRegion(hh[1,:gvtregn])
                if( nhba == 1) && ( nhh == 1 ) && ( gvtregn != 13 )  # only those with HBAI record, not in NI
                        adno += 1
                        ajob = job[(( job.sernum .== asn ) .&
                                    ( job.benunit .== abu ) .&
                                    ( job.person .== apn )),:]

                        apen = penprov[(( penprov.sernum .== asn ) .&
                                        ( penprov.benunit .== abu ) .&
                                        ( penprov.person .== apn )),:]
                        njobs = size( ajob )[1]
                        npens = size( apen )[1]
                        nhba  = size( hba )[1]
                        dd = split( hh[1,:intdate], "/" )
                        interview_year = parse( Int64, dd[3])
                        interview_month  = parse( Int8, dd[1])
                        quarter = div( interview_month-1, 3 ) + 1
                        merged[adno,:interview_year] = interview_year
                        merged[adno,:interview_month] = interview_month
                        # print( "interview_month $interview_month quarter $quarter\n" )

                        aprice = prices[((prices.year .== interview_year) .&
                                         (prices.month .== interview_month )), : ]
                        agdp = gdpdef[((gdpdef.year .== interview_year) .&
                                (gdpdef.q .== quarter )), : ]

                        merged[adno,:frs_year] = year
                        merged[adno,:sernum] = asn
                        merged[adno,:benunit] = abu
                        merged[adno,:person] = apn
                        merged[adno,:gvtregn] = gvtregn
                        merged[adno,:tenure] = hh[1,:tenure]
                        merged[adno,:hhcomps] = hh[1,:hhcomps]
                        merged[adno,:num_children] = hba[1,:depchldh]
                        merged[adno,:num_adults] = hba[1,:adulth]
                        if adult[ao,:ftwk] > 0
                                merged[adno,:ftwk] = adult[ao,:ftwk]
                        end
                        if( year >= 2005 )
                                merged[adno,:age_in_bands] = adult[ao,:age80]
                        else
                                iagegr2 = adult[ao,:iagegr2]
                                age = 0
                                if iagegr2 == 4
                                   age = 20 # Age 16 to 24
                                elseif iagegr2 == 5
                                   age = 30 # Age 25 to 34
                                elseif iagegr2 == 6
                                   age = 40 # Age 35 to 44
                                elseif iagegr2 == 7
                                   age = 50 # Age 45 to 54
                                elseif iagegr2 == 8
                                   age = 58 # Age 55 to 59
                                elseif iagegr2 == 9
                                   age = 62 # Age 60 to 64
                                elseif iagegr2 == 10
                                   age = 70 # Age 65 to 74
                                elseif iagegr2 == 11
                                   age = 80 # Age 75 to 84
                                elseif iagegr2 == 12
                                   age = 85 # Age 85 or over
                                else
                                        @assert "unmapped iagegr2=$iagegr2"
                                end # age
                                @assert( age >= 16 ) && (age <= 85)
                                merged[adno,:age_in_bands] = age
                        end
                        merged[adno,:sex] = adult[ao,:sex]
                        merged[adno,:marital] = adult[ao,:marital]
                        merged[adno,:tea] = max(0,adult[ao,:tea])
                        merged[adno,:nssec] = max(0,adult[ao,:nssec])
                        merged[adno,:empstati] = adult[ao,:empstati]

                        ethgr3 = -1
                        ethgrp = -1;
                        if year < 2011
                                ethgrp = adult[ao,:ethgrp]
                                if ethgrp in ( 1,2,3 )
                                        ethgr3 = 1 # white
                                elseif ethgrp in ( 4,5,6,7 )
                                        ethgr3 = 2 # mixed
                                elseif ethgrp in ( 8,9,10,11,15 )
                                        ethgr3 = 3 # asian inc chinese
                                elseif ethgrp in ( 12,13,14 )
                                        ethgr3 = 4 # black
                                elseif ethgrp in ( 16 )
                                        ethgr3 = 5 # other
                                end
                        else
                                ethgr3 = adult[ao,:ethgr3]
                        end
                        @assert (ethgr3 in ( 1:5 )) "failed to map $ethgr3 for person $ao ethgrp $ethgrp year $year"
                        merged[adno,:ethgrp]  = ethgr3 # merged white,oth,asian,black,oth

                        if year >= 2008 && year <= 2011
                                merged[adno,:hi2qual] = adult[ao,:hi2qual] # 2008-11
                        end # fixme merge in others ..
                        merged[adno,:sic] = adult[ao,:sic] # recoded in 2009 Vector{Union{Int8,Missing}}(missing,n),
                        if year  >= 2011
                                merged[adno,:soc2010] = adult[ao,:soc2010] # 2011-15
                        end
                        if adult[ao,:spcreg1] > 0
                                merged[adno,:spcreg1] = adult[ao,:spcreg1]
                        end
                        if adult[ao,:spcreg2] > 0
                                merged[adno,:spcreg2] = adult[ao,:spcreg2]
                        end
                        if adult[ao,:spcreg3] > 0
                                merged[adno,:spcreg3] = adult[ao,:spcreg3]
                        end
                        if year >= 2003 && year <= 2011
                                merged[adno,:disdif1] = adult[ao,:disdif1] == 1 ? 1 : 0
                                merged[adno,:disdif2] = adult[ao,:disdif2] == 1 ? 1 : 0
                                merged[adno,:disdif3] = adult[ao,:disdif3] == 1 ? 1 : 0
                                merged[adno,:disdif4] = adult[ao,:disdif4] == 1 ? 1 : 0
                                merged[adno,:disdif5] = adult[ao,:disdif5] == 1 ? 1 : 0
                                merged[adno,:disdif6] = adult[ao,:disdif6] == 1 ? 1 : 0
                                merged[adno,:disdif7] = adult[ao,:disdif7] == 1 ? 1 : 0
                                merged[adno,:disdif8] = adult[ao,:disdif8] == 1 ? 1 : 0
                        elseif year > 2011
                                merged[adno,:disdifp1] = adult[ao,:disdifp1]  == 1 ? 1 : 0
                        end
                        merged[adno,:hourcare] = max(0,adult[ao,:hourcare])
                        ht = adult[ao,:hourtot]
                        hourtot = 0.0
                        ht = adult[ao,:hourtot]
                        if ht ==  0
                           hourtot = 0 # 0 hours per week
                        elseif ht ==  1
                           hourtot = 2 # 0-4 hours per week
                        elseif ht ==  2
                           hourtot = 7 # 5-9 hours per week
                        elseif ht ==  3
                           hourtot = 15 # 10-19 hours per week
                        elseif ht ==  4
                           hourtot = 28 # 20-34 hours per week
                        elseif ht ==  5
                           hourtot = 42 # 35-49 hours per week
                        elseif ht ==  6
                           hourtot = 75 # 50-99 hours per week
                        elseif ht ==  7
                           hourtot = 100 # 100 or more hours per week
                        elseif ht ==  8
                           hourtot = 10 # Varies - under 20 hours per week
                        elseif ht ==  9
                           hourtot = 27 # Varies - 20-34 hours per week
                        elseif ht ==  10
                           hourtot = 50 # Varies - 35 hours a week or more
                        end
                        merged[adno,:hourtot] = hourtot

                        merged[adno,:incseo2 ] = max(0,adult[ao,:incseo2 ])
                        merged[adno,:tothours ] = max(0,adult[ao,:tothours ])
                        merged[adno,:indinc  ] = adult[ao,:indinc  ]
                        merged[adno,:indisben ] = adult[ao,:indisben ]
                        merged[adno,:inearns  ] = adult[ao,:inearns  ]
                        merged[adno,:ininv ] = adult[ao,:ininv   ]
                        merged[adno,:inirben  ] = adult[ao,:inirben  ]
                        merged[adno,:innirben ] = adult[ao,:innirben ]
                        merged[adno,:inothben ] = adult[ao,:inothben ]
                        merged[adno,:inpeninc ] = adult[ao,:inpeninc ]
                        merged[adno,:inrinc  ] = adult[ao,:inrinc  ]
                        penamt = 0.0
                        for p in 1:npens
                                if( apen[p,:penamt] > 0 )
                                        if apen[p,:penamtpd]==95
                                                penamt += apen[p,:penamt]/52.0
                                        else
                                                penamt += apen[p,:penamt]
                                        end
                                end
                        end
                        earnings = 0.0
                        actual_hours = 0.0
                        usual_hours = 0.0
                        pays_union_contrib = false
                        for j in 1:njobs
                                if j == 1 # take 1st record job for all of these
                                        merged[adno,:etype] =  ajob[j,:etype]
                                        merged[adno,:jobtype] =  ajob[j,:jobtype]
                                        if( year >= 2010 )
                                                merged[adno,:jobsect] = ajob[j,:jobsect]
                                        end
                                end
                                if ajob[j,:jobhours] > 0
                                        actual_hours += ajob[j,:jobhours]
                                end
                                if ! (year in (2007,2008))
                                        if ajob[j,:dvushr] > 0
                                                usual_hours += ajob[j,:dvushr]
                                        end
                                        if( year >= 2012)
                                                if( ajob[j,:othded03] == 1)
                                                        pays_union_contrib = true
                                                end
                                        else
                                                if( ajob[j,:othded3] == 1)
                                                        pays_union_contrib = true
                                                end
                                        end
                                end

                                addBonus = false
                                if ajob[j,:ugross] > 0.0 # take usual when last not usual
                                        earnings += ajob[j,:ugross]
                                        addBonus = true
                                elseif ajob[j,:grwage] > 0.0 # then take last
                                        earnings += ajob[j,:grwage]
                                        addBonus = true
                                elseif ajob[j,:ugrspay] > 0.0 # then take total pay, but don't add bonuses
                                        earnings += ajob[j,:ugrspay]
                                end
                                if addBonus
                                        for i in 1:6
                                                bon = Symbol( string("bonamt",i))
                                                tax = Symbol( string("bontax",i))
                                                if ajob[j,bon] > 0.0
                                                        bon = ajob[j,bon]
                                                        if  ajob[j,tax] == 2
                                                                bon /= (1-0.22) # fixme hack basic rate
                                                        end
                                                        earnings += bon/52.0 # fixwme weeks per year
                                                end
                                        end # bonuss loop
                                end # add bonuses
                        end # jobs loop
                        @assert earnings >= 0.0
                        @assert actual_hours >= 0.0
                        @assert usual_hours >= 0.0
                        merged[adno,:earnings] = earnings
                        merged[adno,:actual_hours] = actual_hours
                        merged[adno,:usual_hours] = usual_hours
                        if pays_union_contrib
                                merged[adno,:pays_union_contrib] = 1
                        else
                                merged[adno,:pays_union_contrib] = 0
                        end
                        if actual_hours > 0
                                merged[adno,:hourly_wage] = earnings/actual_hours # inc bonuses
                        end
                        merged[adno,:pencont] = penamt
                        merged[adno,:hhld_income] = hba[1,:egrinchh] #FRS extended - gross income for the household
                        merged[adno,:gbhscost] = hba[1,:ehcost]

                        merged[adno,:cpi] = aprice[1,:D7BT]
                        merged[adno,:cpih] = aprice[1,:L522]
                        merged[adno,:gdpdeflator] = agdp[1,:L8GG]
                end # add this person - is in HBAI
                # print( "$asn $abu $apn $njobs $npens \n")
        end # loop round Adult
        merged[1:adno,:]
end

function loadone( which, year )
        fname = string( "/mnt/data/frs/", year, "/tab/", which, ".tab")
        loadtoframe( fname )
end

# parse.(Int64,split.(h95[:intdate],"/")[:][1])

global MONTHS = Dict(
        "JAN"=>1,
        "FEB"=>2,
        "MAR"=>3,
        "APR"=>4,
        "MAY"=>5,
        "JUN"=>6,
        "JUL"=>7,
        "AUG"=>8,
        "SEP"=>9,
        "OCT"=>10,
        "NOV"=>11,
        "DEC"=>12 )


function loadGDPDeflator( name )
        prices = DataFrame(CSV.File( name, separator=',' ))
        np = size(prices)[1]
        prices[:year] = zeros(Int64,np) #Union{Int64,Missing},np)
        prices[:q] = zeros(Int8,np) #zeros(Union{Int64,Missing},np)
        dp = r"([0-9]{4}) Q([1-4])"
        for i in 1:np
                rc = match( dp, prices[i,:CDID] )
                if( rc !== nothing )
                        prices[i,:year] = parse(Int64,rc[1])
                        prices[i,:q] = parse( Int8,rc[2])
                #else
        #                prices[i,:year] = 0 # missing
        #                prices[i,:month] = 0 # missing
                end
        end
        prices
end

function loadPrices( name )
        prices = DataFrame(CSV.File( name, separator=',' ))
        np = size(prices)[1]
        prices[:year] = zeros(Int64,np) #Union{Int64,Missing},np)
        prices[:month] = zeros(Int8,np) #zeros(Union{Int64,Missing},np)
        dp = r"([0-9]{4}) ([A-Z]{3})"
        for i in 1:np
                rc = match( dp, prices[i,:CDID] )
                if( rc != nothing )
                        prices[i,:year] = parse(Int64,rc[1])
                        prices[i,:month] = MONTHS[rc[2]]
                #else
        #                prices[i,:year] = 0 # missing
        #                prices[i,:month] = 0 # missing
                end
        end
        prices
end


"""
Load one frame using [] and jam all names to lower case (FRS changes case by year)
"""
function loadtoframe( name )
        (pname,ext) = splitext( name )
        if ext == ".tab"
                df = CSV.File( name, delim='\t') |> DataFrame
        else
                df = DataFrame(load(name))
        end
        # all names as lc strings
        lcnames = Symbol.(lowercase.(string.(names(df))))
        names!(df,lcnames)
        df
end

function loadoneold( name, year )
        name = dfname( name, year )
        return loadtoframe( name )
end

function makeAll( startyear, endyear )
        merged = initialiseMerged(0)
        prices = loadPrices( "/mnt/data/prices/mm23/mm23_edited.csv" );
        gdpdef = loadGDPDeflator( "/mnt/data/prices/gdpdef.csv" )
        for year in startyear:endyear
                print( "on year $year " )
                hh = loadone("househol", year);
                ad = loadone("adult", year);
                pen = loadone("penprov", year );
                job = loadone("job", year );
                hbai = loadtoframe( string( HBAI_DIR, HBAIS[year]))
                ds = mergeAll( year, hh, ad, job, pen, hbai, prices, gdpdef )
                append!( merged, ds )
        end
        merged
end
