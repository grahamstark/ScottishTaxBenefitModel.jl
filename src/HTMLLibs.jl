"""
This module contains some code for formatting Results and Households as
Bootstrap-style HTML 
"""
module HTMLLibs

using Parameters: @with_kw
using Format
using DataFrames 

using ScottishTaxBenefitModel
using .Results
using .Definitions
using .ModelHousehold
using .Utils
using .STBIncomes
using .RunSettings

export PrintControls

@with_kw mutable struct PrintControls
    include_children = true
    include_legacy   = false
    short_version    = false
    include_legal_aid = true
    include_wealth_tax = false
    include_indirect_tax = false
end

const ARROWS_3 = Dict([
    "nonsig"          => "&#x25CF;",
    "positive_strong" => "&#x21c8;",
    "positive_med"    => "&#x2191;",
    "positive_weak"   => "&#x21e1;",
    "negative_strong" => "&#x21ca;",
    "negative_med"    => "&#x2193;",
    "negative_weak"   => "&#x21e3;" ])

const ARROWS_1 = Dict([
    "nonsig"          => "",
    "positive_strong" => "<i class='bi bi-arrow-up-circle-fill'></i>",
    "positive_med"    => "<i class='bi bi-arrow-up-circle'></i>",
    "positive_weak"   => "<i class='bi bi-arrow-up'></i>",
    "negative_strong" => "<i class='bi bi-arrow-down-circle-fill'></i>",
    "negative_med"    => "<i class='bi bi-arrow-down-circle'></i>",
    "negative_weak"   => "<i class='bi bi-arrow-down'></i>" ])

function xfmt( a )
    Format.format( a; precision=2, commas=true )
end



"""
@return number, formatted 2dp, class for gain-lose, string for arrow 
"""
function format_and_class( change :: Real ) :: Tuple
    gnum = Format.format( abs(change), commas=true, precision=2 )
    glclass = "";
    glstr = ""
    if change > 20.0
        glstr = "positive_strong"
        glclass = "text-success"
    elseif change > 10.0
        glstr = "positive_med"
        glclass = "text-success"
    elseif change > 0.01
        glstr = "positive_weak"
        glclass = "text-success"
    elseif change < -20.0
        glstr = "negative_strong"
        glclass = "text-danger"
    elseif change < -10
        glstr = "negative_med"
        glclass = "text-danger"
    elseif change < -0.01
        glstr = "negative_weak"
        glclass = "text-danger"
    else
        glstr = "nonsig"
        glclass = "text-body"
        gnum = "";
    end
    ( gnum, glclass, glstr )
end

"""
Format a pair of numbers
@return bootstrap colo[u]r value, before value after value, all formatted to prec, commas
"""
function format_diff( name::String, before :: Number, after :: Number; up_is_good = 1, prec=2,commas=true, always_print=false ) :: NamedTuple
    change = round(after - before, digits=6)
    skipthis = (! always_print) && (before ≈ 0) && (after ≈ 0)

    colour = ""
    if (up_is_good !== 0) && (! (change ≈ 0))
        if change > 0
            colour = up_is_good == 1 ? "text-success" : "text-danger"
        else
            colour = up_is_good == 1 ? "text-danger" : "text-success"
        end # neg diff   
    end # non zero diff
    ds = change ≈ 0 ? "-" : Format.format(change, commas=true, precision=prec )
    if ds != "-" && change > 0
        ds = "+$(ds)"
    end 
    before_s = Format.format(before; commas=commas, precision=prec)
    after_s = Format.format(after; commas=commas, precision=prec)    
    (; name=pretty(name), colour, ds, before_s, after_s, skipthis )
end

function format_diff( name::String, before :: Bool, after :: Bool; up_is_good = 1, always_print=false ) :: NamedTuple
    skipthis = (! always_print) && (! before ) && (! after )
    change = after != before
    colour = ""
    if (up_is_good !== 0) && change
        if after
            colour = up_is_good == 1 ? "text-success" : "text-danger"
        else
            colour = up_is_good == 1 ? "text-danger" : "text-success"
        end # neg diff   
    end # non zero diff
    ds = if before == after
        ""
    elseif before 
        "-"
    else 
        "+"
    end 
    before_s = "$before"
    after_s = "$after"
    (; name=pretty(name), colour, ds, before_s, after_s, skipthis )
end

function format_diff(name :: String, before :: Enum, after :: Enum; up_is_good = 1, always_print=false )
    skipthis = false
    change = after != before
    colour = ""

    if (up_is_good !== 0) && change
        if after > before
            colour = up_is_good == 1 ? "text-success" : "text-danger"
        else
            colour = up_is_good == 1 ? "text-danger" : "text-success"
        end # neg diff   
    end # non zero diff
    ds = if before == after
        ""
    elseif before > after
        "-"
    else 
        "+"
    end 
    before_s = "$before"
    after_s = "$after"
    (; name, colour, ds, before_s, after_s, skipthis )
end

function format_diff(; name :: String, before :: Any, after :: Any, up_is_good = 1 )
    (; name=pretty(name), colour="", ds="", before_s="$before", after_s="$after", skipthis=false )
end

function frame_to_table(
    df :: DataFrame;
    up_is_good :: Vector{Int},
    prec :: Int = 2, 
    caption :: String = "",
    totals_col :: Int = -1 )
    table = "<table class='table table-sm'>"
    table *= "<thead>
        <tr>
            <th></th><th style='text-align:right'>Baseline Policy</th><th style='text-align:right'>Your Policy</th><th style='text-align:right'>Change</th>            
        </tr>
        </thead>"
    table *= "<caption>$caption</caption>"
    i = 0
    for r in eachrow( df )
        i += 1
        fmtd = format_diff( r.Item, r.Before, r.After; up_is_good=up_is_good[i], prec=prec )
        row_style = i == totals_col ? "class='text-bold table-info' " : ""
        row = "<tr $row_style><th class='text-left'>$(r.Item)</th>
                  <td style='text-align:right'>$(fmtd.before_s)</td>
                  <td style='text-align:right'>$(fmtd.after_s)</td>
                  <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>
                </tr>"
        table *= row
    end
    table *= "</tbody></table>"
    return table
