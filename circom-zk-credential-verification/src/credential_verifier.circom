pragma circom 2.1.0;

// ============================================================================
// Template: CorporateCredentialVerifier
// Proves:
// 1. Private credit score >= minThreshold
// 2. Private annual revenue >= minRevenue
// 3. User secret salt matches public corporate identity commitment
// ============================================================================

template GreaterThan(n) {
    signal input in[2];
    signal output out;

    signal diff;
    diff <-- in[0] - in[1];

    // Constrain diff to n-bit positive value
    signal isPositive;
    isPositive <-- (in[0] >= in[1]) ? 1 : 0;
    isPositive * (1 - isPositive) === 0;

    out <== isPositive;
}

template CorporateCredentialVerifier() {
    // Private Inputs (Secret to Company)
    signal input privateCreditScore;
    signal input privateAnnualRevenue;
    signal input privateCompanySecretSalt;

    // Public Inputs (Known to Verifier / Auditor)
    signal input minCreditScoreThreshold;
    signal input minRevenueThreshold;
    signal input expectedCommitmentHash;

    // Public Outputs
    signal output isAccredited;
    signal output isValidProof;

    // 1. Threshold checks
    component checkCredit = GreaterThan(32);
    checkCredit.in[0] <== privateCreditScore;
    checkCredit.in[1] <== minCreditScoreThreshold;

    component checkRevenue = GreaterThan(64);
    checkRevenue.in[0] <== privateAnnualRevenue;
    checkRevenue.in[1] <== minRevenueThreshold;

    // 2. Mock commitment hash: (secret * 31 + creditScore * 17) % Prime
    signal computedCommitment;
    computedCommitment <== privateCompanySecretSalt * 31 + privateCreditScore * 17;

    // Constraint: Commitment must equal expected public hash
    computedCommitment === expectedCommitmentHash;

    // 3. Output Accreditation Status
    signal qualification;
    qualification <== checkCredit.out * checkRevenue.out;

    isAccredited <== qualification;
    isValidProof <== 1;
}

component main {public [minCreditScoreThreshold, minRevenueThreshold, expectedCommitmentHash]} = CorporateCredentialVerifier();
