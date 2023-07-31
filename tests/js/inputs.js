const fs = require("fs");
const bigInt = require("big-integer");
const crypto = require("crypto");
const path = require("path");

function getNumRounds(nInputs, alpha){
    const arr = [
        [21, 21, 20, 19],
        [14, 14, 13, 13],
        [12, 12, 12, 11],
        [12, 12, 11, 11],
        [10, 10, 10, 10],
        [10, 10, 9, 9]
    ];
    let out;
    if (nInputs.lesser(5)){
        if (alpha.equals(3)) out = arr[nInputs.minus(1)][0];
        if (alpha.equals(5)) out = arr[nInputs.minus(1)][1];
        if (alpha.equals(7)) out = arr[nInputs.minus(1)][2];
        if (alpha.equals(11)) out = arr[nInputs.minus(1)][3];
    } else {
        if (nInputs.equals(6)) out = 10;
        else {
            if (alpha.equals(3)) out = arr[4][0];
            if (alpha.equals(5)) out = arr[4][1];
            if (alpha.equals(7)) out = arr[4][2];
            if (alpha.equals(11)) out = arr[4][3];
        }
    } 
    return out;
}

function genRoundConstants(inv_alpha, g, inv_g, prime_value, num_rounds, nInputs){
    // console.log("Calculating round constants");

    const pi_0 = bigInt("1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679").mod(prime_value);
    const pi_1 = bigInt("8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196").mod(prime_value);

    let C = [];
    let D = [];

    for (var r = 0; r < num_rounds; r++){
        let pi_0_r = pi_0.pow(r).mod(prime_value);
        C.push([]);
        D.push([]);

        for (var i = 0; i < nInputs; i++){
            let pi_1_i = pi_1.pow(r).mod(prime_value);
            let pow_alpha = pi_0_r.add(pi_1_i).modPow(inv_alpha, prime_value);
            C[r].push((pi_0_r.modPow(2, prime_value).times(g).add(pow_alpha).mod(prime_value)).toString());
            D[r].push((pi_1_i.modPow(2, prime_value).times(g).add(pow_alpha).add(inv_g).mod(prime_value)).toString());
        }
    }
    const out = [C,D];
    return out;
}

function genRandomBigInt(maxValue){
    if (maxValue <= 0 || !Number.isInteger(Number(maxValue))) {
        throw new Error("maxValue should be a positive integer.");
    }
    
    // Generate a random byte array of appropriate length for the given maxValue
    const byteArrayLength = Math.ceil(Math.log2(Number(maxValue)) / 8);
    const randomBytes = crypto.randomBytes(byteArrayLength);
    
    // Convert the random byte array to a BigInt
    let randomValue = bigInt(0);
    for (let i = 0; i < byteArrayLength; i++) {
        randomValue = randomValue.shiftLeft(8).add(randomBytes[i]);
        // (randomValue.shiftLeft(8)) + bigInt(randomBytes[i]);
    }
    randomValue = randomValue.mod(maxValue);
    
    return randomValue;    
}

function genState(nInputs, prime){
    // console.log("Generating state");
    let X = [];
    let Y = [];

    for (var i = 0; i < nInputs; i++){
        X.push(genRandomBigInt(prime).toString());
        Y.push(genRandomBigInt(prime).toString());
    }
    const out = [X, Y];
    return out;
}

function generate_input_json(prime_value, alpha, nInputs){
    prime_value = bigInt(prime_value);
    if (!prime_value.isPrime()){
        throw "Prime value entered not a prime";
    }
    alpha = bigInt(alpha);
    nInputs = bigInt(nInputs);
    // console.log("Generating input json file with inputs:", prime_value.toString(), 
    // alpha.toString(), nInputs.toString());

    const generator = bigInt(5);
    // console.log("Found generator:", generator.toString());

    const inverse_generator = generator.modInv(prime_value);
    // console.log("Found inverse of generator:", inverse_generator.toString());

    const numRounds = getNumRounds(nInputs, alpha);
    // console.log("Number of rounds:", numRounds);

    const inv_alpha = alpha.modInv(prime_value);

    const roundConstants = genRoundConstants(inv_alpha, generator, inverse_generator, prime_value,
        numRounds, nInputs);
    // console.log("Round Constants Generated:", roundConstants[0], roundConstants[1]);

    const state = genState(nInputs, prime_value);
    // console.log("State Generated: ", state[0], state[1]);

    let input_data = {
        g: generator.toString(),
        inv_g: inverse_generator.toString(),
        q: prime_value.toString(),
        isPrime: "1",
        X: state[0],
        Y: state[1],
        roundConstantC: roundConstants[0],
        roundConstantD: roundConstants[1]
    };

    // console.log(JSON.stringify(input_data));

    fs.writeFile(path.join(__dirname, 'input.json'), JSON.stringify(input_data), (error) => {
        if (error) {
            console.log(error);
            throw error;
        }
    });
    // console.log("Successfully written to file");
}

function generate_specific_inputs_json(prime_value, alpha, nInputs, X, Y){
    prime_value = bigInt(prime_value);
    if (!prime_value.isPrime()){
        throw "Prime value entered not a prime";
    }
    alpha = bigInt(alpha);
    nInputs = bigInt(nInputs);
    // console.log("Generating input json file with inputs:", prime_value.toString(), 
    // alpha.toString(), nInputs.toString());

    const generator = bigInt(5);
    // console.log("Found generator:", generator.toString());

    const inverse_generator = generator.modInv(prime_value);
    // console.log("Found inverse of generator:", inverse_generator.toString());

    const numRounds = getNumRounds(nInputs, alpha);
    // console.log("Number of rounds:", numRounds);

    const inv_alpha = alpha.modInv(prime_value);

    const roundConstants = genRoundConstants(inv_alpha, generator, inverse_generator, prime_value,
        numRounds, nInputs);
    // console.log("Round Constants Generated:", roundConstants[0], roundConstants[1]);

    let input_data = {
        g: generator.toString(),
        inv_g: inverse_generator.toString(),
        q: prime_value.toString(),
        isPrime: "1",
        X: X,
        Y: Y,
        roundConstantC: roundConstants[0],
        roundConstantD: roundConstants[1]
    };

    // console.log(JSON.stringify(input_data));

    fs.writeFile(path.join(__dirname, 'input2.json'), JSON.stringify(input_data), (error) => {
        if (error) {
            console.log(error);
            throw error;
        }
    });
    // console.log("Successfully written to file");
}

module.exports = {
    generate_input_json,
    generate_specific_inputs_json 
};