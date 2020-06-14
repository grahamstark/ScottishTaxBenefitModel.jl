module WebModelLibs


using JSON
using DataFrames
using CSV
using StatsBase
using Random
using Logging
using PovertyAndInequalityMeasures
using BudgetConstraints

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .ExampleHouseholdGetter
using .ModelHousehold
using .Utils
using .MiniTB
using .GeneralTaxComponents
using .Definitions

export do_one_run, local_makebc, load_data
export print_output_to_csv, create_base_results, summarise_results!

function load_data(; load_examples::Bool, load_main :: Bool, start_year = 2015 )
   example_names = Vector{AbstractString}()
   num_households = 0
   if load_examples
      example_names = ExampleHouseholdGetter.initialise()
   end
   if load_main
      rc = @timed begin
         num_households,num_people,nhh2 =
            FRSHouseholdGetter.initialise(
            household_name = "model_households_scotland",
            people_name    = "model_people_scotland",
            start_year = start_year )
      end
      mb = trunc(Integer, rc[3] / 1024^2)
      @info "loaded data; load time $(rc[2]); memory used $(mb)mb; loaded $num_households households\nready..."
   end
   (example_names, num_households, num_people )
end

const mr_edges = [-99999.99, 0.0, 0.1, 0.25, 0.5, 0.75, 1.0, 9999.0]
const growth = 0.02

function poverty_targetting_adder( dfr :: DataFrameRow, data :: Dict ) :: Real
   which = data[:which_element]
   if dfr.net_income_1 <= data[:poverty_line]
      return dfr[which]*dfr.weight_1
   end
   return 0.0
end

function create_base_results( num_households :: Integer, num_people :: Integer )
   base_results = do_one_run( MiniTB.DEFAULT_PARAMS, num_households, num_people, 1 )
   basenames = names( base_results )
   basenames = addsysnotoname( basenames, 1 )
   rename!( base_results, basenames )
   base_results
end

function characteristic_targetting_adder( dfr :: DataFrameRow, data :: Dict ) :: Real
   which = data[:which_element]
   characteristic = data[:characteristic]
   if dfr[characteristic] in data[:targets]
      return dfr[which]*dfr.weight_1
   end
   return 0.0
end

function operate_on_frame( results :: DataFrame, adder, data::Dict )
   n = size( results )[1]
   total = 0
   for i in 1:n
      total += adder( results[i,:], data )
   end
   total
end

function add_targetting( results :: DataFrame, total_spend:: AbstractArray, item_name :: AbstractString, poverty_line :: Real ) :: AbstractArray
    targetting = zeros(3)
    for sys in 1:3
        key = Symbol( "$(item_name)_$sys" )
        on_target = operate_on_frame( results, poverty_targetting_adder,
            Dict(
             :which_element=>key,
             :poverty_line=>poverty_line
            )
        )
        targetting[sys] = on_target
    end
    # targetting[3] = targetting[2]-targetting[1]
    for sys in 1:3
        if !(total_spend[sys] == 0.0)
            targetting[sys] /= total_spend[sys]
            targetting[sys] *= 100.0
        end
    end # loop to props
    targetting
end


