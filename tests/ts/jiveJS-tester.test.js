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
    });

    describe("Compiles tets for length = 2", function() {

      it("Generates test inputs", async () =>{
        prime_field = BigInt("0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16);
        nInputs = 2;
        numRounds = 14; // should add a check for this
        generator = BigInt(5);
        inverse_generator = modInverse(generator, prime_field);
        alpha = BigInt(5);
        inverse_alpha = modInverse(alpha, prime_field);
        beta = generator;
        gamma = inverse_generator;
        delta = BigInt(0);
        stateX = [BigInt("9548783334288792222187719850239633635968338977891712075177722185624419687148"), BigInt("21519226999405371723682296546608643070472098252591275400625434157612750424885")];
        stateY = [BigInt("15500362218220226581748862416315814470162069496421580649821713367394410892519"), BigInt("6276975102585164162533073879512408564194467882927333840322202175012480815313")];
    });
      
    it("Compresses the state", async () =>{
      var out = jive_mode(prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha, beta, gamma, delta, stateX, stateY);
      assert.equal(out, BigInt("4584627583742434057326785101528698066157055122872090701865894498340904704204"));
    }); 
  });

  describe("Compiles tests for length = 3", function() {

    it("Generates test inputs", async () =>{
      prime_field = BigInt("0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16);
      nInputs = 3;
      numRounds = 12; // should add a check for this
      generator = BigInt(5);
      inverse_generator = modInverse(generator, prime_field);
      alpha = BigInt(5);
      inverse_alpha = modInverse(alpha, prime_field);
      beta = generator;
      gamma = inverse_generator;
      delta = BigInt(0);
      stateX = [BigInt("9331813979263278637820688835064071024726684349449605362541077612726604877263"), BigInt("17054071849927222935046772206378847759024497588411706375681754050161069007142"), BigInt("15240021571817749178866021087203608315928749791957328125080714107084456320860")];
      stateY = [BigInt("20959840420686837714202968027958882667761028882645627885504725342374203437627"), BigInt("17439201755872236084431259414503251014924134264534647965508038585751422292522"), BigInt("7075495444444388091850850289801102050086788307565544673793595241055499137009")];
    });
    
    it("Compresses the state", async () =>{
      var out = jive_mode(prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha, beta, gamma, delta, stateX, stateY);
      assert.equal(out, BigInt("6697959810768371918583218916013412832092137181845243973000569746616804626880"));
    }); 
  });

  describe("Compiles tests for length = 4", function() {

    it("Generates test inputs", async () =>{
      prime_field = BigInt("0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001", 16);
      nInputs = 4;
      numRounds = 12; // should add a check for this
      generator = BigInt(5);
      inverse_generator = modInverse(generator, prime_field);
      alpha = BigInt(5);
      inverse_alpha = modInverse(alpha, prime_field);
      beta = generator;
      gamma = inverse_generator;
      delta = BigInt(0);
      stateX = [BigInt("11791873043189730376767856592623449459729276490609688014948741864777093871304"), BigInt("6568335653924751622156771054922021302042960267782577420764231899317090923374"), 
      BigInt("13842316347010138632574849440746054698892270227217740346030367177693594368866"), BigInt("15028505170174691212174431575637629877559039281898140067555927331316616697038")];
      stateY = [BigInt("8230575181648048398158185173893833351437703830882082524748340837839626416692"), BigInt("15717764266924541210444261093213193122857216055376029102038335752355069011646"),
      BigInt("17596346400168342421789442602844540148976393340997617702493557773907672771155"), BigInt("3023258445115205347209713590591301213470465997679181996020717873273341609883")];
    });
    
    it("Compresses the state", async () =>{
      var out = jive_mode(prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha, beta, gamma, delta, stateX, stateY);
      assert.equal(out, BigInt("513102371531696489370490618714104897763008661434507389297101409373159319612"));
    }); 
  });
});