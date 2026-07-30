# Placement-paper reading notes

Status: completed  
Reading completed: 2026-07-29  
Source status checked: 2026-07-29  
Coverage: PDF pages 1–66 of 66, read sequentially  
Source locator: <https://github.com/tscnlab/ZaunerDeVriesEtAl_JExpoSciEnvironEpidemiol_2026>  
Repository version inspected: `v1.0.0`  
Document title: *Toward scalable ambulatory light dosimetry: sensor-placement bias under naturalistic conditions*  
Audited PDF SHA-256: `9cf8309c753d6ad753ac1d772927996d1035f59dadfa3b62523a810897ca67e3`

No public preprint was found at the last check on 2026-07-29. The work is
therefore treated as a submitted/unpublished related manuscript until a
public, citable version is verified. No DOI or other publication identifier is
inferred here.

## Reading coverage log

- PDF pages 1–12: completed.
- PDF pages 13–24: completed.
- PDF pages 25–36: completed.
- PDF pages 37–48: completed.
- PDF pages 49–60: completed.
- PDF pages 61–66: completed.

## Purpose and evidential role

The companion manuscript assesses how wearable light-logger placement affects
naturalistic personal-light-exposure measurements. It is directly relevant to
the proposal to combine glasses- and chest-position data in the present study.
It does not supply a health outcome and it does not turn the two positions
into interchangeable measures of ocular exposure.

The companion analyses are exploratory. In particular, the reported
placement and site-by-placement p-values are unadjusted. Counts of nominal
differences below are descriptive evidence about the breadth of placement
sensitivity; they are not confirmatory discoveries and must not be combined
with, or substituted for, the preregistered multiplicity families in the
present study.

## Extracted findings

| Evidence | Interpretation for this project | Boundary on use |
|---|---|---|
| Chest and near-eye measurements differed nominally for 19 of 54 evaluated metrics. | Placement sensitivity is too common to assume that a single fixed position coefficient makes the measurements interchangeable. | These are exploratory, unadjusted p-values. “Nominal difference” must be used instead of confirmatory significance language. |
| Site-by-placement terms differed nominally for 12 of 54 metrics. | Placement bias can vary by site or by site-linked contexts; a universal position adjustment is not supported. | These are exploratory, unadjusted p-values and do not establish a confirmatory interaction family. |
| Placement differences varied across context, participant, and participant-day. | A single additive correction cannot represent the observed heterogeneity. Paired structure and context must be respected whenever positions are compared. | Do not infer a latent calibration function or measurement-error model from these exploratory analyses. |
| Timing metrics were relatively robust to placement. | Timing outcomes may be suitable for explicitly labelled complementary chest analyses and support retaining the project-defined L10 metric, subject to the same coverage and gap-validity rules as the primary analysis. | Relative robustness is not equivalence and does not justify pooling by itself. |
| Level and temporal-dynamics metrics were less robust to placement. | Chest measurements cannot be treated as additional ocular observations for these metric classes. | Do not apply one universal correction across metrics. |
| During reported sleep, a worn-position contrast no longer has its normal interpretation because devices are placed by the bedside. | Sleep-period measurements describe the bedside sleep environment, not light reaching the eye while the logger is worn. | Do not describe sleep-period glasses-versus-chest results as ocular-versus-chest wearing-position bias. |
| The manuscript does not support one correction applicable to every metric and context. | No universal chest-to-glasses conversion will be implemented. | Any future calibration model would be a separate major methodological change requiring approval and independent validation. |

## Consequences for the Nature Health analysis

1. Near-eye measurements define the primary ocular-exposure construct.
2. Simple pooling of all glasses and chest records with only a fixed
   `position` term is rejected.
3. Chest analyses are complementary and should preferentially use paired or
   otherwise explicit common samples, with their own sample-flow accounting.
4. Site and placement availability must be shown because Tübingen lacks chest
   measurements and Costa Rica has sparse glasses measurements.
5. Position comparisons must preserve participant and participant-day pairing
   and distinguish metric classes and relevant contexts.
6. L10 is retained, but its use remains conditional on the common metric
   validity audit for coverage, gaps, state handling, and interpretation.
7. Sleep-period results must be framed as bedside sleep-environment exposure.

## Claims not supported by this source

- The two placements are equivalent.
- Chest measurements increase the independent sample size for ocular
  exposure.
- A fixed position term removes placement bias.
- One universal correction converts chest measurements to near-eye
  measurements.
- Nominal unadjusted p-values from the companion manuscript are confirmatory.
- Placement results demonstrate a health effect.

## Final-submission checks

- Recheck whether a public preprint, DOI, or accepted version exists.
- Verify the final title, author byline, and publication status from the
  public version before adding a numbered reference.
- If no public version exists, disclose the related submitted manuscript in
  the cover letter and avoid a numbered placeholder citation.

