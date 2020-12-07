# STB Design Principles

Graham Stark 07 Dec 2020.

## General

* scope is Scotland, current and reasonably foreseeable fiscal systems;
  - UK is likely needed for some purposes;
* This is a *static, single period* model:
  - Entitlement to benefits, liability to tax;
  - single year;
  - dynamic features enabled by clean design, not built in;
* results should be completely reproduceable:
  - randoms, sample selection, etc. should be parameterised, not built in;
* accuracy of individual calculations over accuracy in aggregate:
  - use weighting routines sparingly, especially during development;
* it's a model:
  - some trade-off between complete accuracy and flexibility is necessary;
* other documentation: 
   - test suite is also key documentation;
   - annotated bibliography should be an output;
* multiple front ends:
   - Pluto;
   - web using callbacks;
   - embeddable module (e.g. in labour supply or macro models);
* Primary data is FRS:
   - don't attempt model that completely abstracts from FRS;
   - model consumption taxes either by merging LCF or estimating Engel Curves;
   - investigate merging SHS (health, housing, transport).
* documentation through code:
   - use type annotations and naming over comments;
* runs should be outside the model package, using (e.g.) Pluto, a Web Interface, or DrWatson;
   - the model package just provides a simple `run` API.
 
## Coding

Practically all of this is violated in the actual code ..

* use a sensible subset of Julia 
   - models are often best developed by people who know a bit about programming, policy, economics & the
     tax-benefit system, rather than hardcore specialists in any one of these things;
   - stick to aspects covered in a good introduction to the language;
   - avoid hard to understand things like Julia's interfaces, parallelism;
* give types to everything
   - function inputs & returns, elements of structs
   - this is for documentation & early detection of errors rather than
     performance;
   - abstract types (Real, Number, Integer, etc.) should work well for
     this purpose; but see [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-fields-with-abstract-type), 
* testing: 
   - unit testing of all public and most private functions;
   - test against known results;
   - and against extremes (negative incomes, max reals etc.);
   - aim for 100% coverage;
   - use [Travis](https://travis-ci.com/grahamstark/ScottishTaxBenefitModel.jl) or similar;
* designed to fail:
   - any unreasonable value should halt the program;
   - assertions on entry and exit from all important functions;
* use [Blue Style](https://github.com/invenia/BlueStyle)
   - I almost never do;
* keep user interface and graphics code completely seperate;
* use DataFrames everywhere;