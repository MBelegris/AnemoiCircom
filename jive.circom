pragma circom 2.0.0;
include "./anemoi.circom";

// Jive mode turns a permutation into a compression function
// Jive_b(P) = Sum(x_i + P(x_0,...,x_b-1))
// To be used for Merkle Trees

template jive_mode(b, numRounds, exp, inv_exp){
    // Implementation Jive Compression Function for b-to-1
    // In essence there are two inputs s.t. numInputs = 2b
    signal input X[b];
    signal input Y[b];
    signal input q; // The field over which the hash function is described (either an odd prime field or 2^n where n is odd)
    signal input isPrime;
    signal input g; // g is the generator found in Fq
    signal input inv_g; // The multiplicative inverse of g in Fq
    signal input roundConstantC[numRounds][b];
    signal input roundConstantD[numRounds][b];

    signal output out;

    signal accX[b];
    signal accY[b];

    component anemoi = Anemoi(b, numRounds, exp, inv_exp);
    anemoi.X <== X;
    anemoi.Y <== Y;
    anemoi.q <== q;
    anemoi.isPrime <== isPrime;
    anemoi.g <== g;
    anemoi.inv_g <== inv_g;
    anemoi.c <== roundConstantC;
    anemoi.d <== roundConstantD;

    for (var i = 0; i < b; i++){
        // log(anemoi.outX[i], "+", X[i], "+", anemoi.outY[i], "+", Y[i]);
        if (i == 0){
            accX[i] <== anemoi.outX[i] + X[i];
            accY[i] <== anemoi.outY[i] + Y[i];
        }
        else{
            accX[i] <== anemoi.outX[i] + X[i] + accX[i-1];
            accY[i] <==  anemoi.outY[i] + Y[i] + accY[i-1];
        }
    }
    out <== accX[b-1] + accY[b-1];
    log("Final result: ", out);
}

component main = jive_mode(1, 21, 5, 8755297148735710088898562298102910035419345760166413737479281674630323398247);