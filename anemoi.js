const Scalar = require("ffjavascript").Scalar;
const chai = require('chai');
const assert = chai.assert;

function modPow(base, exponent, modulus) {
    if (modulus === 1) return BigInt(0);
    let result = BigInt(1);
    base = base % modulus;
  
    while (exponent > 0) {
      if (exponent % BigInt(2) === BigInt(1)) {
        result = (result * base) % modulus;
      }
      exponent = exponent / BigInt(2);
      base = (base * base) % modulus;
    }
  
    return BigInt(result);
}

function getRoundConstants(prime_field, numRounds, nInputs, generator, alpha, inverse_generator){
    const pi_0 = Scalar.mod(BigInt("1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"), prime_field)
    const pi_1 = Scalar.mod(BigInt("8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196"), prime_field)
    var roundC = []
    var roundD = []

    for (var r = 0; r < numRounds; r++){
        var pi_0_r = modPow(pi_0, BigInt(r), prime_field);
        roundC.push([])
        roundD.push([])
        for (var i = 0; i < nInputs; i++){
            var pi_1_i = modPow(pi_1, BigInt(i), prime_field);
            var pow_alpha = modPow((Scalar.add(pi_0_r, pi_1_i)), alpha, prime_field);
            var constC = Scalar.mod(Scalar.add(Scalar.mul(generator, modPow(pi_0_r, BigInt(2), prime_field)), pow_alpha), prime_field);
            var constD = Scalar.mod(Scalar.add(Scalar.mul(generator, (modPow(pi_1_i, BigInt(2), prime_field))), (pow_alpha+inverse_generator)), prime_field);
            roundC[r].push(constC);
            roundD[r].push(constD);
        }
    }
    return [roundC, roundD]
}

function genMatrix(nInputs, generator){
    assert(nInputs < 5)
    assert(nInputs > 0)
    if (nInputs == 1) {
        const num0 = BigInt(0);
        const num1 = BigInt(1);
        const mat = [[num0, num1], [num1, num0]] // Identity matrix
        return mat
    }
    else {
        const num1 = BigInt(1)
        const num2 = BigInt(2)
        if (nInputs == 2){
            const mat = [
                [num1, generator], // [1,g]
                [generator, Scalar.add(Scalar.pow(generator, num2),num1)] // [g,g^2 + 1]
            ]
            return mat
        }
        else if (nInputs == 3){
            const mat = [
                [Scalar.add(generator, num1), num1, Scalar.add(generator, num1)],
                [num1, num1, generator],
                [generator, num1, num1]
            ]
            return mat
        } if(nInputs == 4){
            const mat = [
                [num1, Scalar.pow(generator, num2), Scalar.pow(generator, num2), Scalar.add(generator, num1)],
                [Scalar.add(num1, generator), Scalar.add(generator, Scalar.pow(generator, num2)), Scalar.pow(generator, num2), Scalar.add(num1, Scalar.mul(num2, generator))],
                [generator, Scalar.add(num1, generator), num1, generator],
                [generator, Scalar.add(num1, Scalar.mul(num2, generator)), Scalar.add(num1, generator), Scalar.add(num1, generator)]
            ]
            return mat
        }
    }
}

function addConstants(prime_field, nInputs, roundNum, stateX, stateY, roundConstantC, roundConstantD) {
    let outX = [];
    let outY = [];
    for (var i = 0; i < nInputs; i++){
        // console.log("Round Constant C:", roundConstantC[roundNum][i]);
        // console.log("Round Constant D:", roundConstantD[roundNum][i]);
        outX.push(Scalar.mod(Scalar.add(stateX[i], roundConstantC[roundNum][i]), prime_field));
        outY.push(Scalar.mod(Scalar.add(stateY[i], roundConstantD[roundNum][i]), prime_field));
    }
    return [outX, outY]
}

function wordPermutation(nInputs, stateY) {
    let out = []
    for (var i = 1; i < nInputs; i++){
        out.push(stateY[i]);
    }
    out.push(stateY[0]);
    return out;
}

function linearLayer(prime_field, nInputs, stateX, stateY, mat) {
    stateY = wordPermutation(nInputs, stateY);

    if (nInputs == 1){
        return [stateX, stateY];
    }
    let outX = [];
    let outY = [];
    if (nInputs == 2 || nInputs == 4){
        for (col = 0; col < nInputs; col++){
            var sumX = BigInt(0);
            var sumY = BigInt(0);
            for (row = 0; row < nInputs; row++){
                // sumX = sumX + (stateX[row] * ) % prime_field
                sumX = Scalar.mod(Scalar.add(Scalar.mul(stateX[row], mat[row][col]), sumX), prime_field);
                sumY = Scalar.mod(Scalar.add(Scalar.mul(stateY[row], mat[row][col]), sumY), prime_field);
            }
            outX.push(sumX);
            outY.push(sumY);
        }
    }
    else {
        for (col = 0; col < nInputs; col++){
            var sumX = BigInt(0);
            var sumY = BigInt(0);
            for (row = 0; row <nInputs; row++){
                sumX = Scalar.mod(Scalar.add(Scalar.mul(stateX[col], mat[col][row]), sumX), prime_field);
                sumY = Scalar.mod(Scalar.add(Scalar.mul(stateX[col], mat[col][row]), sumY), prime_field);
            }
            outX.push(sumX);
            outY.push(sumY);
        }
    }
    return [outX, outY]
}

