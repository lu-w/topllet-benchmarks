# Evaluation of Topllet

This repository contains a simple evaluation of Topplet.
For this, we have:

- one query (`row.tcq`),
- one ontology (`tbox.owl`)
- and temporal data, scaled by some factor `N` (`data/aboxes/N`)

## Generating the data

The data are already generated and available in this repository.
However, if data are to be re-generated, one can do so by calling `data/create_benchmarks.sh N` from this directory, where `N` is the maximum scaling factor to generate.
The benchmarks are probabilistic in the behavior of the generated two-wheelers, therefore it takes an optional seed as well.
We used a maximum scaling factor of 30 and the seed 1.

## Executing the benchmarks

We expect a functioning version of `topllet` in your `PATH`.
For installation inscrutions of topllet, refer to the [README](https://github.com/lu-w/topllet/).
The benchmarks can simply be executed by calling `./execute_benchmarks.sh -c` from this directory.
The results will then be located in `results/row.csv`.
