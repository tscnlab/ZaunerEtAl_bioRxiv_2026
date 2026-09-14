# BA-018 derivative-gate verifier recovery 001

Date: 2026-09-11. Authority: BA-018 / CHG-157.
Recovery ID: BA018-DERIVATIVE-GATE-RECOVERY-001.

Status: stopped state independently accepted; the exact additive verifier and
versioned fit-driver continuation below are released only on sealed dispatch.
The scientific specification and all BA-018 limits are unchanged. No second
batch, fit-slot reset, render reset or new author linkage choice is authorized.

## Independent stopped-state disposition

The owner Stage 2 root is:

`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/`

Its stopped `final_manifest.csv` remains
c32e37760fea1226a420d8d42552f48862adfca41d044fbc56581497761328f0,
54 exact unique non-circular members. The separate verification remains
7272f682e0fd4cbb560d2f54179fdbab924ed13b014f0e21eb0cbd98c5a56cab.
The handoff remains
5a4c7c05e8c77b2971d264cb9d62dc257efe3baca2f0fd939ee0b293b4e1e2bf.

Independent R 4.6.1 review confirms the defect: the saved derivative CSV has
four repeated automatic-gradient columns and four repeated difference columns,
not an exact `absolute_difference` column. The original threshold operation
used `max(NULL)`, so its PASS is invalid. This is a verifier schema defect, not
a model or likelihood failure. Never use that PASS alone to start fitting.

Reading only the saved numbers, the four named derivative pairs reconcile
componentwise to their saved differences within 1e-12. The largest absolute
difference is 1.2271492988435995e-08, finite and below the original 1e-4
threshold. All other 14 validation gates remain required. The stored 24-case
probability/moment records and both 10-row frame/design checks also pass.
No objective, gradient, model, frame, compiler or simulator was called by the
independent review.

The exact proposed checker was tested against ten malformed input cases,
including empty/missing schema, duplicate or misordered parameters, nonfinite
and nonnumeric values, nonconstant repeated matrix rows, inconsistent stored
differences and values above the threshold. All ten fail closed. The complete
standalone additive gate was replayed in an isolated temporary tree and both
PRIMARY-ANY and PRIMARY-80 driver prefixes passed through the corrected gate.
No fit portion of either driver was evaluated.

Independent checks pass 19/19. The 23-member historical implementation manifest,
all 56 current stopped files, 2,174 execution inputs, 2,066 historical protected
paths and 89 Stage 1 members remain exact. Both recorded children, PIDs 28004
and 28174, are absent in a read-only process check. No computation lock,
primary output, estimand or report is present.

The first central temporary audit used an environment without the normally
attached utils functions and stopped at `read.csv`; its script and stop note
are retained. Only that audit environment was corrected. No owner source or
prospective checker changed for that infrastructure issue.

## Exact write and code boundary

Preserve all 56 stopped files byte-for-byte, including the original validation,
implementation manifest, code, compiled objects, frame files, job records,
assessment, handoff, gate and final manifest. Do not overwrite or reclassify an
old row as a current successful gate.

Copy only the two exact centrally supplied files from this release's
`prospective_code/` into these previously absent owner paths:

1. `code/05_saved_derivative_gate_v2.R`, SHA-256
   25dfbbc1e137cf4924970dec3ad11fb673c4d74fe54511d53dac723e78036b9a,
   7,841 bytes.
2. `code/02_fit_primary_gate_v2.R`, SHA-256
   f0b1cd0dababf36701a0254d3a32f5918f42026525cd7778749fc39d158bff1e,
   5,099 bytes.

Both already parse and pass Air. Do not reformat, adapt or rewrite them. The
versioned primary driver differs from original `code/02_fit_primary.R` only
by replacing one gate expression with the mapping check plus a call to the
new additive gate. Exact inverse replacement reproduces the original SHA
ee428f805cc6d7adaf70c68530a1a2aa82bedd88e271919bf4d78ae862fc2374.
All fit, optimizer, initialization, reproduction and model-output expressions
remain unchanged. The original driver remains in place, so the historical
implementation manifest remains fully exact and no self-pin exception is needed.

The only new verifier output root is
`likelihood/derivative_gate_recovery_v2/`. Its five-member non-circular manifest
must bind the two versioned code files, saved-value reconciliation, additive
gate and scope record. This gate explicitly sets
`historical_derivative_pass_used` to FALSE and verifies all 14 other gates.
It must require exactly four finite named derivatives and a finite scalar
maximum strictly below 1e-4. Do not modify or regenerate the original saved CSV.

The new `completion_v2/` subdirectory may hold continuation identity/reverse
proofs, new complete or stopped handoff, assessment, author gate, final manifest
and verification. It replaces only the now-occupied final-package path
templates for this continuation. Keep the existing top-level stopped package
unchanged. New statistical outputs otherwise use the existing accepted Stage 2
path contract. No write outside the original Stage 2 root is released.

## One additive gate, then the unconsumed work only

1. Before writing, rehash the central release, all 56 stopped identities, the
   23-member implementation manifest and all existing execution inputs. Confirm
   the two new code paths and recovery output root are absent and no Brown
   computational job or lock is active.
2. Copy the exact versioned files, verify their hashes, parse/Air status and
   inverse proof. No preliminary likelihood or frame execution.
3. Invoke the unchanged `code/run_bounded_job.py` once with job ID
   `VERIFY-SAVED-DERIVATIVE-GATE-V2`, ordinary limit 120 seconds and driver
   `code/05_saved_derivative_gate_v2.R`, under the exact accepted R 4.6.1 library
   and BA-018 environment. This reads saved values only. Preserve its new job
   record alongside, not over, the two existing jobs.
4. On exact PASS, accept the additive fit-start gate conditionally under this
   independently replayed authority and proceed to the first unconsumed
   PRIMARY-ANY fit using `code/02_fit_primary_gate_v2.R`. PRIMARY-80 follows
   only after the original reproduction and parent gates pass. Use the versioned
   driver for those two entries, not the original gate-defective driver.
5. Continue the remaining BA-018 finite scientific plan only as originally
   authorized. This is not a new batch. Existing frame preparation and the
   likelihood job must not be rerun. Ordinary frozen-frame-to-design mapping
   inside the unchanged fit driver is still part of its original fit interface.
   Do not recompile, reload historical scripts for execution, regenerate saved
   derivatives or change the model/optimizer equations.

The two consumed jobs retain their exact 11.036231749982107 accumulated seconds.
The new verifier job and every later scientific job add to the same supervisor
accumulator and 1,200-second ceiling. No primary fit slot or report render was
consumed by the stopped validation. No failed job retry or extra optimization
restart is created by this recovery. A genuinely new defect stops and seals
once without another attempt.

The original scientific plan, family/claim gates, 30 nominal plus at most 21
conditional fit slots, per-job limits, maximum diagnostic draws, preservation
and single-report conditions remain controlling. This record grants no new
render allowance. Coordinate the original conditional report QA lease with
the Harmonizer when reached and honor browser-policy denials.

## Next stop

The author result stop remains BA-LB-G2-REVIEW. No replacement result is accepted
here. Current Stage 3/4, S5, Writer numerical integration, manuscript, selection
preview and website remain unchanged and held. Reader reports remain standalone
and results-led with only brief final-method grouping language.

This is a verifier-only clarification under the existing BA-018 / CHG-157 chain.
Neither central ledger needs another append. Release evidence and exact dispatch
identities are in `audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001/`.
