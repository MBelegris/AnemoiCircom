const fs = require('fs');
const chai = require("chai");
const path = require("path");
const { genWitness, getSignalByName } = require('circom-helper/build/utils');
const wasm_tester = require("./index").wasm;
const c_tester = require("./index").c;
const genInputs = require("./inputs").generate_input_json;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;
const prime_value = BigInt("0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16);

const circuit_dir = "./circom";

describe("Testing Jive Mode", function() {
    this.timeout(90000);
    const alpha = 5;
    const nInputs = 1;
    before(() => {
        genInputs(prime_value, alpha, nInputs);
    });

    const raw = fs.readFileSync(path.join(__dirname, 'input.json'));
    let circuit_inputs = JSON.parse(raw);
    //circuit_inputs = JSON.stringify(circuit_inputs);
    console.log(circuit_inputs);
    // circuit_inputs = JSON.parse(circuit_inputs);
    
    const circuit = "jive_L2_a5";
    console.log(circuit);

    it("Compiles Jive circuit and generates wasm", async () =>{        
        // Generates witness
        const witness = await genWitness(circuit, circuit_inputs);
        // Output of Jive mode
        const output = await getSignalByName(circuit, witness, 'main.out');
        console.log(output.toString());
    });
})