end

function html_format( a :: DataFrameRow )::String
    println( "dataFrame1")
    ""
end

function html_format( a :: AbstractDataFrame )::String
    println( "dataFrame2")
    ""
end

function html_format( a :: Union{AbstractArray,Tuple} )::String
    println( "html_format entering (1) with $a")
    s = "<ol class='list-group list-group-numbered'>\n"
    for i in eachindex(a)
        item = a[i]
        if ! ismissing(item)
            if( typeof(item) <: AbstractArray) && (length(item) == 1)
                item = item[1]
            end
            vs = html_format(item) # a[i] # 
            s *= "   <li class='list-group-item'> $(vs)</li>\n"
        end
    end
    s *= "</ol>"
    return s
 end
 
 function html_format( a :: AbstractDict )::String
    s = "<ul class='list-group'>\n"
    n = length(a)
    for (k,v) in a
       if ! ismissing(v)
            if typeof(v) <: Number
                vs = xfmt(v) # v
            else
                vs = "$v"
            end
            pk = pretty(k)
            s *= "     <li class='list-group-item'><strong>$pk</strong>: $vs</li>\n"
       end
    end
    s *= "</ul>\n"
    return s
 end
 
function html_format( a :: AbstractFloat )::String
    return xfmt( a )
end

function html_format( a )
    "$a"
end
 
"""
Clone of to_md_table in .Utils
"""
function to_html_table( f; exclude=[], depth = 0 )
    # FIXME move the Utils bit here to a function
    F = typeof(f)
    @assert isstructtype( F )
    names = fieldnames(F)
    prinames = []
    structnames = []

    for n in names
        v = getfield(f,n)
        T = typeof(v)
        if n in exclude 
            ;
        elseif Utils.is_a_struct( T )
            push!( structnames, n )
        else
            push!( prinames, n )
        end
    end

    s = "<table class='table table-sm'>\n"
    for n in prinames
        v = getfield(f,n)
        pn = pretty(n)
        vs = html_format(v)    
        s *= "<tr><th>$(pn)</th><td>$vs</td></tr>\n"
    end
    s *= "</table>\n\n"
    depth += 1    
    for n in structnames
        v = getfield(f,n)
        pn = pretty(n)
        s *= "<div>\n"
        s *= "<h$(depth)>$pn</h$depth>\n\n"
        s *= to_html_table( v, exclude=exclude, depth=depth )
        s *= "</div>\n"        
    end    
    return s 
end


function non_null_row( k, val, v )
    if ismissing(v) 
        return ""
    end
    if typeof(val) <: AbstractString
        if contains( val, r"[Mm]issing")
            return ""
        end
    end
    return "<tr><th>$k</th><td>$val</td></tr>"
end

function diff_row( fmtd :: NamedTuple, row_style="" )
    @show fmtd
    if fmtd.skipthis
        return ""
    end
    # (; name=pretty(name), colour="", ds="", before_s="$before", after_s="$after", skipthis=false )
    return "<tr $row_style><th class='text-left'>$(fmtd.name)</th>
                  <td style='text-align:right'>$(fmtd.before_s)</td>
                  <td style='text-align:right'>$(fmtd.after_s)</td>
                  <td style='text-align:right' class='$(fmtd.colour)'>$(fmtd.ds)</td>
                </tr>"
end

function format_results( one_result :: HouseholdResult )::String
    return to_html_table( one_result )
end

