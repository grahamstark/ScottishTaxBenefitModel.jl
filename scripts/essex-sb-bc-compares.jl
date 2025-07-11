


@usingany CairoMakie
@usingany Format
@usingany PrettyTables
@usingany CSV
@usingany DataFrames
using ScottishTaxBenefitModel
using .STBIncomes
using .BCCalcs
using .Results

include( "generate_bcs_for_essex.jl")

const WPM = 4.354
const DIR = joinpath("/","mnt", "data", "FES-Project", "Essex", "bc-comparisons" ) 
# const DIR = joinpath("/", "home", "graham_s", "VirtualWorlds", "projects", "FES-Project", "Essex", "bc-comparisons" ) 

function eu_index( key :: NamedTuple, legacy :: Bool, n :: Int ):: NamedTuple
    sbid = id_from_key( key, legacy )
    legstr = legacy ? "Old Benefit System" : "Universal Credit"
    label = title_from_key( key, legstr )
    euid = 0
    if key.marrstat == "couple"	euid += 32 end
    if key.chu6 == 3 euid += 16 end	
    if key.ch6p == 3 euid += 8 end
    if key.hcost == 400 euid += 4 end
    if key.tenure == "owner" euid += 2 end
    if key.wage == 30 euid += 2 else euid += 1 end
    euid = n + (131*(euid-1))
    num_people = key.ch6p + key.chu6 + (if key.marrstat == "couple" 2 else 1 end)
    return (; euid, sbid, label, num_people )
end

function load_essex( fname="essex-uc-all.tab", legacy=false )::DataFrame
    edf = CSV.File( joinpath( DIR, fname ), delim='\t', limit=37729) |> DataFrame
    # edf = edf[1:37728,:]
    @show names(edf)
    nrows,ncols = size(edf)
    edf.idhh_1 = coalesce.(edf.idhh_1,-9999999) # 2nd ihdd has only heads, so... 
    edf.sbid = fill("",nrows)
    edf.obs_num = fill(0,nrows)
    edf.wage = fill(0,nrows)
    edf.tenure = fill("",nrows)
    edf.marrstat = fill("",nrows)
    edf.hcost = fill(0.0,nrows)
    edf.bedrooms = fill(0,nrows)
    edf.chu6 = fill(0,nrows)
    edf.ch6p = fill(0,nrows)
    tenures = ["private", "owner"]
    hcosts = [200,400]
    marrstats = ["single", "couple"]
    num_bedrooms = [1,4]
    for wage in [12,30] # !! above mw or mr results look weird (though they're ight)
        for tenure in tenures
            for marrstat in marrstats
                for hcost in hcosts
                    for bedrooms in num_bedrooms
                        for chu6 in [0,3]
                            for ch6p in [0,3]
                                if((ch6p + chu6) > 0)&&(bedrooms <2)
                                    ; # skip pointless examples
                                elseif((ch6p + chu6) == 0)&&(bedrooms > 1)
                                    ;
                                else
                                    key = (; wage, tenure, marrstat, hcost, bedrooms, chu6, ch6p )
                                    println( "on $key")
                                    for n in 1:131
                                        eukey = eu_index( key, legacy, n )
                                        edfra = @view edf[ edf.idhh_1 .== eukey.euid, : ]
                                        @assert size(edfra)[1] == 1 "mismatch for $(eukey.label) id=$(eukey.euid) size=$(size(edfra)[1])" # eukey.num_people
                                        edfra.sbid .= eukey.sbid
                                        edfra.obs_num .= n
                                        edfra.wage .= wage
                                        edfra.tenure .= tenure
                                        edfra.marrstat .= marrstat
                                        edfra.hcost .= hcost
                                        edfra.bedrooms .= bedrooms
                                        # fix: just take euromod's children 
                                        edfra.chu6 .= edfra.i_ftype_hh_nkidsu5
                                        edfra.ch6p .= edfra.i_ftype_hh_nChildren - edfra.i_ftype_hh_nkidsu5
                                        # @assert each( edfra.ch6p .>= 0   
                                    end
                                end
                            end # ch6p
                        end # chu6
                    end # bedrooms
                end # hcost
            end # marr
        end # tenure
    end # wage
    edf = edf[edf.idhh_1.>0,:] # return heads only
    edf
