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

template getNumRounds(nInputs){
    // Given that s = 128, a={3,5,7,11} and l={1,2,3,4,6,8}
    signal input alpha;

    signal output out;
    
    var arr[4][6] = [[21,21,20,19], // Values taken from paper
                [14,14,13,13],
                [12,12,11,11],
                [10,10,10,10],
                [10,10,9,9]];
    
    if (nInputs < 5){
        if (alpha == 3){
            out <== arr[0][nInputs-1];
        }
        if (alpha == 5){
            out <== arr[1][nInputs-1];
        }
        if (alpha == 7){
            out <== arr[2][nInputs-1];
        }
        if (alpha == 11){
            out <== arr[3][nInputs-1];
        }
    }
    else {
        if (nInputs == 6){
            if (alpha == 3){
            out <== arr[0][4];
            }
            if (alpha == 5){
                out <== arr[1][4];
            }
            if (alpha == 7){
                out <== arr[2][4];
            }
            if (alpha == 11){
                out <== arr[3][4];
            }
        }
        else{
            if (alpha == 3){
            out <== arr[0][5];
            }
            if (alpha == 5){
                out <== arr[1][5];
            }
            if (alpha == 7){
                out <== arr[2][5];
            }
            if (alpha == 11){
                out <== arr[3][5];
            }
        }
    }
}

template getRoundConstants(nCol) {
    signal input alpha;
    signal input g;
    signal input inv_g;
    signal input q;
    var pi_0 = 1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679;
    var pi_1 = 8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196;

    signal tmp[nCol];
    signal output c[nCol];
    signal output d[nCol];

    for (var i = 0; i < nCol; i++) {
        var const1 = (pi_0 + pi_1)**alpha;

        tmp[i] <== const1; // Introduce a temporary variable to store const1

        c[i] <== g*(pi_0**2) + tmp[i]; // Quadratic constraint
        d[i] <== g*(pi_1**2) + tmp[i] + inv_g; // Quadratic constraint
    }
}


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
    // signal input ; // Number of rounds to run round function

    var security_level = 128;
    var a = 3; // The main exponent found in the flystel

    component getRoundConstants = getRoundConstants(nInputs);
    getRoundConstants.alpha <== a;
    getRoundConstants.g <== g;
    getRoundConstants.inv_g <== inv_g;
    getRoundConstants.q <== q;

    signal c <== getRoundConstants.c; // Constants C
    signal d <== getRoundConstants.d; // Constants D

    signal roundX[numRounds + 1][nInputs];
    signal roundY[numRounds + 1][nInputs];

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

component main = Anemoi(2, 2);
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