function format_person( pers :: Person; short=false )::String    
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    hid_str = string(pers.hid)
    s *= non_null_row( "Hid", hid_str, pers.hid )
    pid_str = string(pers.pid)
    s *= non_null_row( "Pid", pid_str, pers.pid )
    pno_str = string(pers.pno)
    s *= non_null_row( "Pno", pno_str, pers.pno )
    is_hrp_str = string(pers.is_hrp)
    s *= non_null_row( "Is Hrp", is_hrp_str, pers.is_hrp )
    default_benefit_unit_str = string(pers.default_benefit_unit)
    s *= non_null_row( "Default Benefit Unit", default_benefit_unit_str, pers.default_benefit_unit )
    is_standard_child_str = string(pers.is_standard_child)
    s *= non_null_row( "Is Standard Child", is_standard_child_str, pers.is_standard_child )
    age_str = string(pers.age)
    s *= non_null_row( "Age", age_str, pers.age )
    sex_str = string(pers.sex)
    s *= non_null_row( "Sex", sex_str, pers.sex )
    ethnic_group_str = string(pers.ethnic_group)
    s *= non_null_row( "Ethnic Group", ethnic_group_str, pers.ethnic_group )
    marital_status_str = string(pers.marital_status)
    s *= non_null_row( "Marital Status", marital_status_str, pers.marital_status )
    highest_qualification_str = string(pers.highest_qualification)
    s *= non_null_row( "Highest Qualification", highest_qualification_str, pers.highest_qualification )
    sic_str = string(pers.sic)
    s *= non_null_row( "Sic", sic_str, pers.sic )
    occupational_classification_str = string(pers.occupational_classification)
    s *= non_null_row( "Occupational Classification", occupational_classification_str, pers.occupational_classification )
    public_or_private_str = string(pers.public_or_private)
    s *= non_null_row( "Public Or Private", public_or_private_str, pers.public_or_private )
    principal_employment_type_str = string(pers.principal_employment_type)
    s *= non_null_row( "Principal Employment Type", principal_employment_type_str, pers.principal_employment_type )
    socio_economic_grouping_str = string(pers.socio_economic_grouping)
    s *= non_null_row( "Socio Economic Grouping", socio_economic_grouping_str, pers.socio_economic_grouping )
    age_completed_full_time_education_str = string(pers.age_completed_full_time_education)
    s *= non_null_row( "Age Completed Full Time Education", age_completed_full_time_education_str, pers.age_completed_full_time_education )
    years_in_full_time_work_str = string(pers.years_in_full_time_work)
    s *= non_null_row( "Years In Full Time Work", years_in_full_time_work_str, pers.years_in_full_time_work )
    employment_status_str = string(pers.employment_status)
    s *= non_null_row( "Employment Status", employment_status_str, pers.employment_status )
    actual_hours_worked_str = xfmt(pers.actual_hours_worked)
    s *= non_null_row( "Actual Hours Worked", actual_hours_worked_str, pers.actual_hours_worked )
    usual_hours_worked_str = xfmt(pers.usual_hours_worked)
    s *= non_null_row( "Usual Hours Worked", usual_hours_worked_str, pers.usual_hours_worked )
    age_started_first_job_str = string(pers.age_started_first_job)
    s *= non_null_row( "Age Started First Job", age_started_first_job_str, pers.age_started_first_job )
    income_str = html_format( pers.income )
    s *= non_null_row( "Income", income_str, pers.income )
    benefit_ratios_str = html_format( pers.benefit_ratios )
    s *= non_null_row( "Benefit Ratios", benefit_ratios_str, pers.benefit_ratios )
    jsa_type_str = string(pers.jsa_type)
    s *= non_null_row( "Jsa Type", jsa_type_str, pers.jsa_type )
    esa_type_str = string(pers.esa_type)
    s *= non_null_row( "Esa Type", esa_type_str, pers.esa_type )
    dla_self_care_type_str = string(pers.dla_self_care_type)
    s *= non_null_row( "Dla Self Care Type", dla_self_care_type_str, pers.dla_self_care_type )
    dla_mobility_type_str = string(pers.dla_mobility_type)
    s *= non_null_row( "Dla Mobility Type", dla_mobility_type_str, pers.dla_mobility_type )
    attendance_allowance_type_str = string(pers.attendance_allowance_type)
    s *= non_null_row( "Attendance Allowance Type", attendance_allowance_type_str, pers.attendance_allowance_type )
    pip_daily_living_type_str = string(pers.pip_daily_living_type)
    s *= non_null_row( "Pip Daily Living Type", pip_daily_living_type_str, pers.pip_daily_living_type )
    pip_mobility_type_str = string(pers.pip_mobility_type)
    s *= non_null_row( "Pip Mobility Type", pip_mobility_type_str, pers.pip_mobility_type )
    bereavement_type_str = string(pers.bereavement_type)
    s *= non_null_row( "Bereavement Type", bereavement_type_str, pers.bereavement_type )
    had_children_when_bereaved_str = string(pers.had_children_when_bereaved)
    s *= non_null_row( "Had Children When Bereaved", had_children_when_bereaved_str, pers.had_children_when_bereaved )
    assets_str = html_format( pers.assets )
    s *= non_null_row( "Assets", assets_str, pers.assets )
    over_20_k_saving_str = string(pers.over_20_k_saving)
    s *= non_null_row( "Over 20 K Saving", over_20_k_saving_str, pers.over_20_k_saving )
    pay_includes_str = html_format( pers.pay_includes )
    s *= non_null_row( "Pay Includes", pay_includes_str, pers.pay_includes )
    registered_blind_str = string(pers.registered_blind)
    s *= non_null_row( "Registered Blind", registered_blind_str, pers.registered_blind )
    registered_partially_sighted_str = string(pers.registered_partially_sighted)
    s *= non_null_row( "Registered Partially Sighted", registered_partially_sighted_str, pers.registered_partially_sighted )
    registered_deaf_str = string(pers.registered_deaf)
    s *= non_null_row( "Registered Deaf", registered_deaf_str, pers.registered_deaf )
    disabilities_str = html_format( pers.disabilities )
    s *= non_null_row( "Disabilities", disabilities_str, pers.disabilities )
    health_status_str = string(pers.health_status)
    s *= non_null_row( "Health Status", health_status_str, pers.health_status )
    has_long_standing_illness_str = string(pers.has_long_standing_illness)
    s *= non_null_row( "Has Long Standing Illness", has_long_standing_illness_str, pers.has_long_standing_illness )
    adls_are_reduced_str = string(pers.adls_are_reduced)
    s *= non_null_row( "Adls Are Reduced", adls_are_reduced_str, pers.adls_are_reduced )
    how_long_adls_reduced_str = string(pers.how_long_adls_reduced)
    s *= non_null_row( "How Long Adls Reduced", how_long_adls_reduced_str, pers.how_long_adls_reduced )
    relationships_str = html_format( pers.relationships )
    s *= non_null_row( "Relationships", relationships_str, pers.relationships )
    relationship_to_hoh_str = string(pers.relationship_to_hoh)
    s *= non_null_row( "Relationship To Hoh", relationship_to_hoh_str, pers.relationship_to_hoh )
    is_informal_carer_str = string(pers.is_informal_carer)
    s *= non_null_row( "Is Informal Carer", is_informal_carer_str, pers.is_informal_carer )
    receives_informal_care_from_non_householder_str = string(pers.receives_informal_care_from_non_householder)
    s *= non_null_row( "Receives Informal Care From Non Householder", receives_informal_care_from_non_householder_str, pers.receives_informal_care_from_non_householder )
    hours_of_care_received_str = xfmt(pers.hours_of_care_received)
    s *= non_null_row( "Hours Of Care Received", hours_of_care_received_str, pers.hours_of_care_received )
    hours_of_care_given_str = xfmt(pers.hours_of_care_given)
    s *= non_null_row( "Hours Of Care Given", hours_of_care_given_str, pers.hours_of_care_given )
    hours_of_childcare_str = xfmt(pers.hours_of_childcare)
    s *= non_null_row( "Hours Of Childcare", hours_of_childcare_str, pers.hours_of_childcare )
    cost_of_childcare_str = xfmt(pers.cost_of_childcare)
    s *= non_null_row( "Cost Of Childcare", cost_of_childcare_str, pers.cost_of_childcare )
    childcare_type_str = string(pers.childcare_type)
    s *= non_null_row( "Childcare Type", childcare_type_str, pers.childcare_type )
    employer_provides_child_care_str = string(pers.employer_provides_child_care)
    s *= non_null_row( "Employer Provides Child Care", employer_provides_child_care_str, pers.employer_provides_child_care )
    company_car_fuel_type_str = string(pers.company_car_fuel_type)
    s *= non_null_row( "Company Car Fuel Type", company_car_fuel_type_str, pers.company_car_fuel_type )
    company_car_value_str = xfmt(pers.company_car_value)
    s *= non_null_row( "Company Car Value", company_car_value_str, pers.company_car_value )
    company_car_contribution_str = xfmt(pers.company_car_contribution)
    s *= non_null_row( "Company Car Contribution", company_car_contribution_str, pers.company_car_contribution )
    fuel_supplied_str = xfmt(pers.fuel_supplied)
    s *= non_null_row( "Fuel Supplied", fuel_supplied_str, pers.fuel_supplied )
    work_expenses_str = string(pers.work_expenses)
    s *= non_null_row( "Work Expenses", work_expenses_str, pers.work_expenses )
    travel_to_work_str = string(pers.travel_to_work)
    s *= non_null_row( "Travel To Work", travel_to_work_str, pers.travel_to_work )
    debt_repayments_str = string(pers.debt_repayments)
    s *= non_null_row( "Debt Repayments", debt_repayments_str, pers.debt_repayments )
    wealth_and_assets_str = xfmt(pers.wealth_and_assets)
    #=
    s *= non_null_row( "Wealth And Assets", wealth_and_assets_str, pers.wealth_and_assets )
    onerand_str = string(pers.onerand)
    s *= non_null_row( "Onerand", onerand_str, pers.onerand )
    legal_aid_problem_probs_str = html_format( pers.legal_aid_problem_probs )
    s *= non_null_row( "Legal Aid Problem Probs", legal_aid_problem_probs_str, pers.legal_aid_problem_probs )
    =#
    s *= "</tbody>"
    s *= "</table>"
    
    return s
