using CSV,DataFrames
import Utils
#


function dsum( df::DataFrame, keys )
    s = zeros( size( df,1 ))
    for (k,v) in keys
        # println( k )
        # println( df[!,k])
        s .+= df[!,k]
    end
    s
end

good_things = (
    :c11111t =>"Rice",
    :c11121t =>"Bread",
    :c11131t =>"Pasta products",
    :c11142t =>"Pastry (savoury)",
    :c11151t =>"Other breads and cereals",
    :c11211t =>"Beef (fresh, chilled or frozen)",
    :c11221t =>"Pork (fresh, chilled or frozen)",
    :c11231t =>"Lamb (fresh, chilled or frozen)",
    :c11241t =>"Poultry (fresh, chilled or frozen)",
    :c11251t =>"Sausages",
    :c11252t =>"Bacon and ham",
    :c11253t =>"Offal, pâté etc.",
    :c11261t =>"Other preserved or processed meat and meat preparations",
    :c11271t =>"Other fresh, chilled or frozen edible meat",
    :c11311t =>"Fish (fresh, chilled or frozen)",
    :c11321t =>"Seafood (fresh, chilled or frozen)",
    :c11331t =>"Dried, smoked or salted fish and seafood",
    :c11341t =>"Other preserved or processed fish and seafood and preparations",
    :c11411t =>"Whole milk",
    :c11421t =>"Low fat milk",
    :c11431t =>"Preserved milk",
    :c11441t =>"Yoghurt",
    :c11451t =>"Cheese and curd",
    :c11461t =>"Other milk products",
    :c11471t =>"Eggs",
    :c11511t =>"Butter",
    :c11521t =>"Margarine and other vegetable fats",
    :c11522t =>"Peanut butter",
    :c11531t =>"Olive oil",
    :c11541t =>"Edible oils",
    :c11551t =>"Other edible animal fats",
    :c11611t =>"Citrus fruits (fresh)",
    :c11621t =>"Bananas (fresh)",
    :c11631t =>"Apples (fresh)",
    :c11641t =>"Pears (fresh)",
    :c11651t =>"Stone fruits (fresh)",
    :c11661t =>"Berries (fresh)",
    :c11671t =>"Other fresh, chilled or frozen fruits",
    :c11681t =>"Dried fruit and nuts",
    :c11691t =>"Preserved fruit and fruit-based products",
    :c11711t =>"Leaf and stem vegetables (fresh or chilled)",
    :c11721t =>"Cabbages (fresh or chilled)",
    :c11731t =>"Vegetables grown for their fruit (fresh, chilled or frozen)",
    :c11741t =>"Root crops, non-starchy bulbs and mushrooms (fresh or frozen)",
    :c11751t =>"Dried vegetables",
    :c11761t =>"Other preserved or processed vegetables",
    :c11771t =>"Potatoes",
    :c11781t =>"Other tubers and products of tuber vegetables",
    :c11911t =>"Sauces, condiments",
    :c11921t =>"Salt, spices and culinary herbs",
    :c11931t =>"Baker's yeast, dessert preparations, soups",
    :c11941t =>"Other food products",
    :c12111t =>"Coffee",
    :c12121t =>"Tea",
    :c12131t =>"Cocoa and powdered chocolate",
    :c12211t =>"Mineral or spring waters",
    :c12241t =>"Vegetable juices"
)

sugars = (
    :c11122t =>"Buns, crispbread and biscuits",
    :c11141t =>"Cakes and puddings",
    :c11811t =>"Sugar",
    :c11821t =>"Jams, marmalades",
    :c11831t =>"Chocolate",
    :c11841t =>"Confectionery products",
    :c11851t =>"Edible ices and ice cream",
    :c11861t =>"Other sugar products",
    :c12131t =>"Cocoa and powdered chocolate",
    :c12221t =>"Soft drinks",
    :c12231t =>"Fruit juices",
    :cb1112t =>"Eat Out Confectionery eaten off premises",
    :cb1113t =>"Eat Out Ice cream eaten off premises",
    :cb1114t =>"Eat Out Takeaway Soft drinks eaten off premises",
    :cb1117t =>"Eat Out Confectionery (child)",
    :cb1118t =>"Eat Out Ice cream (child)",
    :cb1119t =>"Eat Out Soft drinks (child)",
    :cb1122t =>"Eat Out Confectionery",
    :cb1123t =>"Eat Out Ice cream",
    :cb1124t =>"Eat Out Soft drinks"
    )

sugars_at_home = (
    :c11122t =>"Buns, crispbread and biscuits",
    :c11141t =>"Cakes and puddings",
    :c11811t =>"Sugar",
    :c11821t =>"Jams, marmalades",
    :c11831t =>"Chocolate",
    :c11841t =>"Confectionery products",
    :c11851t =>"Edible ices and ice cream",
    :c11861t =>"Other sugar products",
    :c12131t =>"Cocoa and powdered chocolate",
    :c12221t =>"Soft drinks",
    :c12231t =>"Fruit juices"
    )

other_eating_out = (
    :cb1111t =>"Catered food non-alcoholic drink eaten / drunk on premises",
    :cb1115t =>"Hot food eaten off premises",
    :cb1116t =>"Cold food eaten off premises",
    :cb111at =>"Hot food (child)",
    :cb111bt =>"Cold food (child)",
    :cb1121t =>"Food non-alcoholic drinks eaten drunk on premises",
    :cb1125t =>"Hot food",
    :cb1126t =>"Cold food",
    :cb1127t =>"Hot take away meal eaten at home",
    :cb1128t =>"Cold take away meal eaten at home",
    :cb112bt =>"Contract catering (food)",
    :cb1213t =>"Meals bought and eaten at workplace",
    :cb1311t =>"Catered food - eaten on premises",
    :cb1312t =>"Non-alcoholic drink - drunk on premises"
)

