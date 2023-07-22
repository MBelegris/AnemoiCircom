# Anemoi Paper Notes

A new family of ZK-friendly permutations that can be used to construct **efficient hash function**.
Main features:

1. Efficient within multiple proof systems: Groth16, Plonk
2. Contain dedicated functions optimised for specific applications (namely Merkle Tree hashing and general purpose hashing)
3. Highly competetive performance

It uses a **SPN**.

## Introduction

Modern hash functions operate over the binary field F2 whereas ZK protocols operate over Fq for a large q- usually a prime.
This creates a need for new hash functions that are natively efficient in Fq. *These are known Arithmetization-Oriented (AO) Designs*.
Examples of such:

1. Poseidon
2. Rescue-Prime

### Design Requirements for AO

Multiple design principles have identified to be expected from AO hash functions.

1. **Evaluation vs. Verification:** The efficiency of an AO primitive is dependent on the verification.
2. **b-to-1 compression:** Compression function should map bm to m finite field elements, meaning a compression factor of b (often b=2 in Merkle Trees). *As most AO hash functions are used for Merkle Trees, the inputs are not arbitrarily long inputs*.
3. **Primitive Factories:** AO hash functions must be defined for a vast number of field sizes and security levels (unlike single primitive or small family of primitives such as AES-128/192/256).
4. **Performance constraints:** The space and time complexities of proving systems depend on the size (i.e. the number of gates) of the arithmetized program that is being verified. Therefore it is crucial to minimise the number of gates for practical considerations (a proof could have such overhead to make it unusable).
*Gates are the algebraic operations such multiplication or addition*

### Contributions

1. Jive- new mode of operation which turns a public permutation into a t-to-1 compression function.
2. Argue that asymmetry between the evaluation and the verification of a function is best framed in terms of CCZ-equivalence.
3. Flystel- new family of non-linear components (S-boxes) that allows for both high and low degree evaluation.
4. Anemoi- a new permutation factory that uses the Flystel structure using the Substitution Permutation Network (SPN) structure

## Background

Here we define q as an integer corresponding to field size $$F_q$$
This means that q is either:

1. q=p for a some prime p
2. q=2^n. In particular for binary fields we focus on the case where n is odd *otherwise its is difficult to build low degree permutations*.

We denote <a,b> as the scalar product of $$a \in F^{m}*{q}$$ and $$b \in F^{m}*{q}$$ such that:
$$<a,b> = Σ^{m-1}_ {i=0}(a_i, b_i)$$

Consider a function F: $$ F^{m}*{q} \rightarrow  F^{m}*{q}$$

**Differential Uniformity:** Differential uniformity measures the resistance of a Boolean function against differential attacks.
**Differential attacks** exploit the differences in input/output pairs to reveal information about the internal structure of a cryptographic algorithm.

**Linear Properties:** If q=2^n then we use the Walsh Transform. Otherwise when q=p we use the Fourier Transform.

**CCZ-Equivalence:** Evaluating if y = F(x) <==> v = G(u).

## Modes of Operation

Hash functions have two purposes:

1. To return a digest of a message by emulating a random oracle.
2. To be used as a compression function in a Merkle Tree (maps two inputs of size n to an output of size n)

A full hash function is only used in the Random Oracle case whereas permutation-based construction is used for the Merkle Tree case.

### Case 1: Random Oracle - Sponge Construction

This case is where a digest of a message must be returned. A full hash function is used here.

#### Sponge Construction

Given a permutation P that works on field F(r+c)q where

1. r is the rate, the size of the outer part of the state
2. c is the capacity, the size of the inner part of the state

h is the number of elements in Fq that make up the digest.

The main operations to process a message m are:

1. **Padding**: Append 1 and enough zeroes to message m so that the total length is a multiple of r, then divide that result into blocks m_0, m_1, ... m_l-1 of r elements. *If the lenghth of the message is a multiple of r already, do not append further blocks to it. Instead add a constant σ to the capacity before squeezing*.
2. **Absorption**: For each message block, add it to the outer part of the state and then apply P to the full state (the added m and outer part, AND the inner part).
3. **Squeezing**: The first digest message is the first min(h,r) elements from the outer state. If h>r, then the process is repeated until the desired digest length is reached.

### Case 2: Merkle Compression Function - Jive Mode

This is the case where the hash function is specifically used for Merkle trees as a compression function.

In a Merkle Tree elements are considered in F^m_q. Two elements are hashed in order to obtain a new one, therefore the input size is equal to double the output size.

#### Jive Compression

The definition of Jive is as follows:
Jive_b(P): (x_0,...,x_b-1) -> Σ(x_i + P(x_0,...,x_b-1))

## Flystel Structure

Butter**fly** + Fei**stel** = Flystel

Let Qδ and Qγ be two quadratic functions: Fq -> Fq
Let E be a permutation: Fq -> Fq

For a given tuple (Qδ, E, Qγ)

### Open Flystel

The open flystel H is the permutation of $F_q^2$ obtained using a 3-round Feistel Network with Qγ, $E^-1$ and Qδ.
H(x,y) = (u,v) evaluated as follows:

