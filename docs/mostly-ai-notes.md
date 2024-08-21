# MostAI Generation Notes

https://mostly.ai/

API Key: mostly-a26b0399428716681c2bc85eb34b1f92441cfdabd898994a16835581473e476f

ModelID: e5004384-6f5e-4185-bd46-fe0e28f4cf3a

Uploaded the scottish model hh and pers samples.

Output all loaded into: 

    data/synthetic_data/

Main problem: many more people per household than actual.

PK - needs replacing with integer/bigint

nulls in some fields

_RARE_ intentional - replace random 

pers size:

original:  35,034

```julia
    v=counts(collect(values( countmap( pers.hid ))))
    [1:16 v]
    sum( collect(1:16) .* v)
```

sizes:

    1  2867
    2  3333
    3  1814
    4  1605
    5   887
    6   544
    7   296
    8   211
    9   123
    10    50
    11    24
    12    11
    13     9
    14     1
    15     2
    16     1

Generated: 
size: 55,467

    1  2817
    2  5374
    3  2754
    4  2473
    5  1437
    6   888
    7   508
    8   413
    9   251
    10   106
    11    45
    12    24
    13    21


As python (need to bypass APT `python`).

```python

from mostlyai import MostlyAI

# initialize client

mostly = MostlyAI(
    api_key='mostly-a26b0399428716681c2bc85eb34b1f92441cfdabd898994a16835581473e476f', 
    base_url='https://app.mostly.ai'
)

 fetch configuration via API
g = mostly.generators.get('e5004384-6f5e-4185-bd46-fe0e28f4cf3a')
config = g.config()
config
```

```python 

# probe the generator for some samples
mostly.probe('e5004384-6f5e-4185-bd46-fe0e28f4cf3a', size=10)

# use generator to create a synthetic dataset
sd = mostly.generate('e5004384-6f5e-4185-bd46-fe0e28f4cf3a', size=2_000)
sd.data()

config['tables'][1]['modelConfiguration']

config['tables'][1]['modelConfiguration']['modelSize']
# 'M'

# switch to large model 
config['tables'][0]['modelConfiguration']['modelSize']='L'
config['tables'][1]['modelConfiguration']['modelSize']='L'




sd2 = mostly.generate(g,config=config,size=2_000)


```

API seems broken. 

```python

sd = mostly.synthetic_datasets.create(g, config)

```

should work

## take 2

redid with 'temperature' 'topP' turned down and now 43900 people. `tmp/v2`.

## FIXUP SYNTHETIC DATA

### HH 
1. replace hids with numeric
2. replace rand at end with rand string
3. ben generosity regressions
4. match wealth
5. match consumption 

### PERS

1. map hids from hh
2. create pers id
3. fixup household reference person 
4. benefit unit allocation 

## check

default_benefit_unit is consecutive
data_year is same for all hh records
is_hrp - one per household 


## !!! BIG MISTAKE

add `uhid` as a true unique primary key - was hid which can be duplicated over data_years.

## Relationships Messed Up

fixup_synth_data 

file synthetic_data/skiplist.tab has list of errors

relationships! badly messed up.

## Take 2 - break adults and children into separate files 


