#! /bin/bash

# Step 1: Generate Inputs
echo "Generating Inputs in input.json"
python3 genInputs.py

# Step 2: Compile Circuit
echo "Beginning circuit compilation"
circom jive.circom --r1cs --wasm --sym

# Optional: view information about circuit
echo "Viewing Information about the circuit"
snarkjs r1cs info jive.r1cs
# Optional: print the constraints 
echo "Printing constraints"
snarkjs r1cs print jive.r1cs jive.sym

# Export r1cs to json
echo "Exporting r1cs to json"
snarkjs r1cs export json jive.r1cs jive.r1cs.json

# Step 3: Generate witness
echo "Generating witness"
cd jive_js || exit
node generate_witness.js jive.wasm ../input.json ../witness.wtns
cd ..
# Optional: check if generated witness complies with r1cs
echo "Checking generated witness complies with r1cs"
snarkjs wtns check jive.r1cs witness.wtns

# Step 4: Calculate verification key
echo "Calculating verification key"
snarkjs groth16 setup jive.r1cs pot_28.ptau circuit_0000.zkey

# Contribute to Phase 2 ceremony
echo "Contributing to Phase 2 ceremony" 
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="Name 1" -v -e="Random Entropy"

# Provide second contribution
echo "Providing a second contribution"
snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Name 2" -v -e="Another random entropy"

# Could provide a third-party contribution
# snarkjs zkey export bellman circuit_0002.zkey  challenge_phase2_0003
# snarkjs zkey bellman contribute bn128 challenge_phase2_0003 response_phase2_0003 -e="some random text"
# snarkjs zkey import bellman circuit_0002.zkey response_phase2_0003 circuit_0003.zkey -n="Third contribution name"

# Verify last z_key
echo "Verifying last z-key"
snarkjs zkey verify jive.r1cs pot_28.ptau circuit_0002.zkey

# Apply a random beacon
echo "Applying random beacon"
snarkjs zkey beacon circuit_0002.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

# Verifying the final z_key
echo "Verifying final z-key"
snarkjs zkey verify jive.r1cs pot_28.ptau circuit_final.zkey

# Export the verification key to json format
echo "Exporting the verification key to json format"
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

# Step 5: Generate proof
# Generates proving key and proof
echo "Generating proving key and proof"
snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json

# Step 6: Verify proof
echo "Verifying proof"
snarkjs groth16 verify verification_key.json public.json proof.json

echo "All Done!"