1. $x <- x - Qδ(y)$
2. $y <- y - E^-1(x)$
3. $x <- x + Qγ(y)$
4. $u <- x, v <- y$

### Closed Flystel

The closed flystel V is the function over $F^2_q$ where
V: (y,v) -> (Rγ(y,v), Rδ(y,v)) such that:

1. $Rγ: (y,v) -> E(y-v) + Qγ(y)$
2. $Rδ: (y,v) -> E(y-v) + Qδ(v)$

### Equivalence

Verifying that (u,v) = H(x,y) is the equivalent to verifying that (x,u) <- V(y,v)

This means it is possible to encode the verification of the evaluation of the high-degree permutation using the polynomial representation of the low-degree function.

### Flystel_2

We call Flystel_2 when $q=2^n$ (where n is odd).

Given that $a = 2^i + 1$ (where gcd(i,n)=1)

We can then define the following functions:

1. $Qγ: x -> βx^a + γ$
2. $Qδ: x-> βx^a + δ$
3. $E: x-> x^a$

Concretely, we can set a=3, define g as a generator within the multiplicative subgroup of F_q, β=g, γ=g^-1 and δ=0, s.t.:

1. $Qγ: x -> gx^3 + g^-1$
2. $Qδ: x-> gx^3$
3. $E: x-> x^3$

### Flystel_p

We call Flystel_p when q=p (p is a prime).

Similarly we can define the following functions:

1. $Qγ: x -> gx^2 + γ$
2. $Qδ: x-> gx^2 + δ$
3. $E: x-> x^2$

## Anemoi Description

The anemoi permuations operatore on $F^{2l}_q$ where q is the field size (either a prime or a power of two).

### Round Function

A round function is a permutation of $F^{2l}_q$.
The state is organised into a rectangle of elements of Fq of dimension 2l.
X denotes (x_0,...,x_l-1) and Y denotes (y_0,...,y_l-1) .
g is a specific generator in the multiplicative subgroup of Field $F_q$.

#### Constant Additions

The state is added by a set of round constants that depend on the position (index j) and the round (index i).

We let:

1. $x_j <- x_j + c[i] [j]$.
2. $y_j <- y_j + d[i] [j]$.

They are derived as follows:

1. π_0 and π_1 are the first and second blocks of 100 digits (not inlcuding 3, the first value) of π(3.14...)
2. The round constants are derived by applying the open Flystel with the same parameters as in the round function on the pair (π^i_0,π^j_1)
 a. $c[i] [j] = g(π^i_0)^2 + (π^i_0 + π^j_1)^a$
 b. $d[i] [j] = g(π^j_1)^2 + (π^i_0 + π^j_1)^a + g^-1$

#### Diffusion Layer

The diffusion layer M operates on X and Y seperatly so that:
$M(X,Y) = (M_x(X), M_y(Y))$

We define $M_y = ρ O M_x$.

ρ is a simple word permutation: $ρ(x_0,...,x_l-1) = (x_1,..., x_l-1, x_0)$

In the case where **l is small**, the field size is then expected to be large in order for the permutation to operate on a state large enough to offer security. This is the case when using pairning based proof systems such as Plonk or Groth16 which require large scalar fields for security.

In the case where $l \in {2,3,4}$ we use the matrix $M^l_x$ where:

```
M^2_x = [1     g]
  [g g^2+1]
  
M^3_x = [g+1 1 g_1]
  [1   1   g]
  [g   1   1]

M^4_x = [1   g^2   g^2  1+g]
  [1+g g+g^2 g^2 1+2g]
  [g   1+g   1      g]
  [g   1+2g  1+g  1+g]
```  

*M^1_x is the identity*

#### Pseudo-Hadamard Transform

The Pseudo-Hadamard Transform P:
Y <- Y + X
x <- Y + X

#### S-box Layer

The S-box layer S is an open Flystel operating over F^2_q.
S(X,Y) = (H(x_0,y_0),...,H(x_l-1, y_l-1))

#### Bringing it all together

The Anemoi permutation iterates n_r rounds of the round function followed by a call to the linear layer M:
> $Anemoi_{q,a,l} = M o R_{n_r-1} o ... o R_0$

The round function is described below in pseudocode:

```
// Constant Addition A
for i in {0,...,l-1} do
 x_i <- x_i + c^r_i
 y_i <- y_i + d^r_i
end for

// Linear Layer M
X <- M_x(X)
Y <- ρ(Y) o M_x

// PHT P
Y <- Y + X
X <- X + Y

// S-box layer H
for i in {0,...,l-1} do
 x_i <- x_i - gQ(y_i) - g^-1
 y_i <- y_i - x_i^(1/a)
 x_i <- x_i + gQ(y_i)
end for
```

#### Constraints

For security reasons there are a few constraints that must be met.

**AnemoiSponge**: The Anemoi instance must operate on the field $F^{r+c}_q$ where r is the rate and c is the capacity. Due to the inner workings of Anemoi r_c must be even.

**AnemoiJive**: The Anemoi instance constructs a compression function mapping b-to-1 vectors of $F^m_q$ elements using $Jive_b$ and an Anemoi instance operating on bm elements in $F_q$. The value of bm must be even, due to the inner workings of Anemoi.
