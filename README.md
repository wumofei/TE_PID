# Transfer Entropy Partial Information Decomposition

Compute partial information decomposition (PID) of transfer entropy between time-series. The redundancy partial information term is given by the minimum information function described by Timme et al., 2016.

Also includes some plotting capabilities, as well as extraction of functional and recruitment matrices.

# Table of Contents
<!--ts-->
   * [Transfer Entropy Partial Information Decomposition](#transfer-entropy-partial-information-decomposition)
   * [Table of Contents](#table-of-contents)
   * [Dependencies](#dependencies)
   * [Usage](#usage)
      * [Examples](#examples)
      * [Sample workflow](#sample-workflow)
         * [Inputs](#inputs)
         * [Command window](#command-window)
         * [Outputs](#outputs)
            * [Folder](#folder)
            * [Workspace](#workspace)
   * [Functions](#functions)
      * [Call structure](#call-structure)
      * [TE_PID.m](#te_pidm)
         * [Parameters](#parameters)
         * [Outputs](#outputs-1)
      * [TE.m](#tem)
         * [Parameters](#parameters-1)
         * [Outputs](#outputs-2)
      * [I_min_TE.m](#i_min_tem)
         * [Parameters](#parameters-2)
         * [Outputs](#outputs-3)
   * [Complexity](#complexity)
   * [Bugs](#bugs)
   * [References](#references)
   * [Authors](#authors)

<!-- Added by: mofei, at: Wed Oct 20 14:06:59 EDT 2021 -->

<!--te-->

# Dependencies

* MATLAB R2019a: all functions found here are `.m` files. Various MATLAB in-built functions are called.

# Usage

We identify a neuron with its time-series/spike-train. To calculate transfer entropy PID for all possible neuron triplets, call `TE_PID.m` with 3 required arguments: an output filename, a matrix or cell, and a positive integer time-delay. For an input cell containing multiple matrices for multiple trials, the input cell must be 1-dimensional. Each matrix or cell column should contain the entire time-series of a single neuron, i.e. columns should represent neurons while rows represent observations at incremental times. Optionally, supply a list of neuron triplet indices for which to calculate PID. Otherwise, PID is calculated for all possible triplets. Optionally, supply a positive integer time-resolution at which to time bin input data.

Outputs are written to a separate file. 7 columns indicate in increasing order: *target_index*, *source1_index*, *source2_index*, *synergy*, *redundancy*, *unique1*, *unique2*. PID output terms are given in units of bits. Each row of the output matrix contains terms for a specific triplet.

Additionally, the entropy of each neuron is calculated and recorded to facilitate normalization of information terms by the entropy of the target neuron.

## Examples

Call `TE_PID.m` with test case matrix variables `{identity, xor, and}` stored in `test_logicgates.mat` and time-delay `1`.

```
>> cd ~/TE_PID  
>> load test_logicgates.mat  
>> TE_PID('identity_output.csv', identity, 1, [1 2 3]);   
...  
>> type identity_output.csv  

...  
Target, Source1, Source2, Synergy, Redundancy, Unique1, Unique2  
1, 2, 3, 0, 0, 1, 0  
>> TE_PID('xor_output.csv', xor, 1, [1 2 3]);  
...  
>> type xor_output.csv

...  
Target, Source1, Source2, Synergy, Redundancy, Unique1, Unique2  
1, 2, 3, 1, 0, 0, 0  
>> TE_PID('and_output.csv', and, 1, [1 2 3]);  
...  
>> type and_output.csv  

...  
Target, Source1, Source2, Synergy, Redundancy, Unique1, Unique2  
1, 2, 3, 0.5, 0.311278, 5.55112e-17, 5.55112e-17  
```

In all three test variables, the first column contains the target time-series of interest. Therefore, we check the first row of the output matrix where `target_index` = 1 to verify that our code returns values as expected. Note that since transfer entropy splits the target time-series into a future time-series and a past time-series, test cases have their first column shifted by one.

As expected, all transfer entropy information is found in *unique1* for the `identity` test case, *synergy* for the `xor` relation.

In the case of `and`, small values obtain for *unique1* and *unique2*, contrary to the expected zero value. This may be due to rounding error.

## Sample workflow

### Inputs

`spiketrain.mat`: *n*x*m* matrix of *m* neurons, each with *n* time steps.

`synaptic_matrix.mat`: *m*x*m* matrix of synaptic weights between *m* neurons.

### Command window

```
>> load spiketrain.mat  
>> load synaptic_matrix.mat  
>> time_resolution = 20;  
>> time_delay = 1;  
>> spiketrain = timebin(spiketrain, time_resolution);  
>> nNeuron = size(spiketrain,2);  % number of neurons  
>> TE_PID('output.csv', spiketrain, time_delay);  
...  
>> all_PID = readmatrix('output.csv', 'Range', nNeuron+3);  
>> entropies = readmatrix('output.csv', 'Range', '2:(nNeuron+1)');  
>> [functional_list, functional_matrix, delta_w, TE_matrix] = functional(spiketrain, time_delay);  
>> [recruit_list, recruit_matrix] = recruitment(functional_matrix, synaptic_matrix);  
>> functional_PID = PID_extract(all_PID, functional_list);  
>> recruit_PID = PID_extract(all_PID, recruit_list);  
>> corr_functional_synaptic = compare_matrix(TE_matrix, synaptic_matrix);  
>> [corr_source_out, corr_target_in] = degree_synergy(functional_PID, functional_matrix, entropies, functional_list);  
>> fig = PID_plot(all_PID, functional_PID, recruit_PID);  
```

### Outputs

#### Folder

`output.csv`: entropy of all neurons, and transfer PID values for all active neuron triplets.

#### Workspace

`time_resolution`: scalar at which to time-bin input time-series. In units of time-steps.

`time_delay`: scalar at which to stagger future time-series form past time-series. In units of time-steps after time-binning.

`nNeuron`: scalar. Number of neurons, i.e. *m*.

`all_PID`: 7-column matrix of transfer PID values for all active neuron triplets.

`entropies`: 2-column matrix of neuron index and neuron entropy.

`functional_list`: 3-column matrix of neuron indices forming a functional fan-in triplet where transfer entropies from source neurons in the 2nd and 3rd columns to the target neuron in the 1st column are both greater than zero. Note that this is a subset of `all_PID(:,1:3)`.

`functional_matrix`: *m* by *m* matrix of functional weights between all *m* neurons. Bidirectional connections occurs only if transfer entropy in both directions are equal for a given neuron pair.

`delta_w`: vector of differences between functional weights *w(ij)* and *w(ji)* for non-zero transfer entropies.

`TE_matrix`: *m* by *m* matrix of functional weights between all *m* neurons, without setting to zero the smaller of *w(ij)* and *w(ji)* for all neuron pairs.

`recruit_list`: 3-column matrix of neuron indices forming a recruitment fan-in triplet. Note that this is a subset of both `all_PID(:,1:3` and `functional_list`.

`recruit_mat`: *m* by *m* matrix of recruitment weights between all *m* neurons. Note that this is a subset of `functional_mat`.

`functional_PID`: subset of `all_PID` limited to functional fan-in triplets.

`recruit_PID`: subset of `all_PID` limited to recruitment fan-in triplets.

`corr_functional_synaptic`: correlation coefficient between functional weights and corresponding synaptic weights.

`corr_source_out`: correlation coefficient between synergy and out-degree of source neurons.

`corr_target_in`: correlation coefficient between synergy and in-degree of target neuron.

`fig`: figure object plotting histograms of synergy, redundancy, and unique PID values for all triplets, functional triplets, and recruitment triplets. Use `findobj` to adjust axes or histogram properties.

# Functions

## Call structure

| Parent function      | Child function                    |
|----------------------|-----------------------------------|
| `TE_PID.m`           | `I_min_TE.m` `TE.m` `timebin.m`   |
| `I_min_TE.m`         | `I_spec.m`                        |
| `functional.m`       | `TE.m`                            |
| `TE.m`               | `cond_MI.m`                       |

## `TE_PID.m`

`TE_PID(output_filename, input_timeseries, delay, triplet_list, resolution)`

Given input time-series matrices and a scalar time-delay, calculate PID terms for transfer entropy.

### Parameters

`output_filename`: string or char. Recommend .csv files.

`input_timeseries`: matrix or 1-dimensional cell. Columns should contain entire time-series of a given neuron.

`delay`: positive integer scalar time-delay necessary for transfer entropy.

`triplet_list`: optional 3-column matrix of neuron indices. The first column should represent the target neuron index. If `input_timeseries` is a cell, then `triplet_list` should either be a cell with equal dimensions—each cell element containing a triplet list—or a matrix—in which case PID calculations for all trials are restricted to triplets contained in the single matrix. If not given, PID is calculated for all possible triplets. Triplets containing neurons with zero entropy are discarded.

`resolution`: optional positive integer scalar. Time bins at given `resolution` by partitioning input time-series. If a `1` occurs within a partition, a `1` is recorded. Otherwise, a `0` is recorded. Note that if you time bin, the `delay` used to calculate transfer entropy applies to the *time-series* after it has been time binned.

### Outputs

`output_filename`: file. Recommend .csv format. 7 comma-separated columns indicating in increasing order: `target_index`, `source1_index`, `source2_index`, `synergy`, `redundancy`, `unique1`, `unique2`. Each row corresponds to a specific triplet. PID terms are given in units of bits. Entropy for each neuron is also calculated separately.

## `TE.m`

`[transfer_entropy, normed_TE] = TE(target, source, delay)`

Calculate transfer entropy in bits at given delay from input source time-series to input target time-series.

### Parameters

`target`: vector or matrix. Time-steps should be represented as rows.

`source`: vector or matrix. Time-steps should be represented as rows.

`delay`: positive integer scalar.

### Outputs

`transfer_entropy`: positive scalar. Transfer entropy from `source` to `target` in units of bits.

`normed_TE`: positive scalar. `transfer_entropy` normalized by entropy of future time-series of `target`, i.e. `target` with the first *X* time-steps removed, where *X* = `delay`. Output is a ratio, thus dimensionless.

## `I_min_TE.m`

`[min_info] = I_min_TE(target, source1, source2, delay)`

Calculate minimum information from `source1` and `source2` to `target` using transfer entropy and the given `delay`.

### Parameters

`target`: vector or matrix. Time-steps should be represented as rows.

`source1`: vector or matrix. Time-steps should be represented as rows.

`source2`: vector or matrix. Time-steps should be represented as rows.

`delay`: positive integer scalar.

### Outputs

`min_info`: positive scalar.

# Complexity

For input of size *n* neurons by *m* timebins, current time complexity should be *O(mn^3)*. Specifically, the number of targeted neuron triplets is 3 \* (*n* choose 3), or *O(n^3)*. For each targeted triplet, various probabilities and joint probabilities are calculated by traversing the time-series multiple times and counting instances, at *O(m)*. Though I struggle to see how asymptotic time can be reduced, wall-clock time should allow improvement.

For each triplet comprising target I and sources J, K---denoted (I; J, K)---four terms need to be calculated: minimum information from (J, K) to I, transfer entropy from (J, K) to I, transfer entropy from J to I, and transfer entropy from K to I. The first two terms are unique to each triplet, whereas the latter two terms are shared between multiple triplets. For example, transfer entropy from J to I is used not only in triplet (I; J, K), but also triplet (I; J, L). Currently, 2-ary transfer entropy terms are calculated first before moving on to the 3-ary transfer entropy and minimum information terms to avoid repeated calculations. Further optimization, however, is still possible.

For each time-series X, p(x) is used to calculate minimum information if X is the target, transfer entropy if X is the target, as well as the entropy of X. For minimum information and transfer entropy, p(x) should be calculated for both past and future time-series by applying the input time-delay. Such terms should be calculated first to avoid repetition.

For each time-series X, joint probability p(x\_past, x\_future) is used to calculate minimum information if X is the target, and transfer entropy if X is the target. Currently, this term is calculated once every pair for transfer entropy, and once every triplet for minimum information.

For all time-series X, Y where X != Y, joint probabilities p(x\_past, y\_past) and p(x\_past, y\_past, y\_future) are used to calculate minimum information if X is a source and Y is the target, as well as transfer entropy from X to Y.

For triplet (I; J, K), minimum information is calculated by taking the minimum over sources J, K of the specific information between I and J, and between I and K. Such specific information should be stored rather than recalculated for every triplet, since, for example, the specific information between I and J is also needed to calculate minimum information for triplet (I; J, L).

Space complexity has generally not been a problem with binary time-series on the order of *n*=1000 neurons and *m*=10,000 timebins. Currently, 2-ary targeted transfer entropy is calculated first and stored, using *O(n^2)* space. For the proposed changes above, the highest order term to be calculated is still 2-ary, so asymptotic space usage should not increase. Note that MATLAB handles pass-by-reference under the hood, given that the parameter is not altered within the function.

Further optimization is possible at the cost of input generality. For example, current code is amenable to non-binary time-series, as well as calculating conditional mutual information between any three time-series, not just time-delayed time-series.

# Bugs

* `I_spec.m` and `cond_MI.m` may condition on events with zero probability. For now, all cases involving zero probability are discarded. Such a decision may require theoretical justification. Possible alternative solutions include:
  * Time-binning. For Yuqing's model, all AdEx neurons have some time constant *tau*. Might make sense to bin at time resolution equal to *tau*.
  * Choosing an arbitrarily small value in place of probability zero, e.g. `eps` in MATLAB.

* Non-zero values (both positive and negative) with small magnitude may obtain when value zero is expected. Possible reasons include:  
  * Rounding error may occur. Information measures in `I_spec.m` and `cond_MI.m` require both ratios of probabilities as well as the absolute value of probabilities. Ratio calculations use the number of occurrences unnormalized by the total length of the time-series, whereas the absolute value probabilities are divided by the total length.

# References

Williams, Paul L. and Randall D. Beer. "Nonnegative Decomposition of Multivariate Information." *CoRR* abs/1004.2515 (2010). url: http://arxiv.org/abs/1004.2515v1.

Williams and Beer. "Generalized Measures of Information Transfer." abs/1102.1507 (2011). url: https://arxiv.org/abs/1102.1507v1.

Timme, Nicholas, Wesley Alford, Benjamin Flecker, and John M. Beggs. "Synergy, Redundancy, and Multivariate Information Measures." *J Comput Neurosci* 36(2014): 119-140. doi: 10.1007/s10827-013-0458-4.

Timme et al. "High-Degree Neurons Feed Cortical Computations." *PLoS Comput Biol* 12(5):e1004858 (2016). doi: 10.1371/journal.pcbi.1004858.

# Authors

* Mofei Wu  
mofei@uchicago.edu  
mwumofei@gmail.com  