end

const IN_ORDER_COLS = [
    :euromod_wages, :scotben_wages,
    :euromod_income_tax, :scotben_income_tax,
    :euromod_national_insurance, :scotben_national_insurance,
    :euromod_discretionary_housing_payment, :scotben_discretionary_housing_payment,
    :euromod_universal_credit, :scotben_universal_credit,
    :euromod_local_taxes, :scotben_local_taxes,
    :euromod_council_tax_benefit, :scotben_council_tax_benefit,
    :euromod_net_ahc_income, :scotben_net_ahc_income,
    :euromod_benefit_reduction, :scotben_benefit_reduction,
    :euromod_child_benefit, :scotben_child_benefit,
    :euromod_scottish_child_payment, :scotben_scottish_child_payment
     ]


function match_sb_essex_full()
    edf = load_essex("essex-uc-all-v2.tab")
    nrows,ncols = size(edf)
    for i in instances( Incomes )
        c = Symbol( "scotben_"*lowercase(string(i)))
        edf[!,c] = zeros(nrows)
    end

    edf.euromod_income_tax = copy( edf.ils_taxsim)
    edf.euromod_national_insurance = copy( edf.ils_sicdy)
    edf.euromod_discretionary_housing_payment = copy( edf.bhosc01_s)
    edf.euromod_universal_credit = copy( edf.bsauc_s)
    edf.euromod_local_taxes = copy( edf.i_bmu_tmu)
    edf.euromod_council_tax_benefit = copy( edf.bmu_s)
    edf.euromod_net_ahc_income = copy( edf.il_dispy_ahc_1)
    edf.euromod_benefit_reduction = copy( edf.brduc_s )
    edf.euromod_scottish_child_payment = copy( edf.bchmt_s )
    edf.euromod_child_benefit = copy( edf.bch_s )
    edf.euromod_wages = copy(edf.ils_origy_1)
    edf.euromod_num_children =  copy(edf.i_ftype_hh_nChildren)
    edf.euromod_num_children_u5 =  copy(edf.i_ftype_hh_nkidsu5)

    edf.scotben_net_ahc_income = zeros(nrows)
    edf.uc_work_allowance = zeros(nrows)
    edf.uc_earnings_before_allowances = zeros(nrows)
    edf.uc_earned_income = zeros(nrows)
    edf.uc_untapered_earnings = zeros(nrows)
    edf.uc_other_income = zeros(nrows)
    edf.uc_tariff_income = zeros(nrows)
    edf.uc_standard_allowance  = zeros(nrows)
    edf.uc_child_element = zeros(nrows)
    edf.uc_limited_capacity_for_work_activity_element = zeros(nrows)
    edf.uc_carer_element = zeros(nrows)
    edf.uc_childcare_costs = zeros(nrows)
    edf.uc_housing_element = zeros(nrows)

    edf.ctr_passported = zeros(nrows)
    edf.ctr_premia = zeros(nrows)
    edf.ctr_allowances = zeros(nrows)
    edf.ctr_incomes_gross_earnings = zeros(nrows)
    edf.ctr_incomes_net_earnings   = zeros(nrows)
    edf.ctr_incomes_other_income   = zeros(nrows)
    edf.ctr_incomes_total_income   = zeros(nrows)
    edf.ctr_incomes_disregard = zeros(nrows)
    edf.ctr_incomes_childcare = zeros(nrows)
    edf.ctr_incomes_capital = zeros(nrows)
    edf.ctr_incomes_tariff_income = zeros(nrows)
    edf.ctr_incomes_disqualified_on_capital = zeros(nrows)
    edf.ctr_eligible_amount = zeros(nrows)

    edf.cap = zeros(nrows)
    edf.scotben_benefit_reduction = zeros(nrows)
    settings = Settings()
    # settings.means_tested_routing = uc_full
    sys = STBParameters.get_default_system_for_fin_year( 2024 )

    edf.euromod_derived_income = 
        edf.euromod_wages - 
        (edf.hcost.*4.354) - 
        edf.euromod_income_tax -
        edf.euromod_national_insurance +
        edf.euromod_discretionary_housing_payment +
        edf.euromod_universal_credit -
        edf.euromod_local_taxes +
        edf.euromod_council_tax_benefit +
        edf.euromod_scottish_child_payment +
        edf.euromod_child_benefit

    for r in eachrow(edf)
        hh = get_hh( ;
            country="scotland", 
            tenure = r.tenure, 
            bedrooms = r.bedrooms, 
            hcost = r.hcost, 
            marrstat = r.marrstat, 
            chu6 = r.chu6, 
            ch6p = r.ch6p )
        head = get_head( hh )
        data = Dict([
            :pid  => head.pid,
            :wage => r.wage,
            :hh   => deepcopy(hh),
            :sys  => sys,
            :settings => settings ])
        hres = BCCalcs.local_getnet( data, r.ils_origy_1/WPM )
        r.scotben_net_ahc_income = get_net_income( hres; target = data[:settings].target_bc_income )*WEEKS_PER_MONTH
        for i in instances( Incomes )
            c = Symbol( "scotben_"*lowercase(string(i)))
            r[c] = hres.income[i]*WEEKS_PER_MONTH
        end
        # store UC components
        # CAREFUL BREAKS with > 1  bu!!!! 
        uc = hres.bus[1].uc
        lmt = hres.bus[1].legacy_mtbens
        # @show lmt
        r.ctr_passported = lmt.ctr_passported
        r.ctr_premia = lmt.ctr_premia*WEEKS_PER_MONTH
        r.ctr_allowances = lmt.ctr_allowances*WEEKS_PER_MONTH
        r.ctr_incomes_gross_earnings = lmt.ctr_incomes.gross_earnings*WEEKS_PER_MONTH
        r.ctr_incomes_net_earnings   = lmt.ctr_incomes.net_earnings  *WEEKS_PER_MONTH
        r.ctr_incomes_other_income   = lmt.ctr_incomes.other_income  *WEEKS_PER_MONTH
        r.ctr_incomes_total_income   = lmt.ctr_incomes.total_income  *WEEKS_PER_MONTH
        r.ctr_incomes_disregard = lmt.ctr_incomes.disregard*WEEKS_PER_MONTH
        r.ctr_incomes_childcare = lmt.ctr_incomes.childcare*WEEKS_PER_MONTH
        r.ctr_incomes_capital = lmt.ctr_incomes.capital
        r.ctr_incomes_tariff_income = lmt.ctr_incomes.tariff_income*WEEKS_PER_MONTH
        r.ctr_incomes_disqualified_on_capital = lmt.ctr_incomes.disqualified_on_capital
        r.ctr_eligible_amount = lmt.ctr_eligible_amount*WEEKS_PER_MONTH


        r.uc_work_allowance = uc.work_allowance*WEEKS_PER_MONTH
        r.uc_earnings_before_allowances = uc.earnings_before_allowances*WEEKS_PER_MONTH
        r.uc_earned_income = uc.earned_income*WEEKS_PER_MONTH
        r.uc_untapered_earnings = uc.untapered_earnings*WEEKS_PER_MONTH
        r.uc_other_income = uc.other_income*WEEKS_PER_MONTH
        r.uc_tariff_income = uc.tariff_income*WEEKS_PER_MONTH
        r.uc_standard_allowance  = uc.standard_allowance*WEEKS_PER_MONTH
        r.uc_child_element = uc.child_element*WEEKS_PER_MONTH
        r.uc_limited_capacity_for_work_activity_element = uc.limited_capacity_for_work_activity_element*WEEKS_PER_MONTH
        r.uc_carer_element = uc.carer_element*WEEKS_PER_MONTH
        r.uc_childcare_costs = uc.childcare_costs*WEEKS_PER_MONTH
        r.uc_housing_element = uc.housing_element*WEEKS_PER_MONTH
        r.cap = hres.bus[1].bencap.cap*WEEKS_PER_MONTH
        r.scotben_benefit_reduction = hres.bus[1].bencap.reduction*WEEKS_PER_MONTH
    end
    edf.scotben_derived_income = 
        edf.scotben_wages - 
        (edf.hcost.*WEEKS_PER_MONTH) - 
        edf.scotben_income_tax -
        edf.scotben_national_insurance +
        edf.scotben_discretionary_housing_payment +
        edf.scotben_universal_credit -
        edf.scotben_local_taxes +
        edf.scotben_council_tax_benefit +
        edf.scotben_scottish_child_payment +
        edf.scotben_child_benefit
    edf.euromod_check = edf.euromod_net_ahc_income -
        edf.euromod_derived_income
    edf.scotben_check = edf.scotben_net_ahc_income -
        edf.scotben_derived_income
    edf.scotben_vs_euromod = edf.euromod_net_ahc_income -
        edf.scotben_net_ahc_income

    # report only non-zero colums
    # try catch is because of missing union nonsense - 
    # just add up and see if we crash..
    nms = names(edf)
    non_zero_cols = []
    for n in nms # non-empy cols only
        sn = Symbol(n)
        col = edf[:,sn]
        try
            s = sum(col)
            if s != 0
                push!(non_zero_cols, sn )
            end
        catch e
            push!(non_zero_cols, sn )
        end 
    end
    for n in non_zero_cols
        println(n)
    end
    @show settings
    # clear uo irrelevent cols
    select!(edf,non_zero_cols)
    # put the comparisons on the far side
    select!(edf,Not(IN_ORDER_COLS),IN_ORDER_COLS...)
    CSV.write("$(DIR)/essex-uc-all-edited-v4.tab",edf;delim='\t')
    return edf
