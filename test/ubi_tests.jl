using Test
using ScottishTaxBenefitModel
using Observables
using .ModelHousehold: count,Household, le_age, ge_age
using .GeneralTaxComponents: RateBands, WEEKS_PER_YEAR, WEEKS_PER_MONTH
   
using .Results: aggregate!, init_household_result
using ScottishTaxBenefitModel.Runner: do_one_run
using .Intermediate: MTIntermediate, make_intermediate    
using .UBI: calc_UBI!,make_ubi_post_adjustments! 
using .STBParameters
using .STBIncomes
using .ExampleHelpers
using .Monitor: Progress
sys = get_system( year=2019, scotland=true )
sys.ubi.abolished = false

settings = Settings()

# observer = Observer(Progress("",0,0,0))
tot = 0
obs = Observable( Progress(settings.uuid,"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)

    tot += p.step
    println(tot)
end


@testset "UBI Pre Adjustments" begin

    sys = get_system( year=2019, scotland = true )
    println( typeof(sys.it.non_savings_income))
    sys.ubi.abolished = false
    sys.ubi.mt_bens_treatment = ub_as_is
    make_ubi_pre_adjustments!( sys )
    @test sys.uc.abolished == false
    @test sys.lmt.isa_jsa_esa_abolished == false
    @test sys.lmt.savings_credit.abolished == false
    @test sys.lmt.ctr.abolished == false
    @test sys.lmt.hb.abolished == false
    @test sys.lmt.working_tax_credit.abolished == false
    @test sys.lmt.child_tax_credit.abolished == false

    sys.ubi.mt_bens_treatment = ub_keep_housing
    make_ubi_pre_adjustments!( sys )
    @test sys.lmt.isa_jsa_esa_abolished == true
    @test sys.lmt.savings_credit.abolished == true
    @test sys.lmt.ctr.abolished == false
    @test sys.lmt.hb.abolished == false
    @test sys.lmt.working_tax_credit.abolished == true
    @test sys.lmt.child_tax_credit.abolished == true
    # Worried about inadvertently doing this twice .. should
    # make no difference.
    make_ubi_pre_adjustments!( sys )
    @test sys.lmt.isa_jsa_esa_abolished == true
    @test sys.lmt.savings_credit.abolished == true
    @test sys.lmt.ctr.abolished == false
    @test sys.lmt.hb.abolished == false
    @test sys.lmt.working_tax_credit.abolished == true
    @test sys.lmt.child_tax_credit.abolished == true

    @test BASIC_INCOME in sys.lmt.income_rules.sc_incomes 
    @test ! (BASIC_INCOME in sys.it.non_savings_income)

end


@testset "UBI Post Adjustments" begin
    
    sys = get_system( year=2019, scotland = true )
    sys.ubi.abolished = false
    res1 = do_one_run(
        settings,
        [sys],
        obs )
    sys.ubi.mt_bens_treatment = ub_keep_housing
    res2 = do_one_run(
        settings,
        [sys],
        obs )
    # dodo finish
end

@testset "example tests" begin
    # TODO FINISH

end


@testset "Basic UBI Tests" begin
    
    for (hht,hh) in get_all_examples()
        intermed = make_intermediate( 
            DEFAULT_NUM_TYPE,
            settings,
            hh, 
            sys.hours_limits, 
            sys.age_limits, 
            sys.child_limits )
        for ent in instances( UBEntitlement )
            hres = init_household_result( hh )
            sys.ubi.entitlement = ent
            calc_UBI!(
                hres,
                hh,
                sys.ubi,
                sys.lmt,
                sys.uc,    
                intermed,
                sys.hours_limits,
                sys.minwage
            )
            aggregate!( hh, hres )
            numkids = ModelHousehold.count( hh, le_age, sys.ubi.adult_age-1 )
            numpens = ModelHousehold.count( hh, ge_age, sys.ubi.retirement_age)
            numpeeps = length( hh.people )[1]
            numads = numpeeps - numpens - numkids

            ubit = numkids*sys.ubi.child_amount+
                numads*sys.ubi.adult_amount+
                numpens*sys.ubi.universal_pension
            if ent == ub_ent_all
                @test hres.income[BASIC_INCOME] ≈ ubit
            elseif ent == ub_ent_all_but_non_jobseekers
                # FIXME expand this ti BUs and Dan's elig categories
            elseif ent == ub_ent_only_in_work 

            elseif ent == ub_ent_only_not_in_work

            else

            end
            println( "$hht : adults=$numads pens=$numpens child=$numkids => ubi=$ubit")        
        end
        # Dan's income thresholds
        sys.ubi.entitlement = ub_ent_all
        for thresh in [-1,20_000,50_000,125_000]
            hres = init_household_result( hh )
            sys.ubi.income_limit = thresh/WEEKS_PER_YEAR
            calc_UBI!(
                hres,
                hh,
                sys.ubi,
                sys.lmt,
                sys.uc,    
                intermed,
                sys.hours_limits,
                sys.minwage
            )
            aggregate!( hh, hres )
            # TODO test the f**k out of this
            bi = hres.income[BASIC_INCOME]
            println( "hh $(hht)  thresh=$thresh bi=$bi")
        end
            #=
            Only those with incomes less than £20k are entitled to the full benefit
Only those with incomes less than £50k are entitled to the full benefit
Only those with incomes less than £125k are entitled to the full benefit 
            =#
    end
    # restore
    sys.ubi.entitlement = ub_ent_all
    # todo make_ubi_pre_adjustments
    # toto make_ubi_post_adjustments

end