const fs = require('fs');
const chai = require("chai");
const path = require("path");
const { genWitness, getSignalByName } = require('circom-helper/build/utils');
const wasm_tester = require("./index").wasm;
const c_tester = require("./index").c;
const genInputs = require("./inputs").generate_input_json;
const genSpecInputs = require("./inputs").generate_specific_inputs_json;

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
    const nInputs = 1; // b=2, l=1


    it("Compiles Jive circuit and generates wasm", async () =>{
        genInputs(prime_value, alpha, nInputs);

        // Read inputs
        const raw = fs.readFileSync(path.join(__dirname, 'input.json'));
        let circuit_inputs = JSON.parse(raw);
        const circuit = "jive_L2_a5";
        // Generates witness
        const witness = await genWitness(circuit, circuit_inputs);
        // Output of Jive mode
        const output = await getSignalByName(circuit, witness, 'main.out');
    });

    it("Correctly hashes inputs", async () => {
        // Given that b=2, the X holds 1 value and Y holds 1 value
        let X = ["21284495204729344431162124129465134439933874215855908349147367482226264795899"];
        let Y = ["2320104909775456241592764390901219230983708351369023735970742517587841188432"];

        const correctOutput = "1704116387032886263091266031844209595445024849194757062791001678930440783428";

        genSpecInputs(prime_value, alpha, nInputs, X, Y);

        // Read inputs
        const raw = fs.readFileSync(path.join(__dirname, 'input2.json'));
        let circuit_inputs = JSON.parse(raw);
        const circuit = "jive_L2_a5";

        // Generates witness
        const witness = await genWitness(circuit, circuit_inputs);
        // Output of Jive mode
        const output = await getSignalByName(circuit, witness, 'main.out'); 

        assert.equal(output.toString(),correctOutput);
    });
})