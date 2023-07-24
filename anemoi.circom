pragma circom 2.0.0;

// Anemoi Hash Function
// Steps:
// For each round:
// 1. Constant Addition
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

template exponentiate(exponent){
    signal input in;
    signal output out;

    signal stor[exponent];

    stor[0] <== in;

    for (var i = 1; i < exponent; i++){
        stor[i] <== stor[i-1] * in;
        log("Exponentiate: ", stor[i]);
    }
    out <== stor[exponent-1];
}

template openFlystel(nInputs, alpha){
    // Open Flystel network H maps (x,y) to (u,v)
    // 1. x <- x - Qγ(y)
    // 2. y <- y - E^-1(x)
    // 3. x <- x + Qγ(y)
    // 4. y <- x, v <- y

    // Qγ = β(x^a) + γ
    // Qδ = β(x^a) + δ
    // E^-1 = x^1/a

    signal input x;
    signal input y;
    signal input beta;
    signal input gamma;
    signal input delta;

    signal output u;
    signal output v;

    signal t; // as taken from the paper

    component const1 = exponentiate(alpha);
    const1.in <== x;

    component const2 = exponentiate(alpha);
    component const3 = exponentiate(alpha);

    t <== x - (beta*const1.out + gamma);
    const2.in <== t;
    v <== y - const2.out;
    const3.in <== v;
    u <== t + (beta*const3.out + delta);
}

template closedFlystel(nInputs, alpha){
    // Closed Flystel verifies that (x,u) = V(y,v)
    // Equivalent to checking if (u,v) = H(x,y)
    // x = Qγ(y) + E(y-v)
    // v = Qδ(v) + E(y-v)

    signal input y;
    signal input v;

    signal input beta;
    signal input gamma;
    signal input delta;

    signal output x;
    signal output u;

    signal sub;
    sub <== y - v;

    component const1 = exponentiate(alpha);
    const1.in <== y;

    component const2 = exponentiate(alpha);
    const2.in <== sub;

    component const3 = exponentiate(alpha);
    const3.in <== v;

    x <== (beta*const1.out) + gamma + const2.out;
    u <== (beta*const3.out) + delta + const2.out;
}

template sBox(nInputs, alpha){
    // Let H be an open Flystel operating on Fq. Then Sbox S:
    // S(X, Y) = H(x0,y1),...,H(xl-1,yl-1)
    signal input X[nInputs];
    signal input Y[nInputs];
    signal input beta;
    signal input gamma;
    signal input delta;

    signal output outX[nInputs];
    signal output outY[nInputs];

    component flystel[nInputs];

    for (var i = 0; i < nInputs; i++){       
        flystel[i] = openFlystel(nInputs, alpha);
        flystel[i].x <== X[i];
        flystel[i].y <== Y[i];
        flystel[i].beta <== beta;
        flystel[i].gamma <== gamma;
        flystel[i].delta <== delta;
            
        outX[i] <== flystel[i].u;
        outY[i] <== flystel[i].v;
    }
}

template sBoxVerify(nInputs, alpha){
    // TODO: add verification algorithm to 
    // Let H be an closed Flystel operating on Fq. Then Sbox S:
    // S(X, Y) = H(x0,y1),...,H(xl-1,yl-1)
    signal input Y[nInputs];
    signal input V[nInputs];
    signal input beta;
    signal input gamma;
    signal input delta;

    signal output outX[nInputs];
    signal output outU[nInputs];

    component flystel[nInputs];

    for (var i = 0; i < nInputs; i++){       
        flystel[i] = closedFlystel(nInputs, alpha);
        flystel[i].y <== Y[i];
        flystel[i].v <== V[i];
        flystel[i].beta <== beta;
        flystel[i].gamma <== gamma;
        flystel[i].delta <== delta;
            
        outX[i] <== flystel[i].x;
        outU[i] <== flystel[i].u;
    }
}

template Anemoi(nInputs, numRounds, exp, inv_exp){
    // State of Anemoi is a 2 row matrix:
    // X[x_0,...,x_l-1]
    // Y[y_0,...,y_l-1]

    signal input X[nInputs]; 
    signal input Y[nInputs];
    signal input q; // The field over which the hash function is described (either an odd prime field or 2^n where n is odd)
    signal input isPrime;
    signal input g; // g is the generator found in Fq
    signal input inv_g; // The multiplicative inverse of g in Fq
    signal input roundConstantC;
    signal input roundConstantD;

    signal output outX[nInputs];
    signal output outY[nInputs];

    signal roundX[(4*numRounds) + 1][nInputs];
    signal roundY[(4*numRounds) + 1][nInputs];

    signal verifyX[numRounds][nInputs];
    signal verifyU[numRounds][nInputs];
    
    // Stores round constants for each round
    signal c[nInputs]; 
    signal d[nInputs];

    for (var i = 0; i < nInputs; i++){
        c[i] <== roundConstantC;
        d[i] <== roundConstantD;
    }

    roundX[0] <== X;
    roundY[0] <== Y;

    component constantAddition[numRounds];
    component diffusionLayer[numRounds + 1];
    component phtLayer[numRounds];
    component sBox[numRounds];

    component verify[numRounds];

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
        sBox[i] = sBox(nInputs, inv_exp);
        sBox[i].X <== roundX[(4*i) + 3];
        sBox[i].Y <== roundY[(4*i) + 3];
        sBox[i].beta <== g;
        sBox[i].gamma <== inv_g;
        sBox[i].delta <== 0;
        roundX[(4*i) + 4] <== sBox[i].outX;
        roundY[(4*i) + 4] <== sBox[i].outY;

        // Verifying the output of the sBox
        // verify[i] = sBoxVerify(nInputs, exp);
        // verify[i].Y <== roundY[(4*i) + 3]; // original y
        // verify[i].V <== roundY[(4*i) + 4]; // new y
        // verify[i].beta <== g;
        // verify[i].gamma <== inv_g;
        // verify[i].delta <== 0;

        // verify[i].outX === roundX[(4*i) + 3];
        // verify[i].outU === roundX[(4*i) + 4];
    }
    // One final diffusion before returning the Anemoi permutation
    diffusionLayer[numRounds] = diffusionLayer(nInputs);
    diffusionLayer[numRounds].X <== roundX[4*numRounds];
    diffusionLayer[numRounds].Y <== roundY[4*numRounds];
    diffusionLayer[numRounds].g <== g;

    outX <== diffusionLayer[numRounds].outX;
    outY <== diffusionLayer[numRounds].outY;
}

component main = Anemoi(1,19, 8384883667915720146, 11);