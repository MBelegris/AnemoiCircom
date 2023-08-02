const fs = require('fs');
const chai = require("chai");
const path = require("path");
const { genWitness, getSignalByName } = require('circom-helper/build/utils');
const { c } = require('circom_tester');
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

describe("Circom testing", function(){
    this.timeout(90000);
    describe("Testing Jive Mode with b=2", function() {
        const alpha = 5;
        const nInputs = 1; // b=2, l=1


        it("Compiles Jive circuit and generates wasm", async () =>{
            genInputs(prime_value, alpha, nInputs, 'input.json');

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L2_a5";
            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out');
        });

        it("Correctly compresses 2 inputs into 1", async () => {
            // Given that b=2, the X holds 1 value and Y holds 1 value
            let X = ["21284495204729344431162124129465134439933874215855908349147367482226264795899"];
            let Y = ["2320104909775456241592764390901219230983708351369023735970742517587841188432"];

            const correctOutput = "3353707479168229699906093934575094122738454090912465235257758089186805154372";

            genSpecInputs(prime_value, alpha, nInputs, X, Y, 'input2.json');

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input2.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L2_a5";

            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out'); 

            chai.expect(output < prime_value);

            assert.equal(output.toString(),correctOutput);
        });
    });

    describe("Testing jive mode with b=4", function(){
        // this.timeout(90000);
        const alpha = 5;
        const nInputs = 2;

        it("Compiles Jive circuit and generates wasm", async () =>{
            genInputs(prime_value, alpha, nInputs, 'input3.json');

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input3.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L4_a5";
            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out');
        });

        it("Compresses 4 inputs into 1", async () =>{
            let X = ["9548783334288792222187719850239633635968338977891712075177722185624419687148","21519226999405371723682296546608643070472098252591275400625434157612750424885"];
            let Y = ["15500362218220226581748862416315814470162069496421580649821713367394410892519","6276975102585164162533073879512408564194467882927333840322202175012480815313"];
            genSpecInputs(prime_value, alpha, nInputs, X, Y,'input4.json');
            const correctOutput = "4584627583742434057326785101528698066157055122872090701865894498340904704204";

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input4.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L4_a5";

            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out'); 

            chai.expect(output < prime_value);

            assert.equal(output.toString(),correctOutput);        
        });
    });

    describe("Testing jive mode with b=6", function(){
        // this.timeout(90000);
        const alpha = 5;
        const nInputs = 3;

        it("Compiles Jive circuit and generates wasm", async () =>{
            genInputs(prime_value, alpha, nInputs, 'input5.json');

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input5.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L6_a5";
            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out');
        });

        it("Compresses 6 inputs into 1", async () =>{
            let X = ["9331813979263278637820688835064071024726684349449605362541077612726604877263","17054071849927222935046772206378847759024497588411706375681754050161069007142","15240021571817749178866021087203608315928749791957328125080714107084456320860"];
            let Y = ["20959840420686837714202968027958882667761028882645627885504725342374203437627","17439201755872236084431259414503251014924134264534647965508038585751422292522","7075495444444388091850850289801102050086788307565544673793595241055499137009"];
            
            genSpecInputs(prime_value, alpha, nInputs, X, Y,'input6.json');
            
            const correctOutput = "6697959810768371918583218916013412832092137181845243973000569746616804626880";

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input6.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L6_a5";

            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out'); 

            chai.expect(output < prime_value);

            assert.equal(output.toString(),correctOutput);
        });
    });

    describe("Testing jive mode with b=8", function(){
        // this.timeout(90000);
        const alpha = 5;
        const nInputs = 4;

        it("Compiles Jive circuit and generates wasm", async () =>{
            genInputs(prime_value, alpha, nInputs, 'input7.json');

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input7.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L8_a5";
            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out');
        });

        it("Compresses 8 inputs into 1", async () =>{
            let X = ["11791873043189730376767856592623449459729276490609688014948741864777093871304","6568335653924751622156771054922021302042960267782577420764231899317090923374","13842316347010138632574849440746054698892270227217740346030367177693594368866", "15028505170174691212174431575637629877559039281898140067555927331316616697038"];
            let Y = ["8230575181648048398158185173893833351437703830882082524748340837839626416692","15717764266924541210444261093213193122857216055376029102038335752355069011646","17596346400168342421789442602844540148976393340997617702493557773907672771155", "3023258445115205347209713590591301213470465997679181996020717873273341609883"];
            
            genSpecInputs(prime_value, alpha, nInputs, X, Y,'input8.json');
            
            const correctOutput = "513102371531696489370490618714104897763008661434507389297101409373159319612";

            // Read inputs
            const raw = fs.readFileSync(path.join(__dirname, 'input8.json'));
            let circuit_inputs = JSON.parse(raw);
            const circuit = "jive_L8_a5";

            // Generates witness
            const witness = await genWitness(circuit, circuit_inputs);
            // Output of Jive mode
            const output = await getSignalByName(circuit, witness, 'main.out'); 

            chai.expect(output < prime_value);

            assert.equal(output.toString(),correctOutput);
        });
    });
});
