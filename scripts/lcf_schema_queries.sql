--
-- Queries to show exactly what's in LFS coicop top level divisions.
-- see lfs docs: 9022_volume_f_derived_variables_2020-21.xlsx
-- 
-- food & non alc 

select * from dictionaries.variables where name in (
    'C11111t','C11121t','C11122t','C11131t','C11141t','C11142t','C11151t','C11211t','C11221t',
    'C11231t','C11241t','C11251t','C11252t','C11253t','C11261t','C11271t','C11311t','C11321t',
    'C11331t','C11341t','C11411t','C11421t','C11431t','C11441t','C11451t','C11461t','C11471t',
    'C11511t','C11521t','C11522t','C11531t','C11541t','C11551t','C11611t','C11621t','C11631t',
    'C11641t','C11651t','C11661t','C11671t','C11681t','C11691t','C11711t','C11721t','C11731t',
    'C11741t','C11751t','C11761t','C11771t','C11781t','C11811t','C11821t','C11831t','C11841t',
    'C11851t','C11861t','C11911t','C11921t','C11931t','C11941t','C12111t','C12121t','C12131t',
    'C12211t','C12221t','C12231t','C12241t' ) 
and year=2020
and dataset='lcf';


-- housing and domestic fuel


select * from dictionaries.variables where name in (
    'B010','B020','B050','B053u','B056u','B060','B102',
    'B104','B107','B108','B159','B175','B178','B222',
    'B170','B173','B221','B018','B017','C41211t','C43111t',
    'C43112t','C43212c','C44112u','C44211t','C45112t','C45114t',
    'C45212t','C45214t','C45222t','C45312t','C45411t','C45412t','C45511t')
and year=2020
and dataset='lcf'
and tables='dvhh';

-- health 

select * from dictionaries.variables where name in (
    'C61111c','C61112c','C61211c','C61311c','C61312c','C61313c','C62111c','C62112c',
    'C62113c','C62114c','C62211c','C62212c','C62311c','C62321c','C62322c','C62331c',
    'C63111c')
and year=2020
and dataset='lcf' and tables='dvhh';

-- transport 

select * from dictionaries.variables where name in (
    'B244','B245','B247','B249','B250','B252','B248','B218','B217','B219',
    'B216','B487','B488',
    'C71111c','C71112t','C71121c','C71122t','C71211c','C71212t','C71311t',
    'C71411t','C72111t','C72112t','C72113t','C72114t','C72115t','C72211t',
    'C72212t','C72213t','C72311c','C72312c','C72313t','C72314t','C72411t',
    'C72412t','C72413t','C72414t','C73112t','C73212t','C73213t','C73214t',
    'C73411t','C73512t','C73513t','C73611t')
and year=2020
and dataset='lcf';

-- misc goods

select * from dictionaries.variables where name in (
    'B110','B168','B188','B229','B1802','B238','B273','B280','B281','B282',
    'B283','CC1111t','CC1211t','CC1311t','CC1312t',
    'CC1313t','CC1314t','CC1315t','CC1316t','CC1317t','CC2111t','CC3111t',
    'CC3112t','CC3211t','CC3221t','CC3222t','CC3223t','CC3224t','CC4111t',
    'CC4112t','CC4121t','CC4122t','CC5213t','CC5411c','CC5412t','CC5413t',
    'CC6211c','CC6212t','CC6214t','CC7111t','CC7112t','CC7113t','CC7114t',
    'CC7115t','CC7116t','CC5311c')
and year=2020
and dataset='lcf' and tables='dvhh';

-- non-consumption 

select * from dictionaries.variables where name in (
    'B130','B150','B208','B213','B2081','B038p','B030','B187',
    'B179','B334h','B265','B237','B228','B196','B197','B198',
    'B199','B1961','B1981','B2011','B201','B202','B205','B206',
    'CK1315t','CK1316t','CK1412t','CK2111t','CK3111t','CK3112t',
    'CK4111t','CK4112t','CK5221t','CK5222t','CK5223t','CK5224c',
    'CK5212t','CK5213t','CK5214t','CK5215t','CK5216t','CK5315c',
    'CK5111t','CK5113t','CK1313t','CK1314t','CC5111c','CC5312c','CC5511c')
and year=2020
and dataset='lcf' and tables='dvhh';

-- hotels and restraunts (sp)

select * from dictionaries.variables where name in (

    'B260','B482','B483','B484','B485','CB1111t','CB1112t','CB1113t','CB1114t','CB1115t',
    'CB1116t','CB1117c','CB1118c','CB1119c','CB111Ac','CB111Bc','CB111Ct','CB111Dt','CB111Et',
    'CB111Ft','CB111Gt','CB111Ht','CB111It','CB111Jt','CB1121t','CB1122t','CB1123t','CB1124t',
    'CB1125t','CB1126t','CB1127t','CB1128t','CB112Bt','CB1213t' )
and year=2020
and dataset='lcf' and tables='dvhh';