end

# convoluted way of making pairs of (0,-10),(0,10) for label offsets
const OFFSETS = collect( Iterators.flatten(fill([(0,-10),(0,10)],100)))

function draw_bc( title :: String, sbdf :: DataFrame, exdf :: DataFrame )::Figure
    f = Figure(size=(1200,1200))
    nrows = size(sbdf)[1]
    xmax = max(  maximum(exdf.gross), maximum(sbdf.gross))*1.1
    ymax = max(  maximum(exdf.uc), maximum(sbdf.net))*1.1
    ymin = min( minimum(exdf.uc), minimum(sbdf.net))
    
    ax = Axis(f[1,1]; xlabel="Earnings &pound;s pw", ylabel="Net Income (AHC) &pound;s pw", title=title)
    ylims!( ax, ymin, xmax ) # make this one square
    xlims!( ax, -10, xmax )
    lines!( ax, sbdf.gross, sbdf.net; color=:darkgreen, label="ScotBen" )
    scatter!( ax, 
        sbdf.gross, 
        sbdf.net; 
        marker=sbdf.char_labels,
        marker_offset=OFFSETS[1:nrows], 
        markersize=15, 
        color=:black )
    lines!( ax, [0,xmax], [0, xmax]; color=:lightgrey ) # 45° line
    scatter!( ax, sbdf.gross, sbdf.net, markersize=5, color=:darkgreen )
    lines!(ax, exdf.gross, exdf.uc; color=:darkblue, label="Essex" )
    f[1,2] = Legend( f, ax, framevisible = false )
    f
