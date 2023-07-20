pragma circom 2.0.0;

// Anemoi Hash Function
// Steps:
// For each round:
// 1. Constant Addtion
// 2. Linear Layer
// 3. PHT
// 4. S-box layer H (flystel network)
// Final step:
// Linear Layer


template Anemoi(nInputs){
    signal input X[nInputs];
    signal input Y[nInputs];
    signal input q;
    signal input a;
    signal input l;
    
}