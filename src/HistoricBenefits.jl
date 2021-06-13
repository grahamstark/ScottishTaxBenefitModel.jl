module HistoricBenefits

using ScottishTaxBenefitModel.Definitions 
 
export benefit_ratio

const HISTORIC_BENEFITS = load_historic( "$(MODEL_PARAMS_DIR)/historic_benefits.csv" ) 

function benefit_ratio( 
    fy :: Integer, 
    amt :: Real, 
    btype :: Incomes_Type ) :: Real
    brat = HIST_BENEFITS[Symbol(btype)][fy]
    return amt/brat

end

end