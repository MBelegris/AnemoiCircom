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

    for (var i = 1; i < nInputs; i++){
        out[i-1] <== vector[i];
    }
    out[nInputs-1] <== vector[0];
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

template PHT(nInputs){
    // PHT P does the following
    // Y <- Y + X
    // X <- X + Y
    signal input X[nInputs];
    signal input Y[nInputs];

    signal output outX[nInputs];
    signal output outY[nInputs];

    for (var i = 0; i < nInputs; i++){
        outY[i] <== Y[i] + X[i];
        outX[i] <== X[i] + outY[i];
    }
}

template openFlystel(nInputs){
    // Open Flystel network maps (x,y) to (u,v)
    // 1. x <- x - Qγ(y)
    // 2. y <- y - E^-1(x)
    // 3. x <- x + Qγ(y)
    // 4. y <- x, v <- y

    // Qγ = β(x^a) + γ
    // Qδ = β(x^a) + δ
    // E^-1 = x^1/a

    signal input x;
    signal input y;
    signal input alpha;
    signal input beta;
    signal input gamma;
    signal input delta;

    signal output u;
    signal output v;

    signal t; // as taken from the paper

    t = x - (beta*(x**alpha) + gamma);
    v <== y - (x**alpha);
    u <== outX + (beta*(outY**alpha) + delta);
}

template sBox(nInputs){
    // Let H be an open Flystel operating on Fq. Then Sbox S:
    // S(X, Y) = H(x0,y1),...,H(xl-1,yl-1)
    signal input X[nInputs];
    signal input Y[nInputs];
    signal input alpha;
    signal input beta;
    signal input gamma;
    signal input delta;


    signal output outX[nInputs];
    signal output outY[nInputs];

    component flystel = openFlystel(nInputs);

    for (var i = 0; i < nInputs; i++){
        flystel[i].x <== X[i];
        flystel[i].y <== Y[i];
        flystel[i].alpha <== alpha;
        flystel[i].beta <== beta;
        flystel[i].gamma <== gamma;
        flystel[i].delta <== delta;

        outX[i] <== flystel.u;
        outY[i] <== flystel.v;
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
    signal input exp; // The main exponent to be used in Qδ and Qγ (closed Flystel)
    signal input inv_exp; // The inverse of the exponent to be used in Qδ and Qγ (open Flystel)
    signal input g; // g is the generator found in Fq
    signal input inv_g; // The multiplicative inverse of g in Fq
    signal input roundConstantC;
    signal input roundConstantD;

    var security_level = 128;

    signal roundX[(4*numRounds) + 1][nInputs];
    signal roundY[(4*numRounds) + 1][nInputs];
    
    // Stores round constants for each round
    signal c[numRounds]; 
    signal d[numRounds];

    for (var i = 0; i < numRounds; i++){
        c[i] <== roundConstantC;
        d[i] <== roundConstantD;
    }

    roundX[0] <== X;
    roundY[0] <== Y;

    component constantAddition[numRounds];
    component diffusionLayer[numRounds];
    component phtLayer[numRounds];
    component sBox[numRounds];

    for (var i = 0; i < numRounds; i++){
        // Constant Addition A
        constantAddition[i] = constantAddition(nInputs);
        constantAddition[i].c <== c;
        constantAddition[i].d <== d;
        constantAddition[i].X <== roundX[4*i]; 
        constantAddition[i].Y <== roundY[4*i]; 
        roundX[(4*i)+1] <== constantAddition[i].outX;
        roundY[(4*i)+1] <== constantAddition[i].outY;

        // Linear Layer M
        diffusionLayer[i] = diffusionLayer(nInputs);
        diffusionLayer[i].X <== roundX[(4*i)+1];
        diffusionLayer[i].Y <== roundX[(4*i)+1];
        diffusionLayer[i].g <== g;
        roundX[(4*i)+2] <== diffusionLayer[i].outX;
        roundY[(4*i)+2] <== diffusionLayer[i].outY;

        // PHT P
        phtLayer[i] = PHT(nInputs);
        phtLayer[i].X <== roundX[(4*i) + 2];
        phtLayer[i].Y <== roundY[(4*i) + 2];
        roundX[(4*i) + 3] <== phtLayer[i].outX;
        roundY[(4*i) + 3] <== phtLayer[i].outY;

        // S-box Layer H
        // Implementing Qγ(x) = gx^a + g^-1
        // Implementing Qδ(x) = gx^a
        // Implementing E^-1 = x^1/a
        sBox[i] = sBox(nInputs);
        sBox[i].X <== roundX[(4*i) + 3];
        sBox[i].Y <== roundY[(4*i) + 3];
        sBox[i].alpha <== inv_exp; // Value is equivalent to 1/a so E^inv_exp = E^1/a
        sBox[i].beta <== g;
        sBox[i].gamma <== inv_g;
        sBox[i].delta <== 0;
        roundX[(4*i) + 4] <== sBox.outX;
        roundY[(4*i) + 4] <== sBox.outY;
    }
}
