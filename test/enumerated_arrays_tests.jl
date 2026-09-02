using Tests
using ScottishTaxBenefitModel
using .EnumeratedArrays
using JSON

@enum Income begin
    wage = 99
    pension = 5
    tax = 900
end


@testset "EnumeratedArrays" begin

    i = IT{Income,Float64}()                    # D1.i
    j = IT{Income,Number}(wage = 10)            # D1.ii
    k = IT{Income,Number}(; default = 0.0)      # D1.iii
    m = IT{Income,Float64}(; operator = x -> Int(x) / 10)  # D1.iv

    i .= 0                                      # D2 — works, all slots become 0 & "set"
    prod = j .* k                               # D2 — works even though most slots unset (→ plain Vector)

    i.wage = 99                                 # D3
    i[wage] = 99                                # D3
    @show i                                     # D4 — only set entries, in Enum order
    i.pension                                   # D5 — 0.0, unset

    for (k, v) in i                             # F
        println(k, " ", v)
    end

    j_json = JSON.json(j)                       # E
    j2 = IT{Income,Number}(JSON.parse(j_json))  # E — round trip
end


