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

template constantAddition(nInputs){
    signal input c[nInputs];
    signal input d[nInputs];

    signal input X[nInputs];
    signal input Y[nInputs];

    signal output outX[nInputs];
    signal output outY[nInputs];
    
    for (var i=0; i < nInputs; i++){
        outX[i] <== X[i] + c[i];
        outY[i] <== Y[i] + d[i];    
    }
}

template Anemoi(nInputs, numRounds){
    // State of Anemoi is a 2 row matrix:
    // X[x_0,...,x_l-1]
    // Y[y_0,...,y_l-1]

    signal input X[nInputs]; 
    signal input Y[nInputs];
    signal input q; // The field over which the hash function is described (either an odd prime field or 2^n where n is odd)
    signal input isPrime;
    signal input exp; // The main exponent to be used in Qδ and Qγ
    signal input g; // g is the generator found in Fq
    signal input inv_g; // The multiplicative inverse of g in Fq
    signal input roundConstantC;
    signal input roundConstantD;

    var security_level = 128;
    var a = 3; // The main exponent found in the flystel

    signal roundX[numRounds + 1][nInputs];
    signal roundY[numRounds + 1][nInputs];
    
    // Stores round constants for each round
    signal c[numRounds]; 
    signal d[numRounds];

    for (var i = 0; i < numRounds; i++){
        c[i] <== roundConstantC;
        d[i] <== roundConstantD;
    }

    roundX[0] = X;
    roundY[0] = Y;

    component constantAddition[numRounds];

    for (var i = 0; i < numRounds; i++){
        // Constant Addition A

        constantAddition[i] = constantAddition(nInputs);
        constantAddition[i].c <== c;
        constantAddition[i].d <== d;
        constantAddition[i].X <== roundX[i]; 
        constantAddition[i].Y <== roundY[i]; 
        roundX[i+1] <== constantAddition[i].outX;
        roundY[i+1] <== constantAddition[i].outY;

        // TODO: Linear Layer M

        // TODO: PHT P

        // TODO: S-box Layer H

    }
}

// INPUT = {
//     "X": "", 
//     "Y": "",
//     "q": "",
//     "isPrime": "", 
//     "exp": "", 
//     "g": "", 
//     "inv_g": "", 
//     "numRounds": ""
// }
