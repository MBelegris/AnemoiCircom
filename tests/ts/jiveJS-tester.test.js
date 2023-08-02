const chai = require('chai');
const assert = chai.assert;

const jive_mode = require('./../../jive.js');

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
  
    return result;
}
  
  function modInverse(a, m) {  
    // Calculate the modular multiplicative inverse using Fermat's Little Theorem
    const inverse = modPow(a, m - BigInt(2), m);
  
    return inverse;
}
  
describe("JS Testing", function(){
    this.timeout(90000);
    let prime_field;
    let nInputs;
    let numRounds;
    let generator;
    let inverse_generator;
    let alpha; 
    let beta;
    let gamma;
    let delta;
    let stateX = [];
    let stateY = [];

    describe("Compiles tests for length = 1", function(){

      it("Generates test inputs", async () =>{
        prime_field = BigInt("0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16);
        nInputs = 1;
        numRounds = 21; // should add a check for this
        generator = BigInt(5);
        inverse_generator = modInverse(generator, prime_field);
        alpha = BigInt(5);
        inverse_alpha = modInverse(alpha, prime_field);
        beta = generator;
        gamma = inverse_generator;
        delta = BigInt(0);
        stateX = [BigInt("21284495204729344431162124129465134439933874215855908349147367482226264795899")];
        stateY = [BigInt("2320104909775456241592764390901219230983708351369023735970742517587841188432")];
    });
      it("Compresses the state", async () =>{
          var out = jive_mode(prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha, beta, gamma, delta, stateX, stateY);
          assert.equal(out, BigInt("3353707479168229699906093934575094122738454090912465235257758089186805154372"));
      });
    })
});