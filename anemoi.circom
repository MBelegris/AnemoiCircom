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

template wordPermutation(nInputs){
    signal input vector[nInputs];

    signal output out[nInputs];

    for (var i = 0; i < nInputs; i++){
        if ((i+1) > nInputs){
            out[i] = vector[0]
        }
        else{
            out[i] <== vector[i+1]
        }
    }
}

template diffusionLayer(nInputs){
    // The diffusion layer M: M(X,Y) = (Mx(X), My(Y))
    // Mx(X) = 
    // My(Y) = Mx o ρ(Y)
    // ρ(Y) = (y_1,...,y_l-1, y_0)
    signal input X[nInputs];
    signal input Y[nInputs]; 
    signal input g; // generator

    component wordPermutation = wordPermutation(nInputs);
    wordPermutation.vector <== Y;

    signal output outX[nInputs];
    signal output outY[nInputs];

    var matrix[nInputs][nInputs];

    if (nInputs == 1){
        outX <== X;
        outY <== wordPermutation.out;
    }
    else{
        if (nInputs == 2){
            // Based on diagram of Mx given in the Anemoi paper: Figure 7
            outX[0] <== g*X[1] + X[0];
            outX[1] <== g*X[0] + X[1];
            
            outY[0] <== g*wordPermutation.out[1] + wordPermutation.out[0];
            outY[1] <== g*wordPermutation.out[0] + wordPermutation.out[1];

        }
        if (nInputs == 3){
            // Based on diagram of Mx given in the Anemoi paper: Figure 7
            outX[0] <== (X[0] + g*X[2]) + ((X[2] + X[1]) + g*X[0]);
            outX[1] <== X[1] + X[0] + g*X[2];
            outX[2] <== X[2] + X[1] + g*X[0];

            outY[0] <== (wordPermutation.out[0] + g*wordPermutation.out[2]) + ((wordPermutation.out[2] + wordPermutation.out[1]) + g*wordPermutation.out[0]);
            outY[1] <== wordPermutation.out[1] + wordPermutation.out[0] + g*wordPermutation.out[2];
            outY[2] <== wordPermutation.out[2] + wordPermutation.out[1] + g*wordPermutation.out[0];
        }
        if (nInputs == 4){
            // Based on diagram of Mx given in the Anemoi paper: Figure 7
            outX[0] <== (X[0] + X[1]) + g*(X[1] + X[2] + X[3]);
            outX[1] <== g*(X[1] + X[2] + X[3]) + (X[2] + X[3] + g*(X[3] + g*(X[0] + X[1])));
            outX[2] <== X[2] + X[3] + g*(X[3] + g*(X[0] + X[1]));
            outX[3] <== X[0] + X[1] + g*(X[1] + X[2] + X[3]) + X[3] + g*(X[0] + X[1]);

            outY[0] <== (wordPermutation.out[0] + wordPermutation.out[1]) + g*(wordPermutation.out[1] + wordPermutation.out[2] + wordPermutation.out[3]);
            outY[1] <== g*(wordPermutation.out[1] + wordPermutation.out[2] + wordPermutation.out[3]) + (wordPermutation.out[2] + wordPermutation.out[3] + g*(wordPermutation.out[3] + g*(wordPermutation.out[0] + wordPermutation.out[1])));
            outY[2] <== wordPermutation.out[2] + wordPermutation.out[3] + g*(wordPermutation.out[3] + g*(wordPermutation.out[0] + wordPermutation.out[1]));
            outY[3] <== wordPermutation.out[0] + wordPermutation.out[1] + g*(wordPermutation.out[1] + wordPermutation.out[2] + wordPermutation.out[3]) + wordPermutation.out[3] + g*(wordPermutation.out[0] + wordPermutation.out[1]);
        }
        if (nInputs > 4){
            // TODO: Implement circulant mds matrix
        }
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
    signal c[5*numRounds]; 
    signal d[5*numRounds];

    for (var i = 0; i < numRounds; i++){
        c[i] <== roundConstantC;
        d[i] <== roundConstantD;
    }

    roundX[0] = X;
    roundY[0] = Y;

    component constantAddition[numRounds];
    component diffusionLayer[numRounds];

    for (var i = 0; i < 5*numRounds; i=i*5){
        // Constant Addition A
        constantAddition[i] = constantAddition(nInputs);
        constantAddition[i].c <== c;
        constantAddition[i].d <== d;
        constantAddition[i].X <== roundX[i]; 
        constantAddition[i].Y <== roundY[i]; 
        roundX[i+1] <== constantAddition[i].outX;
        roundY[i+1] <== constantAddition[i].outY;

        // Linear Layer M
        diffusionLayer[i] = diffusionLayer(nInputs);
        diffusionLayer[i].X <== roundX[i+1];
        diffusionLayer[i].X <== roundX[i+1];
        diffusionLayer[i].g <== g;
        roundX[i+2] <== diffusionLayer.outX;
        roundY[i+2] <== diffusionLayer.outY;

        // TODO: PHT P

        // TODO: S-box Layer H

    }
}
