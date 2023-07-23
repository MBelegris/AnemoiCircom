# File to create inputs for anemoi hash function
# Should create: a, g, inv_g, isPrime, state X Y, field q, exponent, roundConstants

import json, random

def genState(nCol, q):
    # the state is 2 column matrix made up of the vectors X and Y which hold values of length 
    print("Generating state")
    X = []
    Y = [] 
    for i in range(0, nCol):
        X.append(random.randint(0, q-1))
        Y.append(random.randint(0, q-1))
    out = [X, Y]
    return out

def genRoundConstants(alpha, g, inv_g, q):
    print("Calculating round constants")
    pi_0 = 1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679 % q
    pi_1 = 8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196 % q

    out = []
    eq1 = g*(pow(pi_0, 2, q)) + pow((pi_0 + pi_1), alpha, q)
    eq2 = g*(pow(pi_1, 2, q)) + pow((pi_0 + pi_1), alpha, q) + inv_g
    out.append(eq1)
    out.append(eq2)

    return out

def getNumRounds(nInputs, alpha):
    print("Determining round number")
    # Given that s = 128, a={3,5,7,11} and nInputs={1,2,3,4,6,8}
    arr = [[21,21,20,19], [14,14,13,13], [12,12,11,11], [10,10,10,10], [10,10,9,9]]
    out = 0
    if (nInputs < 5):
        if (alpha == 3):
            out = arr[nInputs-1][0]
        
        if (alpha == 5):
            out = arr[nInputs-1][1]
        
        if (alpha == 7):
            out = arr[nInputs-1][2]
        
        if (alpha == 11):
            out = arr[nInputs-1][3]
    else:
        if (nInputs == 6):
            out = 10
        else:
            if (alpha == 3):
                out = arr[4][0]
            
            if (alpha == 5):
                out = arr[4][1]
            
            if (alpha == 7):
                out = arr[4][2]
            
            if (alpha == 11):
                out = arr[4][3]

    return out

def is_prime(n):
    print("Checking if given prime is indeed prime")
    if n <= 1:
        return False
    if n <= 3:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    while ((i * i) <= n):
        if n % i == 0 or n % (i + 2) == 0:
            return False
        i += 6
    return True

def mod_inverse(a, m):
    print("Finding modular inverse of generator")
    m0, x0, x1 = m, 0, 1
    while a > 1:
        q = a // m
        m, a = a % m, m
        x0, x1 = x1 - q * x0, x0
    return x1 if x1 >= 0 else x1 + m0

def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    else:
        gcd, x, y = extended_gcd(b % a, a)
        return gcd, y - (b // a) * x, x

def mult_mod_inverse(a, modulus):
    print("Finding multiplicative modular  of a value using gcd")
    gcd, x, y = extended_gcd(a, modulus)
    if gcd != 1:
        raise ValueError("The modular inverse does not exist.")
    return x % modulus


def find_generator(field):
    print("Finding generator")
    for g in range(2, field):
        is_generator = False
        for i in range(1, field - 1):
            if pow(g, i, field) == 1:
                print("Potential generator is found")
                is_generator = True
                break
        if is_generator:
            print("Returning generator")
            return g
    return None

def in_field(value, field):
    if value > field:
        return False
    return True

def generate_input_json(prime_value, alpha, nInputs):
    print("Enter generate input json")

    if not is_prime(prime_value):
        raise ValueError("The input prime_value is not a prime number.")
        
    generator = find_generator(prime_value)
    print("Found generator:", generator)
    if generator is None:
        raise ValueError("No generator found for the given prime_value.")

    inverse_generator = mod_inverse(generator, prime_value)
    if not in_field(inverse_generator, prime_value):
        inverse_generator = inverse_generator % prime_value
    print("Found inverse of generator:", inverse_generator)

    numRounds = getNumRounds(nInputs, alpha)
    print("Number of rounds:",numRounds)

    inv_exp = mult_mod_inverse(alpha, prime_value)
    if not in_field(inv_exp, prime_value):
        inv_exp = inv_exp % prime_value
    print("Found inverse of exponent", alpha, ":", inv_exp)

    roundContstants = genRoundConstants(alpha=alpha, g=generator, inv_g=inverse_generator, q=prime_value)
    print("Round constants generated:", roundContstants[0], roundContstants[1])

    state = genState(nCol=nInputs, q=prime_value)
    print("State generated:", state[0], state[1])

    input_data = {
        "g": generator,
        "inv_g": inverse_generator,
        "q": prime_value, # Prime field q
        "isPrime": True, # For now field is constant and a prime
        "X": state[0],
        "Y": state[1],
        "roundConstantC": roundContstants[0],       
        "roundConstantD": roundContstants[1],       
    }

    with open("input.json", "w") as f:
        json.dump(input_data, f, indent=4)

if __name__ == "__main__":
    print("Generating Inputs")
    prime_value = 2**64 - 2**32 + 1
    # a={3,5,7,11} and nInputs={1,2,3,4,6,8}
    # alpha = random.choice([3,5,7,11]) # taken from the paper
    # nInputs = random.choice([1,2,3,4,6,8])
    alpha = 11
    nInputs = 1
    generate_input_json(prime_value=prime_value, alpha=alpha, nInputs=nInputs)
    print("Generator and its inverse written to input.json.")