end

function format_bu( bu :: BenefitUnit; short=false )::String
    return to_html_table( hh )
end

function format_household( hh :: Household; short=false )::String

    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    sequence_str = string(hh.sequence)
    s *= non_null_row( "Sequence", sequence_str, hh.sequence )
    hid_str = string(hh.hid)
    s *= non_null_row( "Hid", hid_str, hh.hid )
    data_year_str = string(hh.data_year)
    s *= non_null_row( "Data Year", data_year_str, hh.data_year )
    interview_year_str = string(hh.interview_year)
    s *= non_null_row( "Interview Year", interview_year_str, hh.interview_year )
    interview_month_str = string(hh.interview_month)
    s *= non_null_row( "Interview Month", interview_month_str, hh.interview_month )
    quarter_str = string(hh.quarter)
    s *= non_null_row( "Quarter", quarter_str, hh.quarter )
    tenure_str = string(hh.tenure)
    s *= non_null_row( "Tenure", tenure_str, hh.tenure )
    region_str = string(hh.region)
    s *= non_null_row( "Region", region_str, hh.region )
    ct_band_str = string(hh.ct_band)
    s *= non_null_row( "Ct Band", ct_band_str, hh.ct_band )
    dwelling_str = string(hh.dwelling)
    s *= non_null_row( "Dwelling", dwelling_str, hh.dwelling )
    council_tax_str = xfmt(hh.council_tax)
    s *= non_null_row( "Council Tax", council_tax_str, hh.council_tax )
    water_and_sewerage_str = xfmt(hh.water_and_sewerage)
    s *= non_null_row( "Water And Sewerage", water_and_sewerage_str, hh.water_and_sewerage )
    mortgage_payment_str = xfmt(hh.mortgage_payment)
    s *= non_null_row( "Mortgage Payment", mortgage_payment_str, hh.mortgage_payment )
    mortgage_interest_str = xfmt(hh.mortgage_interest)
    s *= non_null_row( "Mortgage Interest", mortgage_interest_str, hh.mortgage_interest )
    years_outstanding_on_mortgage_str = string(hh.years_outstanding_on_mortgage)
    s *= non_null_row( "Years Outstanding On Mortgage", years_outstanding_on_mortgage_str, hh.years_outstanding_on_mortgage )
    mortgage_outstanding_str = xfmt(hh.mortgage_outstanding)
    s *= non_null_row( "Mortgage Outstanding", mortgage_outstanding_str, hh.mortgage_outstanding )
    year_house_bought_str = string(hh.year_house_bought)
    s *= non_null_row( "Year House Bought", year_house_bought_str, hh.year_house_bought )
    gross_rent_str = xfmt(hh.gross_rent)
    s *= non_null_row( "Gross Rent", gross_rent_str, hh.gross_rent )
    rent_includes_water_and_sewerage_str = string(hh.rent_includes_water_and_sewerage)
    s *= non_null_row( "Rent Includes Water And Sewerage", rent_includes_water_and_sewerage_str, hh.rent_includes_water_and_sewerage )
    other_housing_charges_str = string(hh.other_housing_charges)
    s *= non_null_row( "Other Housing Charges", other_housing_charges_str, hh.other_housing_charges )
    gross_housing_costs_str = xfmt(hh.gross_housing_costs)
    s *= non_null_row( "Gross Housing Costs", gross_housing_costs_str, hh.gross_housing_costs )
    total_wealth_str = xfmt(hh.total_wealth)
    s *= non_null_row( "Total Wealth", total_wealth_str, hh.total_wealth )
    house_value_str = xfmt(hh.house_value)
    s *= non_null_row( "House Value", house_value_str, hh.house_value )
    weight_str = xfmt(hh.weight)
    s *= non_null_row( "Weight", weight_str, hh.weight )
    council_str = string(hh.council)
    s *= non_null_row( "Council", council_str, hh.council )
    nhs_board_str = string(hh.nhs_board)
    s *= non_null_row( "Nhs Board", nhs_board_str, hh.nhs_board )
    bedrooms_str = string(hh.bedrooms)
    s *= non_null_row( "Bedrooms", bedrooms_str, hh.bedrooms )
    head_of_household_str = string(hh.head_of_household)
    s *= non_null_row( "Head Of Household", head_of_household_str, hh.head_of_household )
    net_physical_wealth_str = xfmt(hh.net_physical_wealth)
    s *= non_null_row( "Net Physical Wealth", net_physical_wealth_str, hh.net_physical_wealth )
    net_financial_wealth_str = xfmt(hh.net_financial_wealth)
    s *= non_null_row( "Net Financial Wealth", net_financial_wealth_str, hh.net_financial_wealth )
    net_housing_wealth_str = xfmt(hh.net_housing_wealth)
    s *= non_null_row( "Net Housing Wealth", net_housing_wealth_str, hh.net_housing_wealth )
    net_pension_wealth_str = xfmt(hh.net_pension_wealth)
    s *= non_null_row( "Net Pension Wealth", net_pension_wealth_str, hh.net_pension_wealth )
    original_gross_income_str = xfmt(hh.original_gross_income)
    s *= non_null_row( "Original Gross Income", original_gross_income_str, hh.original_gross_income )
    original_income_decile_str = string(hh.original_income_decile)
    s *= non_null_row( "Original Income Decile", original_income_decile_str, hh.original_income_decile )
    equiv_original_income_decile_str = string(hh.equiv_original_income_decile)
    s *= non_null_row( "Equiv Original Income Decile", equiv_original_income_decile_str, hh.equiv_original_income_decile )
    #=
    expenditure_str = html_format( hh.expenditure )
    s *= non_null_row( "Expenditure", expenditure_str, hh.expenditure )
    factor_costs_str = html_format( hh.factor_costs )
    s *= non_null_row( "Factor Costs", factor_costs_str, hh.factor_costs )
    people_str = html_format( hh.people )
    s *= non_null_row( "People", people_str, hh.people )
    onerand_str = string(hh.onerand)
    s *= non_null_row( "Onerand", onerand_str, hh.onerand )
    =#
    equivalence_scales_str = html_format( hh.equivalence_scales )
    s *= non_null_row( "Equivalence Scales", equivalence_scales_str, hh.equivalence_scales )
    s *= "</tbody>"
    s *= "</table>"
    
    #=
    for (pid, pers) in hh.people
        s *= "<h3>Person $pid</h3>\n"
        s *= format_person( pers )
    end
    =#
    return s;
