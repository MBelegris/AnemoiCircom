// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract JiveMode {
    uint256 prime_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256[][] roundConstantC;
    uint256[][] roundConstantD;

    uint256[][] matrix;

    function getRoundConstants(uint256 alpha, uint256 generator, uint256 inverseGenerator, uint256 numRounds, uint nInputs) private {
        uint256 pi_0 = 824104930199602784823943670164769700555607983825738307422343133481298736376; // pre-computed to fit within prime_field
        uint256 pi_1 = 2603526927268970796994549077750998294070306485422942434391779651897459981936;

        for (uint r = 0; r < numRounds; r++){
            uint pi_0_r = (pi_0 ** r) % prime_field;
            for (uint i = 0; i < nInputs; i++){
                uint pi_1_i = (pi_1 ** i) % prime_field;
                uint pow_alpha = ((pi_0_r + pi_1_i) ** alpha) % prime_field;

                uint constC = (((pi_0_r**2) * generator) + pow_alpha) % prime_field;
                uint constD = (((pi_1_i**2) * generator) + pow_alpha + inverseGenerator) % prime_field;
            
                roundConstantC[r].push(constC);
                roundConstantD[r].push(constD);
            }
        }
    }

    function genMatrix(uint nInputs, uint256 generator) private{
        assert(nInputs < 5);
        assert(nInputs > 0);

        if (nInputs == 1){
            matrix = [
                [0,1],
                [1,0]
            ];
        } else {
            if (nInputs == 2) {
                matrix = [
                    [1, generator],
                    [generator, (generator**2) + 1]
                ];
            } else if (nInputs == 3) {
                matrix = [
                    [generator + 1, 1, generator + 1],
                    [1, 1, generator],
                    [generator, 1, 1]
                ];
            } else if (nInputs == 4){
                matrix = [
                    [1, generator**2, generator**2, generator + 1],
                    [1 + generator, generator + (generator**2), generator**2, 1 + (2*generator)],
                    [generator, 1 + generator, 1, generator],
                    [generator, 1 + (2*generator), 1 + generator, 1 + generator]
                ];
            }
        }
    }

    function addConstants(uint256[] memory stateX, uint256[] memory stateY, uint256 round, uint nInputs) private pure returns (uint256[2][] memory){
        uint256[] memory outX;
        uint256[] memory outY;
        
        for (uint i = 0; i < nInputs; i++){
            outX.push((stateX[i] + roundConstantC[round][i]) % prime_field);
            outY.push((stateY[i] + roundConstantD[round][i]) % prime_field);
        }
        return [outX, outY];
    }

    function wordPermutation(uint256[] memory arr) private returns (uint256[] memory out){
        uint length = arr.length();
        for (uint i = 1; i < length; i++){
            out[i-1] = arr[i];
        }
        out.push(arr[0]);
        return out; 
    }

    function linearLayer(uint nInputs, uint256[] memory stateX, uint256[] memory stateY) private {
        uint256[] memory outX;
        uint256[] memory outY;
        uint256[] memory permY;

        permY = wordPermutation(stateY);

        if (nInputs == 1){
            return [stateX, permY];
        } else {
            if (nInputs == 2 || nInputs == 4) {
                for (uint col = 0; col < nInputs; col++){
                    uint sumX = 0;
                    uint sumY = 0;
                    for (uint row = 0; row < nInputs; row++){
                        sumX = (sumX + (stateX[row] * matrix[row][col])) % prime_field;
                        sumY = (sumY + (permY[row] * matrix[row][col])) % prime_field;
                    }
                    outX.push(sumX);
                    outY.push(sumY);
                }
            } else {
                for (uint col = 0; col < nInputs; col++){
                    uint sumX = 0;
                    uint sumY = 0;
                    for (uint row = 0; row < nInputs; row++){
                        sumX = (sumX + (stateX[row] * matrix[col][row])) % prime_field;
                        sumY = (sumY + (permY[row] * matrix[col][row])) % prime_field;
                    }
                    outX.push(sumX);
                    outY.push(sumY);
                }
            }
        }

        return [outX, outY];
    }

    function phtLayer(uint nInputs, uint256[] memory stateX, uint256[] memory stateY) private {
        uint256[] memory outX;
        uint256[] memory outY;
        
        for (uint i = 0; i < nInputs; i++){
            outY.push((stateX[i] + stateY[i]) % prime_field);
            outX.push((stateX[i] + outY[i]) % prime_field);
        }

        return [outX, outY];
    }

    function sBoxLayer(uint nInputs, uint256[] memory stateX, uint256[] memory stateY, uint256 alpha, uint256 generator, uint256 inverse_generator) private {
        uint256[] memory outX;
        uint256[] memory outY;

        for (uint i = 0; i < nInputs; i++){
            uint256 tmp = (stateX[i] - ((generator  * (stateY[i]**2)) + inverse_generator)) % prime_field;
            outY.push((stateY[i] - (stateX[i]**alpha)) % prime_field);
            outX.push((stateX[i] + (generator*(stateY[i]**2))) % prime_field);
        }

        return [outX, outY];
    }

    function anemoiPerm(uint256[] memory stateX, uint256[] memory stateY, uint256 numRounds, uint256 nInputs, uint alpha, uint256 inverse_alpha, uint generator, uint inverse_generator) private returns (uint256[] memory outX, uint256[] memory outY) {
        for (uint round = 0; round < numRounds; round++){
            (outX, outY) = addConstants(stateX, stateY, round, nInputs);

            (outX, outY) = linearLayer(nInputs, outX, outY);

            (outX, outY) = phtLayer(nInputs, outX, outY);

            (outX, outY) = sBoxLayer(nInputs, outX, outY, alpha, generator, inverse_generator);
        }

        (outX, outY) = linearLayer(nInputs, outX, outY);

        (outX, outY) = phtLayer(nInputs, outX, outY);

        return [outX, outY];
    }

    function Jive(uint256[] memory stateX, uint256[] memory stateY, uint256 numRounds) public returns (uint256) {
        uint alpha = 5;
        uint generator = alpha;
        uint256 inverseGenerator = 8755297148735710088898562298102910035419345760166413737479281674630323398247;
        uint inverseAlpha = inverseGenerator;
        uint nInputs = stateX.length;
        
        getRoundConstants(alpha, generator, inverseGenerator, numRounds, nInputs);
        genMatrix(nInputs, generator);
        
        uint256 hash = 0;

        uint256[] memory outX;
        uint256[] memory outY;
        (outX, outY) = anemoiPerm(stateX, stateY, numRounds, nInputs, alpha, inverseAlpha, generator, inverseGenerator);

        for (uint i = 0; i < nInputs; i++) {
            hash = (hash + (stateX[i] + outX[i]) + (stateY[i] + outY[i])) % prime_field;
        }

        return hash;
    }
}