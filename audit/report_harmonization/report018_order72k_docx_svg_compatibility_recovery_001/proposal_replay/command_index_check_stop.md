# Independent checker index correction

The first coordinator verifier passed the 18-member proposal seal, all 139
fixture results, exact reverse proof, all 1,290 preservation rows and the six
future-command input pins. It then stopped because its command comparison
used argument 4 for the raw DOCX. In the actual vector, argument 1 is Python,
2 is the helper, 3 is the raw DOCX, 4 the table map, 5 the figure map and 6
the new output. The proposal command is correct and unchanged.

The original verify.R and its partial outputs are retained. The separate
verify_command_mapping.R completes strict named-role comparisons across both
entire command vectors, rehashes preservation evidence, checks the unused
destinations and records final evidence. It does not change the proposal,
invoke an entry point, create a DOCX or consume any owner allowance.