end

function format( pre::IncomesArray, post::IncomesArray )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    for i in instances(Incomes)
        df = format_diff( "$i", pre[i], post[i] )
        s *= diff_row( df )
    end
    s *= "</tbody>"
    s *= "</table>"
    return s
end


function format( pre::LMTPremiaSet, post::LMTPremiaSet)::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    for i in instances(LMTPremia)
        prep = i in pre
        postp = i in post
        df = format_diff( "$i", prep, postp )
        s *= diff_row( df )
    end
    s *= "</tbody>"
    s *= "</table>"
    return s

end


function format( pre :: OneLegalAidResult, post :: OneLegalAidResult)
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "net_income", pre.net_income, post.net_income)
    s *= diff_row( df )
    df = format_diff( "disposable_income", pre.disposable_income, post.disposable_income)
    s *= diff_row( df )
    df = format_diff( "childcare", pre.childcare, post.childcare)
    s *= diff_row( df )
    df = format_diff( "outgoings", pre.outgoings, post.outgoings)
    s *= diff_row( df )
    df = format_diff( "housing", pre.housing, post.housing)
    s *= diff_row( df )
    df = format_diff( "work_expenses", pre.work_expenses, post.work_expenses)
    s *= diff_row( df )
    df = format_diff( "maintenance", pre.maintenance, post.maintenance)
    s *= diff_row( df )
    df = format_diff( "repayments", pre.repayments, post.repayments)
    s *= diff_row( df )
    df = format_diff( "wealth", pre.wealth, post.wealth)
    s *= diff_row( df )
    df = format_diff( "passported", pre.passported, post.passported)
    s *= diff_row( df )
    df = format_diff( "eligible", pre.eligible, post.eligible)
    s *= diff_row( df )
    df = format_diff( "eligible_on_income", pre.eligible_on_income, post.eligible_on_income)
    s *= diff_row( df )
    df = format_diff( "eligible_on_capital", pre.eligible_on_capital, post.eligible_on_capital)
    s *= diff_row( df )
    df = format_diff( "income_contribution", pre.income_contribution, post.income_contribution)
    s *= diff_row( df )
    df = format_diff( "income_contribution_pw", pre.income_contribution_pw, post.income_contribution_pw)
    s *= diff_row( df )
    df = format_diff( "capital_contribution", pre.capital_contribution, post.capital_contribution)
    s *= diff_row( df )
    df = format_diff( "income_allowances", pre.income_allowances, post.income_allowances)
    s *= diff_row( df )
    df = format_diff( "capital", pre.capital, post.capital)
    s *= diff_row( df )
    df = format_diff( "disposable_capital", pre.disposable_capital, post.disposable_capital)
    s *= diff_row( df )
    df = format_diff( "capital_allowances", pre.capital_allowances, post.capital_allowances)
    s *= diff_row( df )
    df = format_diff( "entitlement", pre.entitlement, post.entitlement)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end # la format

function format( pre::LegalAidResult, post::LegalAidResult )
    s = "<h4>Civil</h4>\n"
    s *= format( pre.civil, post.civil )
    s *= "<h4>A&amp;A</h4>\n"
    s *= format( pre.aa, post.aa )
    return s
end

