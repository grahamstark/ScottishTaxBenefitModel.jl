module TimeSeriesUtils

using TimeSeries, Dates

export fy, fy_array, get_birthdate

"""
For Unit testing. A date age_in_years + 1 month before today.
"""
function get_birthdate( age_in_years :: Integer, from_date :: DateTime = now() ) :: Date
    return Date(from_date - Year( age_in_years ) - Month(1))
end

"""
financial year as an interval
"""
function fy(year::Int)::StepRange
    return Date(year,04,06):Day(1):Date(year+1,04,05)
end

function fy_array( years::UnitRange ) :: Vector{Date}
    n = size(years)[1]
    d = Vector{Date}(undef, n)
    i = 0
    for y in years
        i+=1
        d[i] = Date(y,4,6)
    end
    return d
end


end                                                        