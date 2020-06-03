#### Picking the Right Tool for the Job

Up to this point in the course you've used Excel spreadsheets for all the activities that required calculations or drawing charts. But this model you're exploring this week is instead written in Julia, a high-level programming language, and you will interact with it through web forms embedded in this VLE. One of the key skills you'll need as an applied economist is the ability to pick an appropriate tool for the job at hand, so it's worth us briefly exploring this change of tack.

As you've seen throughout the course, spreadsheets are tremendously useful tools. But, like all tools, they are more appropriate for some tasks than others. Spreadsheets have been extensively studied[^FN_SPREADSHEETS] and it is known that they are especially error-prone when dealing with complex logic or large amounts of data. So, in your career as a professional economist, there may be times when you may want to reach for a different tool.

Other tools that have been found useful in economics include:

* *pencil and paper*: economics has a large inventory of simple but powerful graphics that can be applied to many situations- supply and demand diagrams, IS/LM, budget constraints and many others. The ability to sketch these is a key skill for an applied economist;
* *statistical packages*: these are large computer programs that are optimised to produce, for example, the linear regressions you encountered earlier in this week, and in the macroeconomics week. Examples commonly used in economics include [SAS](https://www.sas.com/en_gb/home.html), [SPSS](https://www.ibm.com/analytics/spss-statistics-software) and [Stata](https://www.stata.com/). Excellent free statistical packages are [R](https://www.r-project.org/) and [Gretl](http://gretl.sourceforge.net/), amongst others;
* *databases*: these are specialised programs that allow modelling, retrieval and update of large amounts of complex data. Examples include [Postgres](https://www.postgresql.org/) and [Oracle](https://www.oracle.com/database/). Systems specialised in the fast processing of 'Big Data' are now appearing; an example is [Apache Hadoop](http://hadoop.apache.org/);
* *high-level programming languages*: these are designed to express complex logic, such as the rules of the tax system, in a clear and efficient way. Examples that are widely used in economics include [Fortran](https://en.wikipedia.org/wiki/Fortran), [Python](https://www.python.org/) and [Julia](https://julialang.org/).

Sometimes large projects use many different tools, organised as *toolchains*; for example, a database to accumulate and retrieve data, a programming language to process it, and a spreadsheet to display the results.

Although it's good to be aware of the options, it's impossible for a single person to master all of these things. But there may come a time in a large project where the best course is to employ a specialist, or to learn a new skill yourself - professional economists would normally be expected to know at least one statistical package, for instance.

On the other hand, sometimes the optimal tool is the one you are familiar with, rather than the technically perfect one. For example, the UK Treasury's Tax Benefit Model, IGOTM, is implemented in the SAS statistical system[^FN_IGOTM] rather than a conventional programming language: SAS is widely used in the UK Government, and that familiarity is judged to outweigh any awkwardness applying SAS a little out of its natural domain.
