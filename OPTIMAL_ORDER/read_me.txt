This demo is entirely based on the following paper:
http://sfb649.wiwi.hu-berlin.de/papers/pdf/SFB649DP2011-056.pdf

It contains 2 MATLAB demonstrating script : DATA_preprocessing.m & VAR_modeling_script.m
DATA_preprocessing.m uses the LOBSTER framework (https://lobster.wiwi.hu-berlin.de/) to preprocess high frequency data from
the NASDAQ Total View ITCH (csv files) allowing us to reconstruct exactly at each time the order book up
to ten depths. Just look at the published script !

VAR_modeling_script.m contains the modeling of the whole order book as VEC/VAR process.
It uses the great VAR/VEC Joahnsen cointegration framework.
After calibrating your VAR model, you then assess the impact of an order 
using shock scenario (sensitivity analysis) to the VAR process.
We deal with 3 scenarii : normal limit order, aggressive limit order & normal market order).
Play section by section the script (to open up figures which contain a lot of graphs).

It contains a power point to help you present this complex topic.
Beware you might want to hide some of the slides !!



