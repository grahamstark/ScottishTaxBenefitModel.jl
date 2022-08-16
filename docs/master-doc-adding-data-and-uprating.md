# Model Maintenance master document - Adding Data, Uprating, Weighting, New Benefits, New Parameters

This tries to bring together everything in the convoluted steps needed to add a year's worth of data to the model (FRS/SHS), uprate the variables and create a new weighting target dataset. 

This is *convoluted*. I don't remember Taxben being this hard. Ideally I'd automate much of this - I had a brief go using some of the APIs for grabbing ONS data, but didn't get far. 

Also, paths are often hard-wired in: add a paths config file.

Always keep running the test suite while you're doing any of this. 

The struct `UpdatingInfo` in `Definitions.jl` holds static info on when each component below was last updated and should be kept up-to-date.

File paths are held as constants in `Definitions.jl`.

Raw survey data from [UK Data Service](https://ukds.ac.uk) (login in keypass). Unpack these into the `$RAW_DATA/[dataset]/[year]` directories and add simlinks to `tab` and `mrdoc` directories.

* bad thing: the `.rtf` format we needed for loading the documentation into the `dictionaries` Postgres database isn't there anymore. TODO document this db and the Ruby code somewhere and add parsing from `.html` files in mrdoc.


## 1. ADDING a new FRS

## 2. Matching in a new SHS

## 3. Creating a target weighting dataset

## 4. Uprating

## 5. Benefits

### 5.1 The Legacy/UC transition

### 5.2 Model Transitions to new disable/carer benefits

### 5.3 Benefit Generosity

## 6. Adding new default parameters

### 6.1 Direct Taxes

### 6.2 UK Benefits

### 6.3 Scottish Benefits

## 7. Updating Tests

### 7.1 Individual Level Unit Tests

### 7.2 Tests in Aggregate - sources

## 8 Notes on data sources

## References





