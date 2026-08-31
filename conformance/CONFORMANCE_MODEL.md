# MCL Conformance Model

Status: **Research Governance Draft**

MCL conformance is layer-specific and capability-explicit. There is intentionally no single vague `MCL compatible` claim.

## 1. Conformance claim

An implementation claim identifies:

- MCL Core major/spec revision;
- MCL Wire major version;
- supported semantic categories/opcodes;
- supported extensions;
- MCL Link features;
- transport bindings and profile IDs;
- node role (receive, transmit, half-duplex, full-duplex as applicable);
- context-compression support;
- security/freshness hooks implemented;
- applicability profile, if any.

## 2. Implementation Conformance Statement (ICS)

Every implementation intended for interoperability testing SHOULD publish a machine-readable ICS.

An ICS is a declaration of supported features. It is not proof that the implementation passes them.

## 3. Test classes

### C0 - Static registry conformance
No duplicate or illegal assigned values; supported IDs are valid.

### C1 - Canonical encoding
Semantic object -> exact canonical bytes and exact bytes -> semantic object.

### C2 - Negative decoding
Malformed lengths, impossible values, unknown mandatory extensions, stale context, and incompatible versions are rejected as required.

### C3 - State-machine conformance
Discovery, negotiation, context establishment/reset, adaptation, handoff, timeout, and fallback transitions.

### C4 - Cross-implementation interoperability
Independent implementation A communicates with B in both directions.

### C5 - Transport-profile conformance
Binding-specific physical/link test cases.

### C6 - Robustness/interoperability matrix
Device diversity, timing errors, malformed peers, multi-node behavior, and other non-minimum ecosystem tests.

C6 may exceed minimum qualification requirements but is important for ecosystem quality.

## 4. Evidence levels

Research results use a separate evidence label:

- `E0 ANALYTICAL`
- `E1 DETERMINISTIC_SIMULATION`
- `E2 RECORDED_CHANNEL_REPLAY`
- `E3 CONTROLLED_OVER_AIR`
- `E4 MULTI_DEVICE_OVER_AIR`
- `E5 OPERATIONAL_ENVIRONMENT`
- `E6 INDEPENDENT_INTEROPERABILITY`

Conformance class and evidence level are different axes.

## 5. Passing behavior

A conforming implementation is judged not only on successful frames but also on deterministic rejection.

For safety-relevant interoperability:
- accepting an invalid/ambiguous frame can be worse than dropping a valid one;
- unknown authority claims MUST NOT acquire authority through fallback behavior;
- unknown context MUST NOT be decoded using a guessed context;
- a decoder MUST NOT reinterpret bytes under another schema after a context failure.

## 6. Qualification future

The present private research project does not operate a certification program.

If MCL becomes externally adopted, a future qualification program should separate:
- feature declaration (ICS);
- mandatory conformance test cases;
- independent interoperability tests;
- physical/profile test facilities where calibration is required;
- ecosystem robustness tests beyond minimum conformance.
