module Uprating

#
# This module uprates the main model data using values from CPI, Nominal GDP, average wages, etc. that 
# I've hacked together from SFC,UPRATING and Bank Of England Data. 
# See the worksheets under `data/prices/`.
#
using DataFrames
using CSV
using Pkg,LazyArtifacts
using LazyArtifacts

using ScottishTaxBenefitModel
using .RunSettings
using .Definitions
using .TimeSeriesUtils
using .Utils


"""
Semi-complete indexing routine using UPRATING quarterly data.
"""

export uprate, UPRATE_MAPPINGS

#
# This maps our uprate types to the column names in the `indexes.tab` file.

	

#
Uprate_Map = Dict(
    upr_earnings => :average_earnings,
    upr_housing_rents => :actual_rents_for_housing,
    upr_housing_oo => :mortgage_interest_payments,
    upr_unearned => :nominal_gdp,
    upr_costs => :cpi,
    upr_cpi => :cpi,
    # not used upr_gdp_deflator => :gdp_deflator,
    upr_nominal_gdp => :nominal_gdp,
    upr_shares => :equity_prices,
    upr_house_prices => :house_price_index_sa
)

function make_uprate_types() :: Dict
    d = Dict()
    for i in instances( Incomes_Type )
        if i <= odd_jobs || i in [trade_unions_etc,friendly_societies,work_expenses,avcs,other_deductions]
            d[i] = upr_earnings
        elseif i in [
            private_pensions,
            national_savings,
            bank_interest,
            individual_savings_account,
            # dividends,
            property,
            royalties,
            bonds_and_gilts,
            other_investment_income,
            other_income,
            pension_contributions_employee,
            pension_contributions_employer,
            loan_repayments ]
            d[i] = upr_nominal_gdp
        elseif i in [stocks_shares]
            d[i] = upr_shares
        elseif i in [
            alimony_and_child_support_received,
            health_insurance,
            alimony_and_child_support_paid,
            care_insurance,
            student_loan_repayments,

            education_allowances,
            foster_care_payments,
            student_grants,
            student_loans,
            free_school_meals ]
            d[i] = upr_cpi
        else # keep bens as they are: freeze, plus we just need that a payment has been made
            d[i] = upr_no_uprate
        end
    end

    d[A_Current_account] = upr_nominal_gdp
    d[A_NSB_Ordinary_account] = upr_nominal_gdp
    d[A_NSB_Investment_account] = upr_nominal_gdp
    d[A_Not_Used] = upr_nominal_gdp
    d[A_Savings_investments_etc] = upr_nominal_gdp
    d[A_Government_Gilt_Edged_Stock] = upr_nominal_gdp
    d[A_Unit_or_Investment_Trusts] = upr_shares
    d[A_Stocks_Shares_Bonds_etc] = upr_shares
    d[A_PEP] = upr_nominal_gdp
    d[A_National_Savings_capital_bonds] = upr_nominal_gdp
    d[A_Index_Linked_National_Savings_Certificates] = upr_nominal_gdp
    d[A_Fixed_Interest_National_Savings_Certificates] = upr_nominal_gdp
    d[A_Pensioners_Guaranteed_Bonds] = upr_nominal_gdp
    d[A_SAYE] = upr_nominal_gdp
    d[A_Premium_bonds] = upr_nominal_gdp
    d[A_National_Savings_income_bonds] = upr_nominal_gdp
    d[A_National_Savings_deposit_bonds] = upr_nominal_gdp
    d[A_First_Option_bonds] = upr_nominal_gdp
    d[A_Yearly_Plan] = upr_nominal_gdp
    d[A_ISA] = upr_nominal_gdp
    d[A_Fixd_Rate_Svngs_Bonds_or_Grntd_Incm_Bonds_or_Grntd_Growth_Bonds] = upr_nominal_gdp
    d[A_GEB] = upr_nominal_gdp
    d[A_Basic_Account] = upr_nominal_gdp
    d[A_Credit_Unions] = upr_nominal_gdp
    d[A_Endowment_Policy_Not_Linked] = upr_nominal_gdp
    d[A_Post_Office_Card_Account] = upr_nominal_gdp
    d[A_Informal_Assets] = upr_nominal_gdp
    d[A_Friendly_Society_Investment] = upr_nominal_gdp

    d
