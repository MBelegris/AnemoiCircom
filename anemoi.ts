const chai = require("chai");
const assert = chai.assert;
const Scalar = require("ffjavascript").Scalar;

// Typescript Implementation for Anemoi Permutation
class AnemoiPerm {
    nInputs: number
    public numRounds: number
    public prime_field: BigInt
    public generator: BigInt
    public inverse_generator: BigInt
    public alpha: BigInt
    public inverse_alpha: BigInt
    public beta: BigInt
    public gamma: BigInt
    public delta: BigInt
    public stateX: BigInt[]
    public stateY: BigInt[]
    public roundConstantC: BigInt[][]
    public roundConstantD: BigInt[][]
    public matrix: BigInt[][]

    constructor (
        _nInputs: number, _numRounds: number, _prime_field: BigInt, _generator: BigInt,
        _inverse_generator: BigInt, _alpha: BigInt, _inverse_alpha: BigInt, _beta: BigInt,
        _gamma: BigInt, _delta: BigInt, _stateX: BigInt[], _stateY: BigInt[]
    ) {
        this.nInputs = _nInputs
        this.numRounds = _numRounds
        this.prime_field = _prime_field
        this.generator = _generator
        this.inverse_generator = _inverse_generator
        this.alpha = _alpha
        this.inverse_alpha = _inverse_alpha
        this.beta = _beta
        this.gamma = _gamma
        this.delta = _delta
        this.stateX = _stateX
        this.stateY = _stateY

        // generate round constants
        const pi_0 = Scalar.mod(BigInt("1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679"), this.prime_field)
        const pi_1 = Scalar.mod(BigInt("8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196"), this.prime_field)
        var roundC: BigInt[][]
        var roundD: BigInt[][]

        for (var r = 0; r < this.numRounds; r++){
            var pi_0_r = Scalar.exp(pi_0, BigInt(r))
            var tmp: BigInt[]
            roundC.push(tmp)
            roundD.push(tmp)
            for (var i = 0; i < this.nInputs; i++){
                var pi_1_i = Scalar.exp(pi_1, i);
                var pow_alpha = Scalar.exp(Scalar.add(pi_0_r, pi_1_i), this.alpha)
                var constC = Scalar.mod(Scalar.add(Scalar.mul(this.generator, Scalar.exp(pi_0_r, BigInt(2))), pow_alpha), this.prime_field);
                var constD = Scalar.mod(Scalar.add(Scalar.mul(this.generator, Scalar.exp(pi_1_i, BigInt(2))), pow_alpha), this.prime_field);
                roundC[r].push(constC);
                roundD[r].push(constD);
            }
        }
        this.roundConstantC = roundC
        this.roundConstantD = roundD

        this.matrix = this.genMatrix(this.nInputs)
    }

    /**
     * genMatrix
prime_field: BigInt, length: number     */
    public genMatrix(length: number) {
        assert(length < 5)
        assert(length > 0)
        if (length == 1) {
            const num0 = BigInt(0);
            const num1 = BigInt(1);
            const mat = [[num0, num1], [num1, num0]] // Identity matrix
            return mat
        }
        else {
            const num1 = BigInt(1)
            const num2 = BigInt(2)
            if (length == 2){
                const mat = [
                    [num1, this.generator], // [1,g]
                    [this.generator, Scalar.add(Scalar.exp(this.generator, num2),num1)] // [g,g^2 + 1]
                ]
                return mat
            }
            else if (length == 3){
                const mat = [
                    [Scalar.add(this.generator, num1), num1, Scalar.add(this.generator, num1)],
                    [num1, num1, this.generator],
                    [this.generator, num1, num1]
                ]
                return mat
            } if(length == 4){
                const mat = [
                    [num1, Scalar.exp(this.generator, num2), Scalar.exp(this.generator, num2), Scalar.add(this.generator, num1)],
                    [Scalar.add(num1, this.generator), Scalar.add(this.generator, Scalar.exp(this.generator, num2)), Scalar.exp(this.generator, num2), Scalar.add(num1, Scalar.mul(num2, this.generator))],
                    [this.generator, Scalar.add(num1, this.generator), num1, this.generator],
                    [this.generator, Scalar.add(num1, Scalar.mul(num2, this.generator)), Scalar.add(num1, this.generator), Scalar.add(num1, this.generator)]
                ]
                return mat
            }
        }
    }

    /**
     * showValues
     */
    public showValues() {
        console.log("Parameters for the current Anemoi class:\n",
        "\nField:", this.prime_field.toString(),
        "\nNumber of Inputs:", this.nInputs, "Number of Rounds:", this.numRounds,
        "\nGenerator:", this.generator.toString(), "Inverse Generator", this.inverse_generator.toString(),
        "\nAlpha:", this.alpha.toString(),
        "\nBeta:", this.beta.toString(),
        "\nGamma:", this.gamma.toString(),
        "\nDelta:", this.delta.toString(),
        "\nStateX:", this.stateX,
        "\nStateY:", this.stateY,
        "\nRound Constants C:", this.roundConstantC,
        "\nRound Constants D:", this.roundConstantD
        );
    }
}

// const anemoi = new AnemoiPerm(
//     1,
//     21,
//     BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617"),
//     BigInt("5"),
//     BigInt("8755297148735710088898562298102910035419345760166413737479281674630323398247"),
//     BigInt("5"),
//     BigInt("8755297148735710088898562298102910035419345760166413737479281674630323398247"),
//     BigInt("5"),
//     BigInt("8755297148735710088898562298102910035419345760166413737479281674630323398247"),
//     BigInt("0"),
//     [BigInt("1379158866955041673364087887057884341645956724581899875764829891317338483353")],
//     [BigInt("16897081616827119598860963615599579375033514399101094788132550756810426780923")]
// );

// anemoi.showValues()