function format(  pre :: UCResults, post :: UCResults)
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "basic_conditions_satisfied", pre.basic_conditions_satisfied, post.basic_conditions_satisfied)
    s *= diff_row( df )
    df = format_diff( "disqualified_on_capital", pre.disqualified_on_capital, post.disqualified_on_capital)
    s *= diff_row( df )
    df = format_diff( "work_allowance", pre.work_allowance, post.work_allowance)
    s *= diff_row( df )
    df = format_diff( "earnings_before_allowances", pre.earnings_before_allowances, post.earnings_before_allowances)
    s *= diff_row( df )
    df = format_diff( "earned_income", pre.earned_income, post.earned_income)
    s *= diff_row( df )
    df = format_diff( "other_income", pre.other_income, post.other_income)
    s *= diff_row( df )
    df = format_diff( "tariff_income", pre.tariff_income, post.tariff_income)
    s *= diff_row( df )
    df = format_diff( "standard_allowance ", pre.standard_allowance , post.standard_allowance )
    s *= diff_row( df )
    df = format_diff( "child_element", pre.child_element, post.child_element)
    s *= diff_row( df )
    df = format_diff( "limited_capacity_for_work_activity_element", pre.limited_capacity_for_work_activity_element, post.limited_capacity_for_work_activity_element)
    s *= diff_row( df )
    df = format_diff( "carer_element", pre.carer_element, post.carer_element)
    s *= diff_row( df )
    df = format_diff( "childcare_costs", pre.childcare_costs, post.childcare_costs)
    s *= diff_row( df )
    df = format_diff( "housing_element", pre.housing_element, post.housing_element)
    s *= diff_row( df )
    df = format_diff( "other_housing_costs", pre.other_housing_costs, post.other_housing_costs)
    s *= diff_row( df )
    df = format_diff( "assets", pre.assets, post.assets)
    s *= diff_row( df )
    df = format_diff( "maximum ", pre.maximum , post.maximum )
    s *= diff_row( df )
    df = format_diff( "total_income", pre.total_income, post.total_income)
    s *= diff_row( df )
    df = format_diff( "transitional_protection", pre.transitional_protection, post.transitional_protection)
    s *= diff_row( df )
    df = format_diff( "ctr", pre.ctr, post.ctr)
    s *= diff_row( df )
    df = format_diff( "recipient", pre.recipient, post.recipient)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre::LMTIncomes, post::LMTIncomes)
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "gross_earnings", pre.gross_earnings, post.gross_earnings)
    s *= diff_row( df )
    df = format_diff( "net_earnings  ", pre.net_earnings  , post.net_earnings  )
    s *= diff_row( df )
    df = format_diff( "other_income  ", pre.other_income  , post.other_income  )
    s *= diff_row( df )
    df = format_diff( "total_income  ", pre.total_income  , post.total_income  )
    s *= diff_row( df )
    df = format_diff( "disregard", pre.disregard, post.disregard)
    s *= diff_row( df )
    df = format_diff( "childcare", pre.childcare, post.childcare)
    s *= diff_row( df )
    df = format_diff( "capital", pre.capital, post.capital)
    s *= diff_row( df )
    df = format_diff( "tariff_income", pre.tariff_income, post.tariff_income)
    s *= diff_row( df )
    df = format_diff( "disqualified_on_capital", pre.disqualified_on_capital, post.disqualified_on_capital)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre::LMTCanApplyFor, post::LMTCanApplyFor)
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "ctc ", pre.ctc , post.ctc )
    s *= diff_row( df )
    df = format_diff( "esa", pre.esa, post.esa)
    s *= diff_row( df )
    df = format_diff( "hb ", pre.hb , post.hb )
    s *= diff_row( df )
    df = format_diff( "is", pre.is, post.is)
    s *= diff_row( df )
    df = format_diff( "jsa", pre.jsa, post.jsa)
    s *= diff_row( df )
    df = format_diff( "pc ", pre.pc , post.pc )
    s *= diff_row( df )
    df = format_diff( "sc ", pre.sc , post.sc )
    s *= diff_row( df )
    df = format_diff( "wtc ", pre.wtc , post.wtc )
    s *= diff_row( df )
    df = format_diff( "ctr", pre.ctr, post.ctr)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre:: LMTResults, post::LMTResults )
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "ndds", pre.ndds, post.ndds)
    s *= diff_row( df )
    df = format_diff( "mig ", pre.mig , post.mig )
    s *= diff_row( df )
    df = format_diff( "mig_recipient", pre.mig_recipient, post.mig_recipient)
    s *= diff_row( df )
    df = format_diff( "mig_premia", pre.mig_premia, post.mig_premia)
    s *= diff_row( df )
    df = format_diff( "mig_allowances", pre.mig_allowances, post.mig_allowances)
    s *= diff_row( df )
    df = format_diff( "ctc_elements", pre.ctc_elements, post.ctc_elements)
    s *= diff_row( df )
    df = format_diff( "wtc_elements", pre.wtc_elements, post.wtc_elements)
    s *= diff_row( df )
    df = format_diff( "wtc_ctc_threshold", pre.wtc_ctc_threshold, post.wtc_ctc_threshold)
    s *= diff_row( df )
    df = format_diff( "wtc_ctc_tapered_excess", pre.wtc_ctc_tapered_excess, post.wtc_ctc_tapered_excess)
    s *= diff_row( df )
    df = format_diff( "wtc_recipient", pre.wtc_recipient, post.wtc_recipient)
    s *= diff_row( df )
    df = format_diff( "cost_of_childcare", pre.cost_of_childcare, post.cost_of_childcare)
    s *= diff_row( df )
    df = format_diff( "hb_passported", pre.hb_passported, post.hb_passported)
    s *= diff_row( df )
    df = format_diff( "other_housing_costs", pre.other_housing_costs, post.other_housing_costs)
    s *= diff_row( df )
    df = format_diff( "hb_premia", pre.hb_premia, post.hb_premia)
    s *= diff_row( df )
    df = format_diff( "hb_allowances", pre.hb_allowances, post.hb_allowances)
    s *= diff_row( df )
    df = format_diff( "hb_eligible_rent", pre.hb_eligible_rent, post.hb_eligible_rent)
    s *= diff_row( df )
    df = format_diff( "hb_recipient", pre.hb_recipient, post.hb_recipient)
    s *= diff_row( df )
    df = format_diff( "ctr", pre.ctr, post.ctr)
    s *= diff_row( df )
    df = format_diff( "ctr_passported", pre.ctr_passported, post.ctr_passported)
    s *= diff_row( df )
    df = format_diff( "ctr_premia", pre.ctr_premia, post.ctr_premia)
    s *= diff_row( df )
    df = format_diff( "ctr_allowances", pre.ctr_allowances, post.ctr_allowances)
    s *= diff_row( df )
    df = format_diff( "ctr_eligible_amount", pre.ctr_eligible_amount, post.ctr_eligible_amount)
    s *= diff_row( df )
    df = format_diff( "ctr_recipient", pre.ctr_recipient, post.ctr_recipient)
    s *= diff_row( df )
    df = format_diff( "pc_premia", pre.pc_premia, post.pc_premia)
    s *= diff_row( df )
    df = format_diff( "pc_allowances", pre.pc_allowances, post.pc_allowances)
    s *= diff_row( df )
    df = format_diff( "pc_recipient", pre.pc_recipient, post.pc_recipient)
    s *= diff_row( df )
    df = format_diff( "wtc_income", pre.wtc_income , post.wtc_income )
    s *= diff_row( df )

    s *= "</tbody>\n"
    s *= "</table>\n"

    s *= "<h4>MIG Incomes</h4>\n"
    s *= format( pre.mig_incomes, post.mig_incomes)
    

    s *= "<h4>Housing Benefit Incomes</h4>\n"
    s *= format( pre.hb_incomes, post.hb_incomes)

    s *= "<h4>Child Tax Credit Incomes</h4>\n"
    s *= format( pre.ctr_incomes, post.ctr_incomes)
    
    s *= "<h4>Pension Credit Incomes</h4>\n"
    s *= format( pre.pc_incomes, post.pc_incomes)

    s *= "<h4>Savings Credit Incomes (Unused?)</h4>\n"
    s *= format( pre.sc_incomes, post.sc_incomes)

    s *= "<h4>Premia</h4>\n"
    s *= format( pre.premia, post.premia)
    
    s *= "<h4>Benefits BU Can Apply For</h4>\n"
    s *= format( pre.can_apply_for, post.can_apply_for)
    return s
