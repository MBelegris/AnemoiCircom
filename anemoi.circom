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
    // x and y are added by the the round constants for that specific round
    signal input c[nInputs];
    signal input d[nInputs];

    signal input X[nInputs];
    signal input Y[nInputs];

    signal output outX[nInputs];
    signal output outY[nInputs];
    
    for (var i=0; i < nInputs; i++){
        log("Round Constant C:", c[i]);
        log("Round Constant D:", d[i]);
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
        component g_squared = exponentiate(2);
        g_squared.in <== g;
        if (nInputs == 2){
            outX[0] <== X[0] + (X[1]*g);
            signal inter_x[3];
            inter_x[0] <== g_squared.out + 1;
            inter_x[1] <== X[1] * inter_x[0];
            inter_x[2] <== (X[0] * g) + inter_x[1];
            outX[1] <== inter_x[2];

            signal inter_y[3];
            inter_y[0] <== g_squared.out + 1;
            inter_y[1] <== wordPermutation.out[1] * inter_y[0];
            inter_y[2] <== (wordPermutation.out[0]*g) + inter_y[1];
            outY[0] <== wordPermutation.out[0] + (wordPermutation.out[1]*g);
            outY[1] <== inter_y[2];
        }
        if (nInputs == 3){
            signal inter_x0[3];
            inter_x0[0] <== X[0] * (g+1);
            inter_x0[1] <== X[1] + inter_x0[0];
            inter_x0[2] <== (X[2] * (g+1)) + inter_x0[1];

            signal inter_x1[3];
            inter_x1[0] <== X[0];
            inter_x1[1] <== X[1] + inter_x1[0];
            inter_x1[2] <== (X[2] * g) + inter_x1[1];

            signal inter_x2[3];
            inter_x2[0] <== X[0] * g;
            inter_x2[1] <== X[1] + inter_x2[0];
            inter_x2[2] <== X[2] + inter_x2[1];

            outX[0] <== inter_x0[2];
            outX[1] <== inter_x1[2];
            outX[2] <== inter_x2[2];

            
            signal inter_y0[3];
            inter_y0[0] <== wordPermutation.out[0] * (g+1);
            inter_y0[1] <== wordPermutation.out[1] + inter_y0[0];
            inter_y0[2] <== (wordPermutation.out[2] * (g+1)) + inter_y0[1];

            signal inter_y1[3];
            inter_y1[0] <== wordPermutation.out[0];
            inter_y1[1] <== wordPermutation.out[1] + inter_y1[0];
            inter_y1[2] <== (wordPermutation.out[2] * g) + inter_y1[1];
            
            signal inter_y2[3];
            inter_y2[0] <== wordPermutation.out[0] * g;
            inter_y2[1] <== wordPermutation.out[1] + inter_y2[0];
            inter_y2[2] <== wordPermutation.out[2] + inter_y2[1];

            outY[0] <== inter_y0[2];
            outY[1] <== inter_y1[2];
            outY[2] <== inter_y2[2];
        }
        if (nInputs == 4){
            signal inter_x0[4];
            inter_x0[0] <== X[0];
            inter_x0[1] <== X[1]*(1+g);
            inter_x0[2] <== X[2]*g;
            inter_x0[3] <== X[3]*g;
            
            signal inter_x1[4];
            inter_x1[0] <== X[0]*g_squared.out;
            inter_x1[1] <== X[1]*(g+g_squared.out);
            inter_x1[2] <== X[2]*(1+g);
            inter_x1[3] <== X[3]*(1+(2*g));

            signal inter_x2[4];
            inter_x2[0] <== X[0]*g_squared.out;
            inter_x2[1] <== X[1]*g_squared.out;
            inter_x2[2] <== X[2];
            inter_x2[3] <== X[3]*(1+g);
            
            signal inter_x3[4];
            inter_x3[0] <== X[0]*(1+g);
            inter_x3[1] <== X[1]*(1+(2*g));
            inter_x3[2] <== X[2]*g;
            inter_x3[3] <== X[3]*(1+g);

            outX[0] <== inter_x0[3] + inter_x0[2] + inter_x0[1] + inter_x0[0];
            outX[1] <== inter_x1[3] + inter_x1[2] + inter_x1[1] + inter_x1[0];
            outX[2] <== inter_x2[3] + inter_x2[2] + inter_x2[1] + inter_x2[0];
            outX[3] <== inter_x3[3] + inter_x3[2] + inter_x3[1] + inter_x3[0];

            signal inter_y0[4];
            inter_y0[0] <== wordPermutation.out[0];
            inter_y0[1] <== wordPermutation.out[1]*(1+g);
            inter_y0[2] <== wordPermutation.out[2]*g;
            inter_y0[3] <== wordPermutation.out[3]*g;
            
            signal inter_y1[4];
            inter_y1[0] <== wordPermutation.out[0]*g_squared.out;
            inter_y1[1] <== wordPermutation.out[1]*(g+g_squared.out);
            inter_y1[2] <== wordPermutation.out[2]*(1+g);
            inter_y1[3] <== wordPermutation.out[3]*(1+(2*g));

            signal inter_y2[4];
            inter_y2[0] <== wordPermutation.out[0]*g_squared.out;
            inter_y2[1] <== wordPermutation.out[1]*g_squared.out;
            inter_y2[2] <== wordPermutation.out[2];
            inter_y2[3] <== wordPermutation.out[3]*(1+g);
            
            signal inter_y3[4];
            inter_y3[0] <== wordPermutation.out[0]*(1+g);
            inter_y3[1] <== wordPermutation.out[1]*(1+(2*g));
            inter_y3[2] <== wordPermutation.out[2]*g;
            inter_y3[3] <== wordPermutation.out[3]*(1+g);

            outY[0] <== inter_y0[3] + inter_y0[2] + inter_y0[1] + inter_y0[0];
            outY[1] <== inter_y1[3] + inter_y1[2] + inter_y1[1] + inter_y1[0];
            outY[2] <== inter_y2[3] + inter_y2[2] + inter_y2[1] + inter_y2[0];
            outY[3] <== inter_y3[3] + inter_y3[2] + inter_y3[1] + inter_y3[0];
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

    signal stor[exponent+1];

    for (var i = 0; i < exponent; i++){
        if (i == 0){
            stor[i] <== in;
            // log("Stor ", i, stor[i]);
        }
        else{
            stor[i] <== stor[i-1] * in;
            // log("Stor ", i, ":", stor[i-1], "*", in, "=", stor[i]);
        }
    }
    out <== stor[exponent-1];
}

template openFlystel(alpha){
    log("In Open Flystel");
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

    component y_squared = exponentiate(2);
    y_squared.in <== y;

    t <== x - (beta*y_squared.out) - gamma;
    log("t:", t);
    
    component t_power_inv_a = exponentiate(alpha);
    t_power_inv_a.in <== t;

    v <== y - t_power_inv_a.out;
    log("v:",v);

    component v_squared = exponentiate(2);
    v_squared.in <== v;

    u <== t + (beta*v_squared.out) + delta;
    log("u:",u);

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
        flystel[i] = openFlystel(alpha);
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
    signal input c[numRounds][nInputs];
    signal input d[numRounds][nInputs];

    log("Exponent:", exp);
    log("Inverse Exponent:", inv_exp);
    log("Generator:", g);
    log("Inverse Generator:", inv_g);

    signal output outX[nInputs];
    signal output outY[nInputs];

    signal roundX[(4*numRounds) + 1][nInputs];
    signal roundY[(4*numRounds) + 1][nInputs];

    signal verifyX[numRounds][nInputs];
    signal verifyU[numRounds][nInputs];
    
    // Stores round constants for each round
    // signal c[nInputs]; 
    // signal d[nInputs];

    // for (var i = 0; i < nInputs; i++){
    //     c[i] <== roundConstantC;
    //     d[i] <== roundConstantD;
    // }

    roundX[0] <== X;
    roundY[0] <== Y;
    for (var i = 0; i < nInputs; i++){
        log("Initial X:", X[i]);
        log("Initial Y:", Y[i]);
    }
        
    component constantAddition[numRounds];
    component diffusionLayer[numRounds + 1];
    component phtLayer[numRounds + 1];
    component sBox[numRounds];

    component verify[numRounds];

    log("");
    log("");
    for (var i = 0; i < numRounds; i++){
        log("Round:", i);
        // Constant Addition A
        constantAddition[i] = constantAddition(nInputs);
        constantAddition[i].c <== c[i];
        constantAddition[i].d <== d[i];
        constantAddition[i].X <== roundX[4*i]; 
        constantAddition[i].Y <== roundY[4*i]; 
        roundX[(4*i)+1] <== constantAddition[i].outX;
        roundY[(4*i)+1] <== constantAddition[i].outY;
        for (var num = 0; num < nInputs; num++){
            log("Constant Addition Output X:", roundX[(4*i)+1][num]);
            log("Constant Addition Output Y:", roundY[(4*i)+1][num]);
        }

        // Linear Layer M
        diffusionLayer[i] = diffusionLayer(nInputs);
        diffusionLayer[i].X <== roundX[(4*i)+1];
        diffusionLayer[i].Y <== roundY[(4*i)+1];
        diffusionLayer[i].g <== g;
        roundX[(4*i)+2] <== diffusionLayer[i].outX;
        roundY[(4*i)+2] <== diffusionLayer[i].outY;
        for (var num = 0; num < nInputs; num++){
            log("Linear Layer Output X:", roundX[(4*i)+2][num]);
            log("Linear Layer Output Y:", roundY[(4*i)+2][num]);
        }

        // PHT P
        phtLayer[i] = PHT(nInputs);
        phtLayer[i].X <== roundX[(4*i) + 2];
        phtLayer[i].Y <== roundY[(4*i) + 2];
        roundX[(4*i) + 3] <== phtLayer[i].outX;
        roundY[(4*i) + 3] <== phtLayer[i].outY;
        for (var num = 0; num < nInputs; num++){
            log("PHT Output X:", roundX[(4*i)+3][num]);
            log("PHT Output Y:", roundY[(4*i)+3][num]);
        }


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
        for (var num = 0; num < nInputs; num++){
            log("S Box Output X:", roundX[(4*i)+4][num]);
            log("S Box Output Y:", roundY[(4*i)+4][num]);
        }

        log("");
        log("");

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

    phtLayer[numRounds] = PHT(nInputs);
    phtLayer[numRounds].X <== diffusionLayer[numRounds].outX;
    phtLayer[numRounds].Y <== diffusionLayer[numRounds].outY;

    outX <== phtLayer[numRounds].outX;
    outY <== phtLayer[numRounds].outY;
}

//component main = Anemoi(1,19, 8384883667915720146, 11);