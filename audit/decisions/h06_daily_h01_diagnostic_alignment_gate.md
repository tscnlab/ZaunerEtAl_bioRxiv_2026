# H06 daily H01-aligned diagnostic gate

Controlling decision: **H06-D-014**  
Author gate: **H06-D-G2A**  
Change ID: **CHG-131**  
Date: 2026-08-12  
Status: **independently verified; awaiting explicit author disposition at H06-D-G2A**

## Verified result

The bounded H06-D-014 amendment is complete without a fit, refit,
prediction, resampling run, deletion run, or change to any raw p-value or FDR
value. All 468 non-L10 production cells and the three stored shifted-log L10
pilot cells received family-appropriate visual residual review.

- All 471 visual reviews are `REVIEW_LIMITATION`; none is `FAIL_GROSS`.
- Of the 468 non-L10 cells, 378 are `WARN_REVIEW` and 90 are
  `FAIL_MAJOR_GATE`.
- AR, participant/site deletion, exact-period, and response-family evidence
  remains mandatory but nonblocking sidecar evidence under the author-approved
  H01 diagnostic architecture.
- The stored shifted-log L10 pilot remains a diagnostic pilot only. Its three
  cells are `WARN_REVIEW`; its p-values remain unaccepted, its named FDR slot
  remains unpopulated, and full L10 production remains unauthorized.

For the primary dataset, 28 association tests and 10 site-interaction tests
are FDR-supported and have no hard diagnostic gate. Thirty-two become
diagnostically claim-eligible under the H01 architecture because AR and other
sensitivity sidecars no longer act as automatic failures. Every such result
must retain its row-specific limitations, and timing site interactions remain
sensitivity-dependent.

## Newly verified gap clock-unit failure

The 90 hard failures are exactly the five gap-timing-unaware clock outcomes
(M10 midpoint, L10 midpoint, mean timing above 250 lx melEDI, first timing
above 250 lx melEDI, and last timing above 250 lx melEDI) across two
placements, three sample roles, and three predictors.

The pinned gap source already stores these values in clock hours. The
H06_daily adapter divided them by 60 as if they were clock minutes. Fresh R
4.6.1 verification reproduced that every affected stored response equals its
gap-source value divided by 60. Consequently:

- all 90 stored gap timing cells are scientifically uninterpretable;
- all six gap-timing-unaware 15-slot FDR families are blocked, including
  dependent ranks and adjusted values for otherwise unaffected slots;
- all 234 primary cells and 144 non-timing gap cells are unaffected by this
  unit defect; and
- no current gap-timing-unaware H06_daily FDR claim is eligible until a
  separately authorized repair is completed.

## Preservation and verification

Fresh R 4.6.1 focused verification passed 471 visual reviews, the 378/90
classification, all six blocked families, exact frozen raw-p and FDR text
tokens, 32 newly eligible primary claims, and 1,011 protected identities.

Accepted identities:

- rendered report:
  `0414e34934c1924f5406e932d913a2c33766dc68d62e19caa96db40a790318cb`;
- transition:
  `c5d1821a568b4c70f495bb0d571d098fd1261e32064c2fc892d9465dcf09e0b0`;
- task shared-change request:
  `6321ae8cd9129fba1aa5f40caa5ad1be475ddd3e6dee620dd5649e6f50a645cb`;
- output manifest:
  `532ba70560caf1cf51de50429b4511865bad76ec44662d06d55375de85adf2ac`;
- report manifest:
  `53f845429847123b21399a66f9e17e79c74e7343cd44f29b55f7d2de11f6b1e9`;
- focused test:
  `801fc446a7b5e0d55b55249d865c8dcba2c637901493fb97c2e16370e4686d26`.

## Mandatory stop

H06_daily remains stopped at **H06-D-G2A**. CHG-131 is a coordinator
verification record, not a new author decision. This verification does not accept
the amended Stage 2 result, authorize repair, or authorize Stage 3/4.

If the author elects to retain the gap sensitivity, the prospective minimum
repair is task-owned and bounded: convert the five gap clock-hour outcomes to
the registered scale exactly once, rebuild only the 90 affected cells, repeat
their hard-gate and visual review, recompute the six complete dependent FDR
families, preserve all 378 unaffected cells byte-for-byte, and stop at a new
author gate. No shared preparation change is required because the error is in
the H06_daily adapter.