end

function format( pre:: IndirectTaxResult , post :: IndirectTaxResult ) :: String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "VED", pre.VED, post.VED)
    s *= diff_row( df )
    df = format_diff( "fuel_duty", pre.fuel_duty, post.fuel_duty)
    s *= diff_row( df )
    df = format_diff( "VAT", pre.VAT, post.VAT)
    s *= diff_row( df )
    df = format_diff( "excise_beer", pre.excise_beer, post.excise_beer)
    s *= diff_row( df )
    df = format_diff( "excise_cider", pre.excise_cider, post.excise_cider)
    s *= diff_row( df )
    df = format_diff( "excise_wine", pre.excise_wine, post.excise_wine)
    s *= diff_row( df )
    df = format_diff( "excise_tobacco", pre.excise_tobacco, post.excise_tobacco)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre::BenefitCapResults, post::BenefitCapResults )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "cap", pre.cap, post.cap)
    s *= diff_row( df )
    df = format_diff( "cap_benefits", pre.cap_benefits, post.cap_benefits)
    s *= diff_row( df )
    df = format_diff( "reduction", pre.reduction, post.reduction)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre::WealthTaxResult, post::WealthTaxResult )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "total_payable", pre.total_payable, post.total_payable )
    s *= diff_row( df )
    df = format_diff( "weekly_equiv", pre.weekly_equiv, post.weekly_equiv)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s
end

function format( pre::NIResult, post::NIResult )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "above_lower_earnings_limit", pre.above_lower_earnings_limit, post.above_lower_earnings_limit)
    s *= diff_row( df )
    df = format_diff( "class_1_primary", pre.class_1_primary, post.class_1_primary   )
    s *= diff_row( df )
    df = format_diff( "class_1_secondary", pre.class_1_secondary, post.class_1_secondary )
    s *= diff_row( df )
    df = format_diff( "class_2", pre.class_2, post.class_2  )
    s *= diff_row( df )
    df = format_diff( "class_3", pre.class_3, post.class_3  )
    s *= diff_row( df )
    df = format_diff( "class_4", pre.class_4, post.class_4  )
    s *= diff_row( df )
    df = format_diff( "assumed_gross_wage", pre.assumed_gross_wage, post.assumed_gross_wage)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    return s    
end

function format( pre :: ITResult, post::ITResult)::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "taxable_income", pre.taxable_income, post.taxable_income)
    s *= diff_row( df )
    df = format_diff( "adjusted_net_income", pre.adjusted_net_income, post.adjusted_net_income)
    s *= diff_row( df )
    df = format_diff( "total_income", pre.total_income, post.total_income)
    s *= diff_row( df )
    df = format_diff( "allowance  ", pre.allowance  , post.allowance  )
    s *= diff_row( df )
    df = format_diff( "non_savings_tax", pre.non_savings_tax, post.non_savings_tax)
    s *= diff_row( df )
    df = format_diff( "non_savings_band", pre.non_savings_band, post.non_savings_band)
    s *= diff_row( df )
    df = format_diff( "non_savings_income", pre.non_savings_income, post.non_savings_income)
    s *= diff_row( df )
    df = format_diff( "non_savings_taxable", pre.non_savings_taxable, post.non_savings_taxable)
    s *= diff_row( df )
    df = format_diff( "savings_tax", pre.savings_tax, post.savings_tax)
    s *= diff_row( df )
    df = format_diff( "savings_band", pre.savings_band, post.savings_band)
    s *= diff_row( df )
    df = format_diff( "savings_income", pre.savings_income, post.savings_income)
    s *= diff_row( df )
    df = format_diff( "savings_taxable", pre.savings_taxable, post.savings_taxable)
    s *= diff_row( df )
    df = format_diff( "dividends_tax", pre.dividends_tax, post.dividends_tax)
    s *= diff_row( df )
    df = format_diff( "dividend_band", pre.dividend_band, post.dividend_band)
    s *= diff_row( df )
    df = format_diff( "dividends_income", pre.dividends_income, post.dividends_income)
    s *= diff_row( df )
    df = format_diff( "dividends_taxable", pre.dividends_taxable, post.dividends_taxable)
    s *= diff_row( df )
    df = format_diff( "unused_allowance", pre.unused_allowance, post.unused_allowance)
    s *= diff_row( df )
    df = format_diff( "mca", pre.mca, post.mca)
    s *= diff_row( df )
    df = format_diff( "transferred_allowance", pre.transferred_allowance, post.transferred_allowance)
    s *= diff_row( df )
    df = format_diff( "pension_eligible_for_relief", pre.pension_eligible_for_relief, post.pension_eligible_for_relief)
    s *= diff_row( df )
    df = format_diff( "pension_relief_at_source", pre.pension_relief_at_source, post.pension_relief_at_source)
    s *= diff_row( df )
    df = format_diff( "personal_savings_allowance", pre.personal_savings_allowance, post.personal_savings_allowance)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    #=
    df = format_diff( "non_savings_thresholds", pre.non_savings_thresholds, post.non_savings_thresholds)
    s *= diff_row( df )
    df = format_diff( "savings_thresholds ", pre.savings_thresholds , post.savings_thresholds )
    s *= diff_row( df )
    df = format_diff( "dividend_thresholds", pre.dividend_thresholds, post.dividend_thresholds)
    s *= diff_row( df )
    df = format_diff( "savings_rates ", pre.savings_rates , post.savings_rates )
    s *= diff_row( df )
    df = format_diff( "dividend_rates", pre.dividend_rates, post.dividend_rates)
    s *= diff_row( df )

    =#
    return s 
