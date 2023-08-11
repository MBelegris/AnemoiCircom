// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract JiveMode {
    uint256 constant prime_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant alpha = 5;
    uint256 constant generator = 5;
    uint256 constant inverse_alpha = 8755297148735710088898562298102910035419345760166413737479281674630323398247;
    uint256 constant inverse_generator = 8755297148735710088898562298102910035419345760166413737479281674630323398247;
    uint256 constant beta = generator;
    uint256 constant gamma = inverse_generator;
    uint256[][] matrix;

    function expmod(
        uint256 base,
        uint256 e,
        uint256 m
    ) internal view returns (uint256 o) {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            // data
            o := mload(p)
        }
    }

    function getRoundConstants(uint256 nInputs, uint numRounds) private view returns (uint256[][] memory, uint256[][] memory) {
        uint256 pi_0 = 824104930199602784823943670164769700555607983825738307422343133481298736376;
        uint256 pi_1 = 2603526927268970796994549077750998294070306485422942434391779651897459981936;
        
        uint256[][] memory roundConstantC = new uint256[][](numRounds);
        uint256[][] memory roundConstantD = new uint256[][](numRounds);

        for (uint r = 0; r < numRounds; r++) {
            uint256 pi_0_r = expmod(pi_0, r, prime_field);
            roundConstantC[r] = new uint256[](nInputs);
            roundConstantD[r] = new uint256[](nInputs);

            for (uint i = 0; i < nInputs; i++) {
                uint256 pi_1_i = expmod(pi_1, i, prime_field);
                uint256 pow_alpha = expmod((pi_0_r+pi_1_i), inverse_alpha, prime_field);

                roundConstantC[r][i] = addmod(pow_alpha, mulmod(generator, expmod(pi_0_r, 2, prime_field), prime_field), prime_field);
                roundConstantD[r][i] = addmod(pow_alpha + inverse_generator, mulmod(generator, expmod(pi_1_i, 2, prime_field), prime_field), prime_field);
            }
        }
        return (roundConstantC, roundConstantD);
    }

    function genMatrix(uint256 nInputs) private {
        assert(nInputs < 5);
        assert(nInputs > 0);

        if (nInputs == 1) {
            matrix = [[0, 1], [1, 0]];
        } else {
            if (nInputs == 2) {
                matrix = [[1, generator], [generator, (generator**2) + 1]];
            } else if (nInputs == 3) {
                matrix = [
                    [generator + 1, 1, generator + 1],
                    [1, 1, generator],
                    [generator, 1, 1]
                ];
            } else if (nInputs == 4) {
                matrix = [
                    [1, generator**2, generator**2, generator + 1],
                    [
                        1 + generator,
                        generator + (generator**2),
                        generator**2,
                        1 + (2 * generator)
                    ],
                    [generator, 1 + generator, 1, generator],
                    [
                        generator,
                        1 + (2 * generator),
                        1 + generator,
                        1 + generator
                    ]
                ];
            }
        }
    }

    function addConstants(uint256[] memory stateX, uint256[] memory stateY, uint256[][] memory roundConstantC, uint256[][] memory roundConstantD, uint round) private pure returns (uint256[] memory, uint256[] memory) {
        uint256[] memory outX = new uint256[](stateX.length);
        uint256[] memory outY = new uint256[](stateY.length);

        for (uint i = 0; i < stateX.length; i++){
            outX[i] = addmod(stateX[i], roundConstantC[round][i], prime_field);
            outY[i] = addmod(stateY[i], roundConstantD[round][i], prime_field);
        }

        return (outX, outY);
    }

    function wordPermutation(uint256[] memory stateY) private pure returns (uint256[] memory) {
        uint256[] memory out = new uint256[](stateY.length);
        for (uint i = 1; i < stateY.length; i++) {
            out[i - 1] = stateY[i];
        }
        out[stateY.length - 1] = stateY[0];
        return out;
    }

    function linearLayer(uint256[] memory stateX, uint256[] memory stateY) private view returns (uint256[] memory, uint256[] memory) {
        require(matrix.length > 0, 
        "Must first call genMatrix");
        uint256[] memory outY = new uint256[](stateY.length);
        outY = wordPermutation(stateY);

        if (stateX.length == 1) {
            return (stateX, outY);
        } else {
            uint256[] memory outX = new uint256[](stateX.length);
            if (stateX.length == 2 || stateX.length == 4) {
                for (uint col = 0; col < stateX.length; col++) {
                    uint256 sumX = 0;
                    uint256 sumY = 0;
                    for (uint256 row = 0; row < stateX.length; row++) {
                        sumX = addmod(sumX, mulmod(stateX[row], matrix[row][col], prime_field), prime_field);
                        sumY = addmod(sumY, mulmod(outY[row], matrix[row][col], prime_field), prime_field);
                    }
                    outX[col] = sumX;
                    outY[col] = sumY;
                }
            } else {
                for (uint col = 0; col < stateX.length; col++) 
                {
                    uint256 sumX = 0;
                    uint256 sumY = 0;

                    for (uint row = 0; row < stateX.length; row++) 
                    {
                        sumX = addmod(sumX, mulmod(stateX[row], matrix[col][row], prime_field), prime_field);
                        sumY = addmod(sumY, mulmod(outY[row], matrix[col][row], prime_field), prime_field);
                    }

                    outX[col] = sumX;
                    outY[col] = sumY;
                }
            }
            return (outX, outY);
        }
    }

    function phtLayer(uint256[] memory stateX, uint256[] memory stateY) private pure returns (uint256[] memory, uint256[] memory) {
        for (uint i = 0; i < stateX.length; i++) {
            stateY[i] = addmod(stateY[i], stateX[i], prime_field);
            stateX[i] = addmod(stateY[i], stateX[i], prime_field);
        }
        return (stateX, stateY);
    }

    function sBox(uint256[] memory stateX, uint256[] memory stateY) private view returns (uint256[] memory, uint256[] memory) {
        for (uint i = 0; i < stateX.length; i++){
            stateX[i] =  addmod(stateX[i], prime_field - addmod(inverse_generator, mulmod(generator, mulmod(stateY[i], stateY[i], prime_field), prime_field), prime_field), prime_field);
            stateY[i] = addmod(stateY[i], prime_field - expmod(stateX[i], alpha, prime_field), prime_field);
            stateX[i] = addmod(stateX[i], mulmod(generator, mulmod(stateY[i], stateY[i], prime_field), prime_field), prime_field);
        }
        return (stateX, stateY);
    }

    function anemoi(uint256[] memory stateX, uint256[] memory stateY, uint numRounds) private returns (uint256[] memory, uint256[] memory) {
        uint256[][] memory roundConstantC;
        uint256[][] memory roundConstantD;

        (roundConstantC, roundConstantD) = getRoundConstants(stateX.length, numRounds);
        genMatrix(stateX.length);

        for (uint round = 0; round < numRounds; round++) {
            (stateX, stateY) = addConstants(stateX, stateY, roundConstantC, roundConstantD, round);

            (stateX, stateY) = linearLayer(stateX, stateY);

            (stateX, stateY) = phtLayer(stateX, stateY);

            (stateX, stateY) = sBox(stateX, stateY);
        }

        (stateX, stateY) = linearLayer(stateX, stateY);

        (stateX, stateY) = phtLayer(stateX, stateY);
        return (stateX, stateY);
    }

    function jive(uint256[] memory stateX, uint256[] memory stateY, uint numRounds) public returns (uint256) {
        require(stateX.length == stateY.length,
        "State of X and Y must be of same length");

        uint256[] memory outX;
        uint256[] memory outY;

        (outX, outY) = anemoi(stateX, stateY, numRounds);
        uint256 hash = 0;
        for (uint i = 0; i < stateX.length; i++) {
            uint256 x = addmod(stateX[i], outX[i], prime_field);
            uint256 y = addmod(stateY[i], outY[i], prime_field);

            hash = addmod(hash, addmod(x, y, prime_field), prime_field);
        }

        return hash;
    }
}