sugars_eating_out = (
:cb1112t =>"Eat Out Confectionery eaten off premises",
:cb1113t =>"Eat Out Ice cream eaten off premises",
:cb1114t =>"Eat Out Takeaway Soft drinks eaten off premises",
:cb1117t =>"Eat Out Confectionery (child)",
:cb1118t =>"Eat Out Ice cream (child)",
:cb1119t =>"Eat Out Soft drinks (child)",
:cb1122t =>"Eat Out Confectionery",
:cb1123t =>"Eat Out Ice cream",
:cb1124t =>"Eat Out Soft drinks" )


bad_stuff = (
    :cb111ct =>"Spirits and liqueurs (away from home)",
    :cb111dt =>"Wine from grape or other fruit (away from home)",
    :cb111et =>"Fortified wines (away from home)",
    :cb111ft =>"Ciders and Perry (away from home)",
    :cb111gt =>"Alcopops (away from home)",
    :cb111ht =>"Champagne and sparkling wines (away from home)",
    :cb111it =>"Beer and lager (away from home)",
    :cb111jt =>"Round of drinks (away from home)",
    :c21111t =>"Spirits and liqueurs (brought home)",
    :c21211t =>"Wine from grape or other fruit (brought home)",
    :c21212t =>"Fortified wine (brought home)",
    :c21213t =>"Ciders and Perry (brought home)",
    :c21214t =>"Alcopops (brought home)",
    :c21221t =>"Champagne and sparkling wines (brought home)",
    :c21311t =>"Beer and lager (brought home)",
    :c22111t =>"Cigarettes",
    :c22121t =>"Cigars",
    :c22131t =>"Other tobacco"
 )

  # C21111t +
  # C21211t +
  # C21212t +
  # C21213t +
  # C21214t +
  # C21221t +
  # C21311t +
  # C22111t +
  # C22121t +
  # C22131t +
  # C23111t

allfood = union( good_things, sugars, bad_stuff, other_eating_out )

for (k,v) in allfood
    println(Symbol(Utils.basiccensor(v)))
end

for (k,v) in good_things
    println(Symbol(Utils.basiccensor(v)))
end

lcfraw = Utils.loadtoframe( "/mnt/data/lcf/1718/tab/tab/dvhh_ukanon_2017-18.tab" ) |> DataFrame
lcf = DataFrame()


lcf[!,:age_u_18]=lcfraw[!,:a020]+lcfraw[!,:a021]+lcfraw[!,:a022]+lcfraw[!,:a030]+lcfraw[!,:a031]+lcfraw[!,:a032]
lcf[!,:age_18_plus]=lcfraw[!,:a049]-lcf[!,:age_u_18]
lcf[!,:tenure_type] =  lcfraw[!,:a122]
lcf[!,:region] =  lcfraw[!,:gorx]
lcf[!,:economic_pos] =  lcfraw[!,:a093]
lcf[!,:age_of_oldest] =  lcfraw[!,:a065p]
lcf[!,:healthy_food] = dsum( lcfraw, good_things )
lcf[!,:takeaways] = dsum( lcfraw, other_eating_out )
lcf[!,:alcohol_tobacco] = dsum( lcfraw, bad_stuff )

for (k,v) in sugars
    sk = Symbol(Utils.basiccensor(v))
    lcf[!,sk] = lcfraw[!,k]
end

n = names( lcfraw )

lcf[!,:sumallfood] = dsum( lcfraw, allfood )


lcf[!,:age_u_18]=lcfraw[!,:a020]+lcfraw[!,:a021]+lcfraw[!,:a022]+lcfraw[!,:a030]+lcfraw[!,:a031]+lcfraw[!,:a032]
lcf[!,:age_18_plus]=lcfraw[!,:a049]-lcf[!,:age_u_18]
lcf[!,:tenure_type] =  lcfraw[!,:a122]
lcf[!,:region] =  lcfraw[!,:gorx]
lcf[!,:economic_pos] =  lcfraw[!,:a093]
lcf[!,:age_of_oldest] =  lcfraw[!,:a065p]

lcf[!,:total_consumpt] =  lcfraw[!,:p600t]
lcf[!,:food_and_drink] =  lcfraw[!,:p601t]
lcf[!,:alcohol_tobacco] =  lcfraw[!,:p602t]
lcf[!,:clothing] =  lcfraw[!,:p603t]
lcf[!,:housing] =  lcfraw[!,:p604t]
lcf[!,:household_goods] =  lcfraw[!,:p605t]
lcf[!,:health] =  lcfraw[!,:p606t]
lcf[!,:transport] =  lcfraw[!,:p607t]
lcf[!,:communication] =  lcfraw[!,:p608t]
lcf[!,:recreation] =  lcfraw[!,:p609t]
lcf[!,:education] =  lcfraw[!,:p610t]
lcf[!,:restaurants_etc] =  lcfraw[!,:p611t]
lcf[!,:miscellaneous] =  lcfraw[!,:p612t]
lcf[!,:non_consumption] =  lcfraw[!,:p620tp]
lcf[!,:total_expend] =  lcfraw[!,:p630tp]
lcf[!,:equiv_scale] =  lcfraw[!,:oecdsc]
lcf[!,:weekly_net_inc] =  lcfraw[!,:p389p]

allfood = union( good_things, sugars_at_home )
