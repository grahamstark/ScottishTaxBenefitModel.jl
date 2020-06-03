module Uprating

using DataFrames
using CSV
using Utils
using Definitions

"""
Semi-complete indexing routine using OBR quarterly data.
"""

export uprate, UPRATE_MAPPINGS


const TO_Q = 4
const TO_Y = 2019

Uprate_Map = Dict(
    upr_earnings => :average_earnings,
    upr_housing_rents => :actual_rents_for_housing,
    upr_housing_oo => :mortgage_interest_payments,
    upr_unearned => :nominal_gdp,
    upr_costs => :cpi,
    upr_cpi => :cpi,
    upr_gdp_deflator => :gdp_deflator,
    upr_nominal_gdp => :nominal_gdp,
    upr_shares => :equity_prices
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
            pension_contributions,
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

    d
end

const UPRATE_MAPPINGS =  make_uprate_types()


"""
Load Quarterly OBR data into a dataframe, and recast everything relative to the target date (Y,Q).
See docs/notes.md on the data. Dataframe is a private global.
"""
function load_prices() :: DataFrame
    obr = CSV.File("$(PRICES_DIR)/merged_quarterly.tab"; delim = '\t', comment = "#") |>
          DataFrame
    nrows = size(obr)[1]
    ncols = size(obr)[2]
    lcnames = Symbol.(basiccensor.(string.(names(obr))))
    rename!(obr, lcnames)

    obr[!,:year] = zeros(Int64, nrows)
    obr[!,:q] = zeros(Int8, nrows) #zeros(Union{Int64,Missing},np)
    dp = r"([0-9]{4})Q([1-4])"
    for i in 1:nrows
        rc = match(dp, obr[i, :date])
        if (rc != nothing)
            obr[i, :year] = parse(Int64, rc[1])
            obr[i, :q] = parse(Int8, rc[2])
        end
    end

    pnew = findfirst((obr.year.==TO_Y) .& (obr.q.==TO_Q))
    for col in 1:ncols
        baser = obr[pnew,col]
        # println( "on col $col $(lcnames[col]); baser=$baser")
        if ! (lcnames[col] in [:q, :year, :date ]) # got to be a better way
            obr[!,col] .= baser./obr[!,col]
        end
    end
    # print(obr[1,:nomi])
    obr
end

const OBR_DATA = load_prices()

function uprate( item :: Number, from_y::Integer, from_q::Integer, itype::Uprate_Item_Type)::Number
    # FIXME this is likely much too slow..
    if itype == upr_no_uprate
        return item
    end
    global Uprate_Map
    global OBR_DATA
    global FROM_Y, FROM_Q
    colsym = Uprate_Map[itype]
    p = OBR_DATA[((OBR_DATA.year.==from_y).&(OBR_DATA.q.==from_q)), colsym][1]
    return item * p
end

end