end 

function format( 
    pre::IndividualResult, 
    post::IndividualResult;
    settings :: Settings,
    print :: PrintControls  )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "net_income", pre.net_income, post.net_income)
    s *= diff_row( df )
    df = format_diff( "metr", pre.metr, post.metr)
    s *= diff_row( df )
    df = format_diff( "replacement_rate", pre.replacement_rate, post.replacement_rate)
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"
    s *= "<h4>Individual Incomes</h4>"
    s *= format( pre.income, post.income )

    s *= "<h4>National Insurance</h4>"
    s *= format( pre.ni, post.ni)

    s *= "<h4>Income Tax</h4>"
    s *= format( pre.it, post.it)
    
    if print.include_wealth_tax
        s *= "<h4>Hypothetical Wealth Tax</h4>"
        s *= format( pre.wealth, post.wealth)
    end
    return s
end 

function format( pre::HousingResult, post::HousingResult)::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "allowed_rooms", pre.allowed_rooms, post.allowed_rooms)
    s *= diff_row( df )
    df = format_diff( "excess_rooms", pre.excess_rooms, post.excess_rooms)
    s *= diff_row( df )
    df = format_diff( "allowed_rent", pre.allowed_rent, post.allowed_rent)
    s *= diff_row( df )
    df = format_diff( "gross_rent", pre.gross_rent, post.gross_rent)
    s *= diff_row( df )
    df = format_diff( "rooms_rent_reduction", pre.rooms_rent_reduction, post.rooms_rent_reduction)
    s *= diff_row( df )
    s *= "</tbody>"
    return s
end

function format( 
    pre::BenefitUnitResult, 
    post::BenefitUnitResult;
    settings :: Settings,
    print :: PrintControls )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "net_income   ", pre.net_income   , post.net_income   )
    s *= diff_row( df )
    df = format_diff( "eq_net_income", pre.eq_net_income, post.eq_net_income)
    s *= diff_row( df )
    df = format_diff( "route", pre.route, post.route)
    s *= diff_row( df )
    df = format_diff( "other_benefits ", pre.other_benefits , post.other_benefits )    
    s *= diff_row( df )
    s *= "</tbody>"
    s *= "</table>"

    s *= "<h4>Benefit Unit Incomes</h4>"
    df = format( pre.income, post.income)

    if print.include_legacy && (settings.means_tested_routing != uc_full )
        s *= "<h4>Legacy Means Tested Benefits </h4>"
        s *= format( pre.legacy_mtbens, post.legacy_mtbens)
    end

    s *= "<h4>Universal Credit</h4>"
    s *= format( pre.uc, post.uc)
    
    s *= "<h4>Benefit Cap</h4>"
    s *= format( pre.bencap, post.bencap)
    
    if print.include_legal_aid
        s *= "<h4>Legal Aid</h4>"
        s *= format( pre.legalaid, post.legalaid)    
    end
    return s;
    #=
    df = format_diff( "pers", pre.pers, post.pers)
    s *= diff_row( df )
    df = format_diff( "adults", pre.adults, post.adults)
    s *= diff_row( df )
    =#
end

function format( 
    pre::HouseholdResult, 
    post::HouseholdResult;
    settings :: Settings,
    print :: PrintControls )::String
    s = "<table class='table table-sm'>"
    s *= "<thead><caption>Money Amounts in £s pw</caption></thead>"
    s *= "<tbody>"
    s *= "<tr><th></th><th>Pre</th><th>Post</th><th>Change</th></tr>"
    df = format_diff( "bhc_net_income", pre.bhc_net_income, post.bhc_net_income)
    s *= diff_row( df )
    df = format_diff( "eq_bhc_net_income", pre.eq_bhc_net_income, post.eq_bhc_net_income)
    s *= diff_row( df )
    df = format_diff( "ahc_net_income", pre.ahc_net_income, post.ahc_net_income)
    s *= diff_row( df )
    df = format_diff( "eq_ahc_net_income", pre.eq_ahc_net_income, post.eq_ahc_net_income)
    s *= diff_row( df )
    df = format_diff( "net_housing_costs", pre.net_housing_costs, post.net_housing_costs)
    s *= "</tbody>"
    s *= "</table>"
    s *= "<h4>Household Incomes</h4>"
    s *= format( pre.income, post.income)

    if ! print.short_version
        s *= "<h4>Housing Restrictions</h4>"
        s *= format( pre.housing, post.housing )
    end
    if print.include_indirect_tax
        s *= "<h4>Indirect Taxes</h4>"
        s *= format( pre.indirect, post.indirect )
    end
    return s
end

function format( 
    hh :: Household,
    pre :: HouseholdResult, 
    post :: HouseholdResult;
    settings :: Settings,
    print :: PrintControls )::String
    s = format_household( hh )
    s *= format( pre, post;
         settings=settings, print=print ) # just hh level stuff
    for bn in eachindex(pre.bus) # note this assumes same bu structure pre and post
        brpre = pre.bus[bn]
        brpost = post.bus[bn]
        s *= "<h2>Benefit Unit $bn</h2>"
        s *= format( brpre, brpost; 
            settings=settings, print=print )
        for pid in sort(collect(keys(brpre.pers)))
            s *= "<h3>Person Number $pid</h3>"
            s *= format_person( hh.people[pid])
            s *= "<h3>Results for Person Number $pid</h3>"            
            s *= format( 
                brpre.pers[pid], brpost.pers[pid]; 
                settings=settings, print=print )
        end
    end
    return s;
end

end # module 