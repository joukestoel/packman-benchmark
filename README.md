# AlleAlle Expresiveness Benchmark - Optimal Package resolution

This project encodes an expresiveness benchmark for the [AlleAlle Relational Model Finder](https://github.com/cwi-swat/allealle).
This benchmark was performed for the evaluation of the paper [AlleAlle: A Bounded Relational Model Finder with Unbounded Data](https://homepages.cwi.nl/~jurgenv/papers/onward-2019.pdf). 

## Introduction
To test the expresiveness of AlleAlle we encoded the optimal package resolution problem as a relational problem.
This encoding was run on the problems used in the 'paranoid'-track of the 2012 package manager competition run by the [MANCOOSI Project](https://www.mancoosi.org/). 
Spoiler: the encoding of the package resolution problem in AlleAlle gives the same results as were published in the competition results. 

##Prerequisits:
- You need to install [Rascal](https://rascal-mpl.org). AlleAlle and the benchmark are written in it.
- You need to checkout [AlleAlle](https://github.com/cwi-swat/allealle) in your workspace. Please follow the install instructions on the AlleAlle Github page
- You need to have a working version of the Z3 SMT solver (see the AlleAlle page for instructions)
- If you want to check the found solutions against an 'oracle' you need to checkout and build the CUDF reader used in the 2012 edition of the [MISC competition](https://github.com/zacchiro/cudf). You will need the `main_cudf_check.native` executable.

## Checking a CUDF using the benchmark 
1) Import the 'packman-benchmark' project into your workspace in Eclipse (make sure that the `AlleAlle` project is also in the same workspace
2) Run the `PackMan.rsc` module in a Terminal (for instance by right-clicking on the module in the Navigator and selecting 'Run-as > Rascal Application'
3) Call the `performRequest(...)` function from the Terminal, i.e
```
performRequest(|file:///<dir/to/benchmark/project>/examples/paranoid/install/80e3fda2-9501-11e0-8001-00163e1e087d.cudf|, cudfSolCheckerExec = "/dir/to/cudf_solution_checker_executable>");
```
4) Let it run and wait for it to be finished!
 
