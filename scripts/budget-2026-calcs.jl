inflation = 3.8/100

function roundup(x,unit=100)
    v = trunc(x/unit)*unit
    return if v ≈ x
        x
    else
    v + unit
    end 
end 

# tb=[16537,29526,43662,75000,125140]
tb = [
        2_827.0,
        14_921.0,
        31_092.0,
        62_430.0,
        125_140 ]
# tb .-= 12570
# tb[end] = 125140
tbg=[tb[1], (tb[2:5] .- tb[1:4])...]
tbg = roundup.(tbg .* (1+inflation))
na = [tbg[1]]
for i in 2:length(tbg)
    push!( na, na[i-1]+tbg[i])
end