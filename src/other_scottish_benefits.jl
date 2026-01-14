
# see: https://www.mygov.scot/pension-age-winter-heating-payment
@with_kw mutable struct OtherScottishBenefits{T}
    winter_heating_income_limit=T(35_000.0)
    winter_heating_amount = [0.0,203.40,305.10]
    winter_heating_upper_age = 80
end


function weeklyise!( osb :: OtherScottishBenefits; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR )
    osb.winter_heating_income_limit /= wpy
    osb.winter_heating_amount ./= wpy
end