end

const UPRATE_MAPPINGS =  make_uprate_types()
#
# FIXME type unstable? use the trick in the 
#
UPRATING_DATA = DataFrame()
BASE_UPRATING_DATA = DataFrame()

"""
FIXME add test
return the missing value if m in -9:-1 or missing, else multy*m
"""
function non_missing_mult( m :: Union{Missing,Number}, multy :: Number )::Union{Missing,Number}
    if ismissing(m)
        return m
    end
    if m ∈ DEFAULT_MISSING_VALUES
        return m
    end
    return m*multy
end

"""
Load Quarterly UPRATING data into a dataframe, and recast everything relative to the target date (Y,Q).
See docs/notes.md on the data. Dataframe is a private global.
"""
function load_prices( settings :: Settings, reload :: Bool = false )

    global UPRATING_DATA
    global BASE_UPRATING_DATA
    @show UPRATING_DATA
    if ((size(UPRATING_DATA)[1] > 0) && ( ! reload ))
        return
    end

    upr = CSV.File(joinpath(qualified_artifact( "augdata" ),"indexes.tab"); delim = '\t', comment = "#") |> DataFrame

    nrows = size(upr)[1]
    ncols = size(upr)[2]
    println( "read $nrows rows and $ncols cols ")
    lcnames = Symbol.(basiccensor.(string.(names(upr))))
    rename!(upr, lcnames)

    upr[!,:year] = zeros(Int64, nrows)
    upr[!,:q] = zeros(Int8, nrows) #zeros(Union{Int64,Missing},np)
    
    # add year, quarter cols parsed from the 'YYYY QQ' field
    dp = r"([0-9]{4}) Q([1-4])"
    for i in 1:nrows
        rc = match(dp, upr[i, :date])
        if (rc !== nothing)
            upr[i, :year] = parse(Int64, rc[1])
            upr[i, :q] = parse(Int8, rc[2])
        end
    end
    # save a copy of the un-inverted data
    BASE_UPRATING_DATA = deepcopy(upr)
    println( "upr=$upr")
    # Make all relative to the target y,q
    println( "uprating to y=$(settings.to_y) q=$(settings.to_q)")
    pnew = findfirst((upr.year.== settings.to_y ) .& (upr.q.== settings.to_q ))
    println( "pnew=$pnew")
    for col in 1:ncols
        baser = upr[pnew,col]
        println( "on col $col $(lcnames[col]); baser=$baser")
        if ! (lcnames[col] in [:q, :year, :date ]) # got to be a better way
            upr[!,col] .= baser./upr[!,col]
        end
    end
    upr[!,:house_price_index_sa] = if settings.target_nation == N_Scotland
        copy( upr[!,:scotland_house_price_index_sa] )
    else
        copy( upr[!,:uk_house_price_index_sa] )
    end
    UPRATING_DATA = upr
end

function uprate( item :: Number, from_y::Integer, from_q::Integer, itype::Uprate_Item_Type)::Number
    # FIXME this is likely much too slow..
    global UPRATING_DATA
    if itype == upr_no_uprate
        return item
    end
    global Uprate_Map
    colsym = Uprate_Map[itype]
    p = UPRATING_DATA[((UPRATING_DATA.year.==from_y).&(UPRATING_DATA.q.==from_q)), colsym][1]
    return non_missing_mult( item, p )
end

"""
FIXME Complete this
Given (e.g.) some SFC annual growth rates `annual_changes`, extend a quarterly set of prices.
"""
function extend!( d :: DataFrame, annual_changes :: Dict{Symbol, Vector{Number} })
    for (k,v) in annual_changes
        for i in range(v)
            qg = p_from_a( v[i], 4 )
        end
    end
end

end