function summarise_results!(; results::DataFrame, base_results :: DataFrame )::NamedTuple

    n_names = names( results )
    n_names_2 = addsysnotoname( n_names, 2 )
    rename!( results, n_names_2 )
    results = hcat( base_results, results )

    @assert results.pid_1 == results.pid_2
    for name in n_names
        diff_name = Symbol(String(name) * "_3")
        name_1 = Symbol(String(name) * "_1")
        name_2 = Symbol(String(name) * "_2")
        try
            results[!,diff_name] = results[!,name_2] - results[!,name_1]
        catch
            ; # idiot check for non numeric cols
        end
    end

    # CSV.write( "/home/graham_s/tmp/stb_test_results.tab", results, delim='\t')

    deciles = []
    push!( deciles, PovertyAndInequalityMeasures.binify( results, 10, :weight_1, :net_income_1 ))
    push!( deciles, PovertyAndInequalityMeasures.binify( results, 10, :weight_1, :net_income_2 ))
    push!( deciles, deciles[2] - deciles[1] )

    poverty_line = deciles[1][5,3]*(2.0/3.0)

    inequality = []
    push!( inequality, PovertyAndInequalityMeasures.make_inequality( results, :weight_1, :net_income_1 ))
    push!( inequality, PovertyAndInequalityMeasures.make_inequality( results, :weight_1, :net_income_2 ))
    push!( inequality, diff_between( inequality[2], inequality[1] ))

    poverty = []
    push!(poverty, PovertyAndInequalityMeasures.make_poverty( results, poverty_line, growth, :weight_1, :net_income_1  ))
    push!( poverty, PovertyAndInequalityMeasures.make_poverty( results, poverty_line, growth, :weight_1, :net_income_2  ))
    push!( poverty, diff_between( poverty[2], poverty[1] ))

    totals = []
    totals_1 = Dict()
    totals_1["total_taxes"]=sum(results[!,:total_taxes_1].*results[!,:weight_1])
    totals_1["total_benefits"]=sum(results[!,:total_benefits_1].*results[!,:weight_1])
    totals_1["benefit1"]=sum(results[!,:benefit1_1].*results[!,:weight_1])
    totals_1["benefit2"]=sum(results[!,:benefit2_1].*results[!,:weight_1])
    totals_1["basic_income"]=sum(results[!,:basic_income_1].*results[!,:weight_1])
    totals_1["vat"]=sum(results[!,:vat_1].*results[!,:weight_1])
    totals_1["other_indirect"]=sum(results[!,:other_indirect_1].*results[!,:weight_1])
    totals_1["total_indirect"]=sum(results[!,:total_indirect_1].*results[!,:weight_1])
    totals_1["net_incomes"]=sum(results[!,:net_income_1].*results[!,:weight_1]) # FIXME not true if we have min wage or (maybe) indirect taxes

    totals_2 = Dict()
    totals_2["total_taxes"]=sum(results[!,:total_taxes_2].*results[!,:weight_1])
    totals_2["total_benefits"]=sum(results[!,:total_benefits_2].*results[!,:weight_1])
    totals_2["benefit1"]=sum(results[!,:benefit1_2].*results[!,:weight_1])
    totals_2["benefit2"]=sum(results[!,:benefit2_2].*results[!,:weight_1])
    totals_2["basic_income"]=sum(results[!,:basic_income_2].*results[!,:weight_1])
    totals_2["vat"]=sum(results[!,:vat_1].*results[!,:weight_2])
    totals_2["other_indirect"]=sum(results[!,:other_indirect_2].*results[!,:weight_1])
    totals_2["total_indirect"]=sum(results[!,:total_indirect_2].*results[!,:weight_1])
    totals_2["net_incomes"]=sum(results[!,:net_income_2].*results[!,:weight_1]) # FIXME not true if we have min wage or (maybe) indirect taxes

    totals_3 = diff_between(totals_2, totals_1)

    push!( totals, totals_1 )
    push!( totals, totals_2 )
    push!( totals, totals_3 )

    disallowmissing!( results )

    # these are for the gain lose weights below
    results.gainers = (((results.net_income_2 - results.net_income_1)./results.net_income_1).>=0.01).*results.weight_1
    results.losers = (((results.net_income_2 - results.net_income_1)./results.net_income_1).<= -0.01).*results.weight_1
    results.nc = ((abs.(results.net_income_2 - results.net_income_1)./results.net_income_1).< 0.01).*results.weight_1

    unit_count = sum( results.weight_1 )

    gainlose_totals = (
        losers = sum( results.losers ),
        nc = sum( results.nc ),
        gainers = sum( results.gainers ))

    gainlose_by_thing = (
        thing=levels( results.thing_1 ),
        losers = counts(results.thing_1,fweights( results.losers )),
        nc= counts(results.thing_1,fweights( results.nc )),
        gainers = counts(results.thing_1,fweights( results.gainers )))
    gainlose_by_sex = (
        sex=pretty.(levels( results.sex_1 )),
        losers = counts(Int.(results.sex_1),fweights( results.losers )),
        nc= counts(Int.(results.sex_1),fweights( results.nc )),
        gainers = counts(Int.(results.sex_1),fweights( results.gainers )))

    metr_histogram = []
    avg_metr = zeros(3)
    wsum = sum( results.weight_1 )
    avg_metr[1] = sum( results.metr_1.*results.weight_1)./wsum
    avg_metr[2] = sum( results.metr_2.*results.weight_1)./wsum
    avg_metr[3] = sum( results.metr_3.*results.weight_1)./wsum

    push!( metr_histogram, fit(Histogram,results.metr_1,Weights(results.weight_1),mr_edges,closed=:right).weights )
    push!( metr_histogram, fit(Histogram,results.metr_2,Weights(results.weight_1),mr_edges,closed=:right).weights )
    push!( metr_histogram, metr_histogram[2]-metr_histogram[1] )

    @debug  "totals[1] $totals[1]"

    targetting_total_benefits =
        add_targetting( results,
                [totals[1]["total_benefits"],
                 totals[2]["total_benefits"],
                 totals[3]["total_benefits"]],
            "total_benefits", poverty_line )
    targetting_benefit1 = add_targetting( results, [totals[1]["benefit1"],totals[2]["benefit1"],totals[3]["benefit1"]], "benefit1", poverty_line )
    targetting_benefit2 = add_targetting( results, [totals[1]["benefit2"],totals[2]["benefit2"],totals[3]["benefit2"]], "benefit2", poverty_line )
    targetting_basic_income = add_targetting( results, [totals[1]["basic_income"],totals[2]["basic_income"],totals[3]["basic_income"]], "basic_income", poverty_line )

    for i in 1:3
        mult_dict!(totals[i], WEEKS_PER_YEAR ) # annualise
    end

    summary_output = (
        gainlose_totals=gainlose_totals,
        gainlose_by_sex=gainlose_by_sex,
        gainlose_by_thing=gainlose_by_thing,

        poverty=poverty,

        inequality=inequality,
        avg_metr=avg_metr,
        metr_histogram=metr_histogram,
        metr_axis=mr_edges,

        deciles=deciles,

        targetting_total_benefits = targetting_total_benefits,
        targetting_benefit1=targetting_benefit1,
        targetting_benefit2=targetting_benefit2,
        targetting_basic_income=targetting_basic_income,

        totals=totals,
        poverty_line=poverty_line,
        growth_assumption=growth,
        unit_count=unit_count
    )
    summary_output
