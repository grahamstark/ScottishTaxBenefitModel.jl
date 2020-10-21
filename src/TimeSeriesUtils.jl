using TimeSeries, Dates

module TimeSeriesUtils

"""
For Unit testing. A date age_in_years + 1 month before today.
"""
function get_birthdate( age_in_years :: Integer, from_date :: DateTime = now() ) :: Date
    Date(from_date - Year( age_in_years ) - Month(1))
end

"""
financial year as an interval
"""
function fy(year::Int)::StepRange
    Date(year,04,01):Day(1):Date(year+1,03,31)
end

function fy_array( start_year :: Int, end_year :: Int ) :: Vector{Date}
    n = start_year - end_year + 1
    d = Vector{Date}(undef, n)
    i = 0
    for y in start_year:end_year
        i+=1
        d[i] = Date(y,4,1)
    end

end


end                                                        