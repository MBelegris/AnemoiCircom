const Scalar = require("ffjavascript").Scalar;

const anemoiPerm = require("./anemoi.js");

const jive_mode = (prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha, beta, gamma, delta, stateX, stateY) => {

        anemoi = anemoiPerm(prime_field, nInputs, numRounds, generator, inverse_generator, alpha, inverse_alpha,
            beta, gamma, delta, stateX, stateY);
        
        hash = 0;

        outX = anemoi[0];
        outY = anemoi[1];

        for (var i = 0; i < nInputs; i++){
            hash = Scalar.mod(
                Scalar.add(
                    Scalar.add(
                        Scalar.add(stateX[i], outX[i]), 
                        Scalar.add(stateY[i], outY[i])), 
                        hash), 
                        prime_field);
        }

        return hash;
}

module.exports = jive_mode;