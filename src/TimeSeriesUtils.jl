module TimeSeriesUtils

using TimeSeries, Dates

export fy, fy_array, get_birthdate, fyear

"""
For Unit testing. A date age_in_years + 1 month before today.
"""
function get_birthdate( age_in_years :: Integer, from_date :: DateTime = now() ) :: Date
    return Date(from_date - Year( age_in_years ) - Month(1))
end

"""
financial year as an interval
"""
function fy(year::Integer)::StepRange
    return Date(year,04,06):Day(1):Date(year+1,04,05)
end

"""

"""
function fyear( year :: Integer  ) :: Date
    return Date( year, 04, 06 )
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

const FY_2000 = fyear(2000)
const FY_2001 = fyear(2001)
const FY_2002 = fyear(2002)
const FY_2003 = fyear(2003)
const FY_2004 = fyear(2004)
const FY_2005 = fyear(2005)
const FY_2006 = fyear(2006)
const FY_2007 = fyear(2007)
const FY_2008 = fyear(2008)
const FY_2009 = fyear(2009)
const FY_2010 = fyear(2010)
const FY_2011 = fyear(2011)
const FY_2012 = fyear(2012)
const FY_2013 = fyear(2013)
const FY_2014 = fyear(2014)
const FY_2015 = fyear(2015)
const FY_2016 = fyear(2016)
const FY_2017 = fyear(2017)
const FY_2018 = fyear(2018)
const FY_2019 = fyear(2019)
const FY_2020 = fyear(2020)
const FY_2021 = fyear(2021)
const FY_2022 = fyear(2022)
const FY_2023 = fyear(2023)
const FY_2024 = fyear(2024)
const FY_2025 = fyear(2025)
const FY_2026 = fyear(2026)
const FY_2027 = fyear(2027)
const FY_2028 = fyear(2028)
const FY_2029 = fyear(2029)
const FY_2030 = fyear(2030)

# financial years as intervals - y in FYI_2021 and so on
export FY_2000
export FY_2001
export FY_2002
export FY_2003
export FY_2004
export FY_2005
export FY_2006
export FY_2007
export FY_2008
export FY_2009
export FY_2010
export FY_2011
export FY_2012
export FY_2013
export FY_2014
export FY_2015
export FY_2016
export FY_2017
export FY_2018
export FY_2019
export FY_2020
export FY_2021
export FY_2022
export FY_2023
export FY_2024
export FY_2025
export FY_2026
export FY_2027
export FY_2028
export FY_2029
export FY_2030

# financial years as dates d < FY_2012 and so on
const FYI_2000 = fy(2000)
const FYI_2001 = fy(2001)
const FYI_2002 = fy(2002)
const FYI_2003 = fy(2003)
const FYI_2004 = fy(2004)
const FYI_2005 = fy(2005)
const FYI_2006 = fy(2006)
const FYI_2007 = fy(2007)
const FYI_2008 = fy(2008)
const FYI_2009 = fy(2009)
const FYI_2010 = fy(2010)
const FYI_2011 = fy(2011)
const FYI_2012 = fy(2012)
const FYI_2013 = fy(2013)
const FYI_2014 = fy(2014)
const FYI_2015 = fy(2015)
const FYI_2016 = fy(2016)
const FYI_2017 = fy(2017)
const FYI_2018 = fy(2018)
const FYI_2019 = fy(2019)
const FYI_2020 = fy(2020)
const FYI_2021 = fy(2021)
const FYI_2022 = fy(2022)
const FYI_2023 = fy(2023)
const FYI_2024 = fy(2024)
const FYI_2025 = fy(2025)
const FYI_2026 = fy(2026)
const FYI_2027 = fy(2027)
const FYI_2028 = fy(2028)
const FYI_2029 = fy(2029)
const FYI_2030 = fy(2030)

# financial years as intervals - y in FYI_2021 and so on
export FYI_2000
export FYI_2001
export FYI_2002
export FYI_2003
export FYI_2004
export FYI_2005
export FYI_2006
export FYI_2007
export FYI_2008
export FYI_2009
export FYI_2010
export FYI_2011
export FYI_2012
export FYI_2013
export FYI_2014
export FYI_2015
export FYI_2016
export FYI_2017
export FYI_2018
export FYI_2019
export FYI_2020
export FYI_2021
export FYI_2022
export FYI_2023
export FYI_2024
export FYI_2025
export FYI_2026
export FYI_2027
export FYI_2028
export FYI_2029
export FYI_2030

end                                                        