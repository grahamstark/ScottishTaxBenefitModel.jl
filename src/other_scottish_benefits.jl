
# see: https://www.mygov.scot/pension-age-winter-heating-payment

@with_kw mutable struct OtherScottishBenefits{RT<:Number}
    todo = zero(RT)
    # https://www.mygov.scot/winter-heating-payment/eligibility
    winter_heating_amount = RT(59.75)
    winter_heating_qualifying_benefits = Set(Incomes[UNIVERSAL_CREDIT,INCOME_SUPPORT])
end

function weeklyise!( otb :: OtherScottishBenefits; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR) 
    otb.winter_heating_amount /= wpy
end