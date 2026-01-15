
# see: https://www.mygov.scot/pension-age-winter-heating-payment

@with_kw mutable struct OtherScottishBenefits{RT<:Number}
    todo = zero(RT)
end

function weeklyise!( otb :: OtherScottishBenefits; wpm=WEEKS_PER_MONTH, wpy=WEEKS_PER_YEAR) 

end