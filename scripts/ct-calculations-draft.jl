using ScottishTaxBenefitModel
using .RunSettings
using .ModelHousehold
using .STBParameters
using .Definitions

using CSV
using DataFrame

const DDIR = joinpath("/","mnt","data","ScotBen","data", "local", "local_targets_2024" )


"""
Very simple implementation of the CT scheme
note this doesn't include rebates apart from single
person rebate
"""
function l_calc_council_tax( 
    hh :: Household{RT}, 
    intermed :: MTIntermediate,
    ctsys :: CouncilTax{RT} ) :: RT where RT 
    ctres = zero(RT)
    if hh.region != Wales
        @assert hh.ct_band != Band_I # We're not Welsh
    end
    ctres = ctsys.band_d[hh.council]* ctsys.relativities[hh.ct_band]
    if intermed.num_adults == 1
        ctres *= (1-ctsys.single_person_discount)
    end
    ## TODO disabled discounts. See CT note.
    return ctres
end

function calculate_ct()
    ctf = joinpath( DDIR, "council-tax-levels-scotland-24-25-edited.tab")
    wf = joinpath( DDIR,  "la-frs-weights-scotland-2024.tab") 
    settings = Settings()
    ctrates = CSV.File( ctf ) |> DataFrame
    ctrates.authority_code = Symbol.(ctrates.authority_code)
    weights = CSV.File( wf ) |> DataFrame
    band_ds = Dict{Symbol,Float64}()
    p = 0
    for r in eachrow(ctrates)
        p += 1
        if p > 1 # skip 1
            band_ds[Symbol(r.authority_code)] = r.D
        end
    end 
    sys = get_default_system_for_fin_year(2024; scotland=true)
    sys.loctax.ct.band_d = band_ds

    time settings.num_households, settings.num_people, nhh2 = initialise( settings; reset=false )
    # @time nhh, num_people, nhh2 = initialise( settings; reset=false )
    num_las = size( ctrates )[1]
    revs = DataFrame( 
        code=fill("", num_las), 
        ctrev = zeros(num_las), 
        average_wage=zeros(num_las), 
        average_se=zeros(num_las), 
        ft_jobs=zeros(num_las), 
        semp=zeros(num_las) )
    p = 0
    for code in ctrates.authority_code
        localincometax = deepcopy( sys.it )
        localincometax.non_savings_rates .+= 0.01
        w = weights[!,code]
        p += 1
        band_d = ctrates[(ctrates.code .== code),:D][1]
        ctrev = 0.0
        average_wage = 0.0
        average_se = 0.0
        nearers = 0.0
        nses = 0.0
        for i in 1:nhh
            hh = get_household(i)
            hh.council = scode
            hh.weight = w[i]
            intermed = make_intermediate( 
                hh, sys.lmt.hours_limits,
                sys.age_limits,
                sys.child_limits )
            ct1 = l_calc_council_tax( hh, intermed.hhint, band_d, sys.loctax.ct )
            ct2 = l_calc_council_tax( 
                hh, intermed.hhint, sys.loctax.ct )
            @assert ct1 ≈ ct2

            

            for (pid,pers) in hh.people
                if pers.employment_status in [
                    Full_time_Employee ]
                    # Part_time_Employee ]
                    nearers += w[i]
                    average_wage += (w[i]*pers.income[wages])
                elseif  pers.employment_status in [
                    Full_time_Self_Employed,
                    Part_time_Self_Employed]
                    average_se += pers.income[self_employment_income]*w[i]
                    nses += w[i]
                end
            end

            ctrev += w[i]*ct2
        end 
        average_se /= nses
        average_wage /= nearers
        revs.code[p] = code
        revs.ctrev[p] = ctrev
        revs.average_wage[p] = average_wage
        revs.average_se[p] = average_se
        revs.ft_jobs[p] = nearers
        revs.semp[p] = nses
    end
    #=
    for code in ctrates.code[2:end]
        f = Formatting.format(revs[code],precision=0, commas=true)
        println( "$code = $(f)")
    end
    =#

    revs
end