end


function various_tests()

    function interpolate( sbdf::AbstractDataFrame, tgross :: Number )::Number
        n = size(sbdf)[1]
        gross = 9999999999999.99
        interp = 0.0
        for r in n:-1:1
            row = sbdf[r,:]
            gross = row.gross
            net = row.net
            lgross = 0.0
            lnet = 0.0
            if gross < tgross 
                if (r > 1) & (r < n)
                    lgross = sbdf[r+1,:gross]
                    lnet = sbdf[r+1,:net]
                end
                dx = (lgross - gross)
                dy = (lnet - net)
                δ = dy/dx
                println( "dx=$dx dy=$dy δ=$δ gross=$gross tgross=$tgross lgross=$lgross lnet=$lnet")
                interp = (δ*(tgross - lgross))+lnet
                break
            end
        end
        interp 
    end

    for row in eachrow( sbdf )
        gross = row.gross
        net = row.net
        computed = gross
        for i in 1:30
            ik = Symbol( "item_$(i)")
            vk = Symbol( "value_$(i)")
            k = row[ik]
            v = row[vk]
            if ! ismissing(k)
                # println( "gross $gross net = $net $k=$v")
                if k == "Wages"
                    ;
                elseif k in ["Income Tax", "National Insurance", "Local Taxes"]
                    computed -= v
                else
                    computed += v
                end            
            end        
        end
        computed -= 200
        @assert isapprox(net,computed; atol=0.02) "Net: $net Computed $computed"
        println( "gross = $gross net=$net OK")
    end

    for r in eachrow( exdf )
        sbn = interpolate( sbdf, r.gross )
        diff = sbn - r.uc
        println( "r.gross=$(r.gross) sbnet=$(sbn) exnet=$(r.uc) diff=$(diff)")
    end