end

function print_output_to_csv( output :: NamedTuple, dir :: AbstractString = "/var/tmp/" ) :: AbstractString
    datestr = basiccensor( "$(now())")
    randstr = randstring( 32 )
    filename = "$dir/stb_$(datestr)_$(randstr).tab"
    f = open( filename, write=true )
    #CSV.write( f, ["A","B"])
    CSV,write( f, [1 2 3; 4 5 6])
    filename
end

function map_to_example( modelpers :: .ModelHousehold.Person ) :: .MiniTB.Person
   inc = 0.0
   for (k,v) in modelpers.income
      inc += v
   end
   sex = MiniTB.Female
   if modelpers.sex == .Definitions.Male ## easier way?
      sex = MiniTB.Male
   end
   MiniTB.Person( modelpers.pid, inc, modelpers.usual_hours_worked, modelpers.age, sex )
end

function local_getnet(data :: Dict, gross::Real)::Real
   person = data[:person]
   person.wage = gross
   person.hours = gross/MiniTB.DEFAULT_WAGE
   rc = MiniTB.calculate_internal( person, data[:params ] )
   return rc[:netincome]
end

function local_makebc(
    person :: MiniTB.Person,
    tbparams :: MiniTB.TBParameters,
    settings :: BCSettings = BudgetConstraints.DEFAULT_SETTINGS ) :: NamedTuple
   data = Dict( :person=>person, :params=>tbparams )
   bc = BudgetConstraints.makebc( data, local_getnet, settings )
   annotations = annotate_bc( bc )
   ( points = pointstoarray( bc ), annotations = annotations )
end


function make_results_frame( n :: Integer ) :: DataFrame
   DataFrame(
     pid = Vector{Union{BigInt,Missing}}(missing, n),
     weight = Vector{Union{Real,Missing}}(missing, n),
     sex = Vector{Union{Gender,Missing}}(missing, n),
     thing = Vector{Union{Integer,Missing}}(missing, n),
     gross_income = Vector{Union{Real,Missing}}(missing, n),

     total_taxes = Vector{Union{Real,Missing}}(missing, n),
     total_benefits = Vector{Union{Real,Missing}}(missing, n),
     tax = Vector{Union{Real,Missing}}(missing, n),
     benefit1 = Vector{Union{Real,Missing}}(missing, n),
     benefit2 = Vector{Union{Real,Missing}}(missing, n),
     basic_income = Vector{Union{Real,Missing}}(missing, n),
     net_income = Vector{Union{Real,Missing}}(missing, n),
     metr = Vector{Union{Real,Missing}}(missing, n),
     tax_credit = Vector{Union{Real,Missing}}(missing, n),
     vat = Vector{Union{Real,Missing}}(missing, n),
     other_indirect = Vector{Union{Real,Missing}}(missing, n),
     total_indirect = Vector{Union{Real,Missing}}(missing, n))
end

function do_one_run( tbparams::.MiniTB.TBParameters, num_households :: Integer, num_people :: Integer, num_repeats :: Integer ) :: DataFrame
   results = make_results_frame( num_people )
   pnum = 0
   for hhno in 1:num_households
      frshh = FRSHouseholdGetter.get_household( hhno )
      for (pid,frsperson) in frshh.people
         pnum += 1
         if pnum > num_people
            # break
            @goto end_of_calcs
         end
         experson = map_to_example( frsperson )
         rc = nothing
         for i in 1:num_repeats
            rc = MiniTB.calculate( experson, tbparams )
         end
         res = results[pnum,:]
         res.pid = experson.pid
         res.sex = experson.sex
         res.gross_income = experson.wage
         res.weight = frshh.weight
         res.thing = rand(1:10)
         res.tax = rc[:tax]
         res.benefit1 = rc[:benefit1]
         res.benefit2 = rc[:benefit2]
         res.basic_income = rc[:basic_income]

         res.total_taxes= rc[:tax]
         res.total_benefits = rc[:benefit2]+rc[:benefit1]+rc[:basic_income]
         res.net_income = rc[:netincome]
         res.metr = rc[:metr]
         res.tax_credit = rc[:tax_credit]
         res.vat = 0.0
         res.other_indirect = 0.0
         res.total_indirect = 0.0
      end # people
   end # hhlds
   @label end_of_calcs
   ran = rand()
   print("Done; people $pnum rand=$ran\n")
   results[1:pnum-1,:];
end

end
