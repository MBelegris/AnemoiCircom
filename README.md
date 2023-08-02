# AnemoiCircom

A Circom Implementation of the Anemoi hash function. 
Paper can be found [here](https://eprint.iacr.org/2022/840).

This implemenation of Anemoi, mainly contains the code in Circom to generate a zkSnark of an Anemoi compression using the Jive Compression mode.
It also contains a JavaScript implementation of Anemoi.

## Installation

**Step 1:** Clone the repo using
> [https://github.com/MBelegris/AnemoiCircom.git](https://github.com/MBelegris/AnemoiCircom.git)

**Step 2:** Install pre-requisites using
> `npm i`

**Step 3:** Run the code

## Running Anemoi

### Running circom implementation

#### Method 1: Using [script.sh](https://github.com/MBelegris/AnemoiCircom/blob/main/script.sh)

There is an in-built script that allows the user to run the circom script with a random state:
> `./script.sh`

This contains all the functions that are relevant to generating a zkSnark of a compression.
*It is also a good start to make sure everything works and view what you are locally missing.*

#### Method 2: Manually

**Step 1:** Generate inputs *this will make a json file called input.json that stores the values to be compressed*.
> `python3 genInputs.py`

**Step 1 alternative** Created an input.json file that will store the following:

- the prime field (use bn-254 scalar field).
- generator in the prime field
- inverse of g
- isPrime set to True
- the states X, Y with values up to the prime field
- the generated round constants given the value of alpha and g

*Additionally, chose a value of alpha, beta, gamma, delta to be used in the S Box round*

**Step 2:** Compile the circuit
> `circom jive.circom --r1cs --wasm --sym`

*This should create an r1cs, wasm and sym file.

**Step 3: Optional** View information about the circuit
> `snarkjs r1cs info jive.r1cs`

Prints out information about the circuit

> `snarkjs r1cs print jive.r1cs jive.sym`

Prints out constraints

**Step 4:** Export circuit to json
> `snarkjs r1cs export json jive.r1cs jive.r1cs.json`

**Step 5:** Generate witness
First, enter jive_js directory that should have been created when compiling the circuit.
> `node generate_witness.js jive.wasm ../input.json ../witness.wtns`

**Step 6: Optional** Check if generated witness complies with the constraints of the r1cs file
> `snarkjs wtns check jive.r1cs witness.wtns`

**Step 7:** Calculate verification key

> `snarkjs groth16 setup jive.r1cs pot_28.ptau circuit_0000.zkey`

> `snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="Name 1" -v -e="Random Entropy"`

> `snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Name 2" -v -e="Another random entropy"`

> `snarkjs zkey verify jive.r1cs pot_28.ptau circuit_0002.zkey`

> `snarkjs zkey beacon circuit_0002.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"`

> `snarkjs zkey verify jive.r1cs pot_28.ptau circuit_final.zkey`

> `snarkjs zkey export verificationkey circuit_final.zkey verification_key.json`

**Step 8:** Generate the proof
> `snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json`

**Step 9:** Verify proof
> `snarkjs groth16 verify verification_key.json public.json proof.json`

## Testing

To run tests simply first run to start the server:
> `npm circom-helper`

Then to test both the JS and circom implementation run:
> `npm run test`
