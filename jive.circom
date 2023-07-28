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

    signal acc[b];

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
            acc[i] <== anemoi.outX[i] + X[i] + anemoi.outY[i] + Y[i];
        }
        else{
            acc[i] <== anemoi.outX[i] + X[i] + anemoi.outY[i] + Y[i] + acc[i-1];
        }
    }
    out <== acc[b-1];
    log("Final result: ", out);
}
// Change these values when using different inputs
component main = jive_mode(2, 14, 8755297148735710088898562298102910035478524462919129465075615157858090483433, 5);