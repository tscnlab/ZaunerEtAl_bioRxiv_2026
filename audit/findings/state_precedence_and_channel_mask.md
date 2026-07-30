# State precedence and channel-validity finding

Finding IDs: `IMP-018`, `IMP-019`  
Status: repair approved; analytical rerun pending  
Date: 2026-07-30

## Confirmed state disagreement

The sleep diary and wear log describe related but distinct events. The diary
defines attempted-sleep and wake windows. The wear log can indicate when the
logger was removed or placed by the bed. The current pipeline preserves both
columns but does not derive a single explicit measurement-context variable.

R 4.6.1 verification of the saved stage-1 artifacts found:

| State relationship | Near-eye minutes | Chest minutes |
|---|---:|---:|
| `wear == "sleep"` outside diary Brown sleep | 49,997 | 53,377 |
| `wear == "off"` inside diary Brown sleep | 36,182 | 39,801 |
| Diary Brown sleep with no wear label | 112,548 | 131,136 |

The disagreements show that wear-log `sleep` is not a reliable alternative
sleep detector. Participants did not follow a strict `sleep`/`off`
declaration scheme and sometimes omitted wear entries.

## Approved primary rule

Preserve the raw diary and wear labels and derive a separate measurement
context:

- `bedside` when the diary-defined Brown state is `sleep`, using the
  `sleepprep`-to-`wake` interval;
- `worn_near_eye` or `worn_chest` outside diary sleep, except invalid
  non-wear;
- `invalid_nonwear` when wear state is `off` outside diary sleep;
- `off` inside diary sleep remains valid bedside sleep-environment
  measurement;
- wear state `sleep` is retained as provenance but has no analytical
  precedence and does not redefine diary sleep;
- a missing wear label does not establish non-wear;
- `site_leave` remains valid wear because the records describe leaving the
  site area while continuing to wear the logger; and
- an explicit conflict/source flag records which rule established the
  context.

Diary-defined attempted-sleep, pre-sleep, sleep, and wake windows remain the
behavioral windows for sleep-specific hypotheses. The author approved this
diary-authoritative rule on 2026-07-30. Wear-log sleep is reported only as a
data-quality disagreement, not promoted to an alternative analytical state.

All state intervals use half-open `[start, end)` bounds on true UTC instants.
For each participant, the first and last diary days retain the existing
full-day behavior: wake is bounded from local midnight to the first
three-hour pre-sleep interval and from the final diary wake to the next local
midnight. Wake carry-forward gaps longer than 24 hours remain unknown rather
than being imputed, while a valid three-hour pre-sleep interval and the
reported sleep interval on either side remain available. This preserves the
implemented diary interpretation without treating a terminal wake interval
as unbounded.

A clean R 4.6.1 exercise of the pinned nine-site diary and wear sources
produced no invalid or overlapping wear intervals. It reason-coded one diary
record with a missing wake and 21 wake carry-forward gaps longer than 24
hours. These exclusions affect only the unsupported interval; valid
pre-sleep and sleep records are retained.

## Confirmed channel-mask discrepancy

For wear state `off` outside diary sleep, the current preprocessing masks
MEDI but not LIGHT. Among those rows, LIGHT remains finite for 59,627
near-eye minutes and 64,240 chest minutes.

The approved repair is to preserve immutable raw channels, derive
channel-validity and exclusion flags, and apply the same invalid-nonwear mask
to analytical MEDI and LIGHT. MDER and other paired-channel quantities must
use identical intervals. This does not treat darkness, sleep, non-wear, and
missingness as interchangeable.
