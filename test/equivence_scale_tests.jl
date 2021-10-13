using Test
using ScottishTaxBenefitModel
using .EquivalenceScales:  
    EQScales, 
    EQ_Person, 
    get_equivalence_scales,
    EQ_P_Type,
    eq_spouse_of_head,
    eq_other_adult,
    eq_head

using .ExampleHelpers

#
# Replicates cases based on tables 1,2 of:
# Chanfreau, Jenny, and Tania Burchard. 2008. 
# ‘Scottish Government - Income and Poverty Statistics - Equivalence Scales Paper’. September 2008. https://www2.gov.scot/Topics/Statistics/Browse/Social-Welfare/IncomePoverty/equivalence-scales-paper.
# https://www2.gov.scot/Topics/Statistics/Browse/Social-Welfare/IncomePoverty/equivalence-scales-paper
#
@testset "Eq Scales" begin
    for (key,hh) in get_all_examples()
        eqs :: EQScales = get_equivalence_scales( 
            Float64,
            collect(values(hh.people)))
        println( "hh $key $eqs" )

        if key == single_hh 
            @test eqs.oxford == 1
            @test eqs.oecd_bhc == 1
            @test eqs.oecd_ahc == 1
            @test eqs.mcclements_bhc == 1
            @test eqs.mcclements_ahc == 1
            @test eqs.square_root == 1
            @test eqs.per_capita == 1
        elseif key == single_parent_hh
            # 1 adult 2 kids 18 and 8
            @test eqs.oxford ≈ 1+0.7+0.5
            @test eqs.oecd_bhc ≈ 1+0.3+0.5
            @test eqs.oecd_ahc ≈ 1+0.34+0.72
            @test eqs.mcclements_bhc ≈ 1+0.377+0.59
            @test eqs.mcclements_ahc ≈ 1+0.42+0.69
            @test eqs.square_root ≈ sqrt(3)
            @test eqs.per_capita ≈ 3
        elseif key == childless_couple_hh   
            @test eqs.oxford ≈ 1+0.7
            @test eqs.oecd_bhc ≈ 1+0.5
            @test eqs.oecd_ahc ≈ 1+0.72
            @test eqs.mcclements_bhc ≈ 1+0.64
            @test eqs.mcclements_ahc ≈ 1+0.82
            @test eqs.square_root == sqrt(2)
            @test eqs.per_capita == 2
        elseif key == cpl_w_2_children_hh
            # chidren 2 5
            @test eqs.oxford ≈ 1+0.7+0.5+0.5
            @test eqs.oecd_bhc ≈ 1+0.5+0.3+0.3
            @test eqs.oecd_ahc ≈ 1+0.72+0.34+0.34
            @test eqs.mcclements_bhc ≈ 1+0.64+0.295+0.344
            @test eqs.mcclements_ahc ≈ 1+0.82+0.33+0.38
            @test eqs.square_root ≈  sqrt(4)
            @test eqs.per_capita ≈ 4
        end
        @test eqs == hh.equivalence_scales        
    end
end