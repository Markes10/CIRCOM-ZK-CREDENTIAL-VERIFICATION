#!/usr/bin/env bash
# Compile Circom circuit to R1CS constraint system and generate witness via SnarkJS
set -e

echo "=== Compiling Circom Zero-Knowledge Verification Circuit ==="

CIRCUIT_SRC="src/credential_verifier.circom"
INPUT_JSON="inputs/input.json"

if command -v circom &> /dev/null && command -v snarkjs &> /dev/null; then
    echo "[1/4] Compiling circuit to R1CS & WASM witness generator..."
    circom "$CIRCUIT_SRC" --r1cs --wasm --sym -o build/

    echo "[2/4] Computing witness using sample input..."
    node build/credential_verifier_js/generate_witness.js build/credential_verifier_js/credential_verifier.wasm "$INPUT_JSON" build/witness.wtns

    echo "[3/4] Generating Groth16 zk-SNARK proof..."
    snarkjs groth16 setup build/credential_verifier.r1cs pot12_final.ptau build/circuit_final.zkey
    snarkjs groth16 prove build/circuit_final.zkey build/witness.wtns build/proof.json build/public.json

    echo "[4/4] Verifying proof authenticity..."
    snarkjs groth16 verify build/verification_key.json build/public.json build/proof.json
    echo "[SUCCESS] Zero-knowledge proof verified valid."
else
    echo "[INFO] Circom / SnarkJS toolchain not installed in host environment."
    echo "Running self-contained verification and constraint satisfaction harness..."
    node runner/run.js
fi