end # junk

function match_essex( exdf :: DataFrame ) :: Tuple
    hh =  get_hh( ;
            country = "scotland",
            tenure  =  "private",
            bedrooms = 1,
            hcost    = 200,
            marrstat = "single", 
            chu6     = 0, 
            ch6p     = 0 )
    settings = Settings()
    sys = STBParameters.get_default_system_for_fin_year( 2024 )
    head = get_head( hh )
    data = Dict([
        :pid  => head.pid,
        :wage => 12.0,
        :hh   => deepcopy(hh),
        :sys  => sys,
        :settings => settings ])
    outd = deepcopy( exdf )
    n = size(outd)[1]
    outd.INCOME_TAX = zeros(n)
    outd.NATIONAL_INSURANCE  = zeros(n)
    outd.LOCAL_TAXES  = zeros(n)
    outd.UNIVERSAL_CREDIT  = zeros(n)
    outd.COUNCIL_TAX_BENEFIT = zeros(n)
    outd.Scotben_Net_UC = zeros(n)
    outx = Vector{Any}(undef,n)
    i = 0
    for r in eachrow( outd )
        i += 1
        hres = BCCalcs.local_getnet( data, r.gross )
        r.Scotben_Net_UC = get_net_income( hres; target = data[:settings].target_bc_income )
        for i in [INCOME_TAX, NATIONAL_INSURANCE, LOCAL_TAXES, UNIVERSAL_CREDIT, COUNCIL_TAX_BENEFIT ]
            c = Symbol(string(i))
            r[c] = hres.income[i]
        end
        outx[i] = hres
    end
    outd, outx
end

#=
sbdf = CSV.File( "$(DIR)/uc-12-private-single-200.0-1-0-0.tab"; delim='\t')|>DataFrame
exdf = CSV.File( "$(DIR)/euromod-bc-summary-1.tab"; delim='\t')|>DataFrame
sbdf.char_labels = BCCalcs.get_char_labels(size(sbdf)[1])    
exdf.gross ./= WPM
exdf.uc  ./= WPM
exdf.legacy  ./= WPM

f1 = draw_bc( "example1", sbdf, exdf )

outd, outx = match_essex( exdf )

for c in eachcol(outd)
    c .*= WPM
    c .= round.(c; digits=2)
end

outd.uc_diff = outd.Scotben_Net_UC - outd.uc
rename!( pretty, outd )

CSV.write( "$(DIR)/euromod-sb-comparison-1.tab", outd; delim='\t' )
save( "$(DIR)/euromod-sb-comparison-1.svg", f1 )

=#


# edf = load_essex( "essex-uc-all-v2.tab", false  )

# CSV.write( "$(DIR)/essex-uc-all-edited-v3.tab", edf; delim='\t' )