function phtLayer(nInputs, prime_field, stateX, stateY) {
    for (var i = 0; i < nInputs; i++){
        stateY[i] = Scalar.mod(Scalar.add(stateX[i], stateY[i]), prime_field);
        stateX[i] = Scalar.mod(Scalar.add(stateX[i], stateY[i]), prime_field);
    }

    return [stateX, stateY]
}

function sBoxLayer(nInputs, prime_field, stateX, stateY, alpha, beta, gamma, delta) {
    for (i = 0; i < nInputs; i++){
        stateX[i] = Scalar.mod(Scalar.sub(stateX[i], Scalar.add(Scalar.mul(beta, Scalar.pow(stateY[i], BigInt(2))), gamma)), prime_field);
        stateY[i] = Scalar.mod(Scalar.sub(stateY[i], Scalar.pow(stateX[i], alpha)), prime_field);
        stateX[i] = Scalar.mod(Scalar.add(stateX[i], Scalar.add(Scalar.mul(beta, Scalar.pow(stateY[i], BigInt(2))), delta)), prime_field);
    }
    return [stateX, stateY]
}


const anemoiPerm = (prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha,
    beta, gamma, delta, stateX, stateY) => {
        const roundConstants = getRoundConstants(prime_field, numRounds, nInputs, generator, inverse_alpha, inverse_generator);
        const roundConstantC = roundConstants[0];
        const roundConstantD = roundConstants[1];
        
        const mat = genMatrix(nInputs, generator);

        // console.log("Parameters for the current Anemoi class:\n",
        // "\nField:", prime_field.toString(),
        // "\nNumber of Inputs:", nInputs, "Number of Rounds:", numRounds,
        // "\nGenerator:", generator.toString(), "Inverse Generator", inverse_generator.toString(),
        // "\nAlpha:", alpha.toString(),
        // "\nBeta:", beta.toString(),
        // "\nGamma:", gamma.toString(),
        // "\nDelta:", delta.toString(),
        // "\nStateX:", stateX,
        // "\nStateY:", stateY,
        // "\nRound Constants C:", roundConstantC,
        // "\nRound Constants D:", roundConstantD
        // );

        for (var round = 0; round < numRounds; round++){
            // console.log("Round:", round);
            // Constant Addition A
            var addConstantsRound = addConstants(prime_field, nInputs, round, stateX, stateY, roundConstantC, roundConstantD);
            stateX = addConstantsRound[0];
            stateY = addConstantsRound[1];
            // console.log("Constant Addition Output X:", stateX);
            // console.log("Constant Addition Output Y:", stateY);
        
            // Linear Layer M
            var linearLayerRound = linearLayer(prime_field, nInputs, stateX, stateY, mat);
            stateX = linearLayerRound[0];
            stateY = linearLayerRound[1];
            // console.log("Linear Layer Output X:", stateX);
            // console.log("Linear Layer Output Y:", stateY);

            var phtLayerRound = phtLayer(nInputs, prime_field, stateX, stateY);
            stateX = phtLayerRound[0];
            stateY = phtLayerRound[1];
            // console.log("PHT Output X:", stateX);
            // console.log("PHT Output Y:", stateY);
            
            var sBoxLayerRound = sBoxLayer(nInputs, prime_field, stateX, stateY, alpha, beta, gamma, delta);
            stateX = sBoxLayerRound[0];
            stateY = sBoxLayerRound[1];
            // console.log("S Box Output X:", stateX);
            // console.log("S Box Output Y:", stateY);
            // console.log("\n\n");
        }

        var finalLinearLayer = linearLayer(prime_field, nInputs, stateX, stateY, mat);
        stateX = finalLinearLayer[0];
        stateY = finalLinearLayer[1];
        // console.log("Linear Layer Output X:", stateX);
        // console.log("Linear Layer Output Y:", stateY);

        var finalPHTLayer = phtLayer(nInputs, prime_field, stateX, stateY);
        stateX = finalPHTLayer[0];
        stateY = finalPHTLayer[1];
        // console.log("PHT Output X:", stateX);
        // console.log("PHT Output Y:", stateY);

        return [stateX, stateY];
}

module.exports = anemoiPerm;