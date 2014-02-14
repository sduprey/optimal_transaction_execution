This entry contains two topics 
The first item is entirely based on the following paper: 
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

The second item is entirely based on the following paper : 
http://www.courant.nyu.edu/~almgren/papers/optliq.pdf 

It contains a mupad document : symbolic_demo.mn 
I did struggle to get something nice with the symbolic toolbox. 
I was not able to drive a continuous workflow and had to recode some equations myself. 
I nevertheless managed to get a closed form solution for the simplified linear cost model. 

It contains a MATLAB demonstrating script : working_script.m 
For more sophisticated cost model, there is no more closed form 
and we there highlighted MATLAB numerical optimization abilities (fmincon). 

It contains an Optimization Apps you can install. 
Just launch the optimization with the default parameters. 
And then switch the slider between volatility risk and liquidation costs 
to see the trading strategies evolve on the efficient frontier. 

It contains a power point to help you present this complex topic. 
