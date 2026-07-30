# H03/H04 category-support gate

Status: major estimand gate prepared; no exposure outcome inspected  
Date: 2026-07-30  
Runtime: R 4.6.1

## Scope and safeguards

`audit/scripts/audit_h03_h04_category_support.R` used only the verified,
normalized hourly light-exposure diary, its aggregate free-text audit, and
the preregistration and H01–H04 migration records. It did not read a MEDI,
LIGHT, illuminance, placement, metric, model, estimate, or p-value column. It
did not fit a model or join an exposure outcome. All exported CSVs contain
aggregate counts only; no participant, participant-day, source-row, or
timestamp key and no free-text content is exported.

The exact inputs were:

- normalized diary:
  `06aa306411d7dbe48407e900b557ffed431b1bfb8eb4840bdbc0446988207f59`;
- normalization manifest:
  `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`;
- preregistration contract:
  `117b3d075df5ee8c822fba70b3cc0b7b5240581ab500c14e2880514474ac4225`;
  and
- H01–H04 migration map:
  `1541e912e549ad47b003da67b62c63deabc8159bac8045cb8287b960ba189573`.

The regenerated 14-artifact support manifest has SHA-256
`8631aa96c566a74df8eb6685e3e101d3f9cbe44d8cb34c28ba67e296746c5207`.
All support-table hashes and counts are unchanged; only stable input
provenance was repinned.

## One-hour interval and join audit

There are 30,172 analysis-eligible diary intervals. Every one:

- has a true-UTC duration of exactly 60 minutes;
- starts and ends at `:00:00`;
- has matching local-wall labels and UTC offsets; and
- has a unique `site + participant + interval_start_utc` key.

The corresponding local-wall keys are also unique. There are no duplicate
hour keys and therefore no cross-row primary-light or activity-label
conflicts created by aggregating the diary to participant-hour. A future
hourly exposure table can use a many-exposure-to-one-diary join on the true
UTC hour key, subject to an independent outcome-side cardinality assertion.
No such join was performed here.

Of the eligible intervals, 30,170 span 60 local-wall minutes. Two
spring-forward intervals, one at RISE and one at THUAS, span 120 local-wall
minutes but exactly 60 elapsed true-UTC minutes. They remain legitimate
one-hour intervals. A further 27 source rows, one RISE and 26 THUAS, lack
both endpoints and remain quarantined rather than being assigned to an hour.

## H03: primary light-source support

The normalized factor reproduces the seven declared categories in the
declared order. Each non-missing primary category has its corresponding
source flag set to true; there are no false or missing expected flags.

| Primary light-source category | Eligible hours | Participants | Participant-days | Sites |
|---|---:|---:|---:|---:|
| Electric light source indoors | 8,219 | 182 | 1,207 | 9 |
| Electric light source outdoors | 346 | 88 | 202 | 9 |
| Daylight indoors | 7,419 | 179 | 1,123 | 9 |
| Daylight outdoors, including shade | 2,575 | 180 | 870 | 9 |
| Emissive display light | 1,158 | 126 | 396 | 9 |
| Darkness during sleep | 7,932 | 171 | 1,138 | 9 |
| Light entering from outside during sleep | 1,215 | 91 | 371 | 9 |

All seven categories occur at every site and across all 24 local clock
hours. The two sleep categories, together comprising 9,147 eligible hours,
must be labelled bedside sleep-environment contexts, not worn ocular
exposure.

There are 1,308 eligible hours with a missing primary light source, from 41
participants, 168 participant-days, and six sites. Missing primary source is
not a category and would leave 28,864 hours for an H03 category model.

### Recommended placement-independent dictionary and estimability rule

1. Fix all seven declared categories before exposure outcomes are accessed,
   with indoor electric light as the reference. Do not delete a category
   globally because a placement-specific outcome is absent or a site cell is
   sparse.
2. Permit a pooled category contrast only when the diary supplies at least
   200 eligible hours, 20 participants, and three sites; the category is
   connected to the indoor-electric reference; and the fixed-effect design
   is full rank. All seven categories pass this diary-only rule. The
   site-plus-category design is rank 15 of 15.
3. Permit a site-specific contrast only when both the target and reference
   have at least 20 hours and five participants at that site, at least five
   participants report both contexts, and the relevant design remains full
   rank. The indoor-electric reference meets its rule at all sites. Under
   this rule, 57 of 63 declared category-by-site cells are supported.
4. Mark an unsupported site-specific contrast as support-non-estimable with
   its reason. Keep its category in pooled estimates, sample flow, and
   descriptive tables.

The six unsupported site-specific cells are:

- electric light outdoors at BAUA: 4 hours, 4 participants, 3 also reporting
  indoor electric light;
- electric light outdoors at RISE: 8 hours, 2 participants, 2 shared;
- electric light outdoors at TUM: 10 hours, 3 participants, 3 shared;
- emissive display at TUM: 37 hours, 4 participants, 4 shared;
- external light during sleep at FUSPCEU: 3 hours, 2 participants, 2 shared;
  and
- external light during sleep at KNUST: 15 hours, 6 participants, 6 shared.

The complete seven-category site interaction matrix is algebraically full
rank, 63 of 63, but algebraic rank does not make these six sparse contrasts
stable. Adopting the proposed support thresholds affects site-specific
reporting and therefore requires author approval before H03 fitting.

## H04: activity encoding and overlap

The eight activity flags are block-complete: no row has only some activity
flags missing. Their eligible-hour cardinality is:

| Activity state | Hours | Percent of eligible hours | Participants | Participant-days |
|---|---:|---:|---:|---:|
| Exactly one selected | 26,094 | 86.48% | 169 | 1,250 |
| Multiple selected | 1,421 | 4.71% | 97 | 469 |
| All eight explicitly false | 431 | 1.43% | 14 | 45 |
| All eight missing | 2,226 | 7.38% | 20 | 116 |

Among the 27,515 hours with at least one activity selected, multi-label hours
account for 5.16%. They occur at eight sites; KNUST has none. They comprise
46 distinct flag combinations, led by sleep plus home (280 hours), home plus
vehicle travel (154), bike/on-foot travel plus indoor work (115), and vehicle
travel plus indoor work (110). This breadth makes multi-label data
structural rather than a single missing-value code.

Missingness and zero selection are also strongly site-patterned: MPI supplies
2,032 of the 2,226 all-missing hours, 48.83% of its eligible diary hours;
THUAS supplies 429 of the 431 explicitly zero-selected hours, 14.84% of its
eligible hours. These rows cannot be interpreted as a substantive
“no activity” reference.

A naive pivot of every true flag would create 28,998 long rows from 27,515
unique any-selected participant-hours: 1,483 extra copies of an eventual
hourly outcome. Thus, the current long-factor strategy would duplicate
outcomes for the 1,421 multi-label hours even though source-to-hour
aggregation itself creates no duplicate key.

For exactly-one hours, all eight declared activities occur at all nine sites:

| Declared activity | Exactly-one hours | True in multi-label hours |
|---|---:|---:|
| Sleeping in bed | 9,107 | 306 |
| Awake at home | 7,448 | 764 |
| Public-transport/car travel | 1,008 | 501 |
| Bike/on-foot travel | 525 | 426 |
| Indoor/home-office work | 5,885 | 445 |
| Outdoor work | 267 | 87 |
| Free time outdoors | 850 | 208 |
| Other | 1,004 | 167 |

The exactly-one site-by-original-category matrix is algebraically full rank,
72 of 72, although some cells remain practically sparse; for example, TUM
has two exactly-one outdoor-work hours from one participant. The additive
eight-indicator design is full rank, 17 of 17. Its complete site-interaction
design is rank 80 of 81: `siteKNUST:act_other` is aliased because KNUST has
only exactly-one activity rows. The same absence of a KNUST multi-label
profile makes an explicit profile-by-site interaction rank 80 of 81.

Aggregate source auditing records 908 nonblank original activity-description
fields and 863 nonblank translated fields. Their contents are excluded from
the analytical RDS and were neither read nor exported here. Consequently,
`other` can be retained as a declared category, but no outcome-blind
row-level recoding from its description is available in the model-ready
input.

## Pre-outcome H04 options

### Option A: joint indicator block

Retain the 27,515 hours with at least one selected flag: 170 participants,
1,251 participant-days, and all nine sites. Estimate one global activity
indicator block, then predeclare standardized exact-one profiles for
interpretable comparisons. This uses multi-label hours without duplicating
an outcome, but changes H04 from a nominal primary-activity estimand to an
additive co-activity estimand. The primary multiplicity unit would be one
global eight-indicator block; profile contrasts would form one separate
declared family. A full site-by-indicator interaction is not currently
identifiable without reparameterization or a supported subset.

### Option B: exactly-one original eight-category factor

Retain 26,094 hours: 169 participants, 1,250 participant-days, and all nine
sites. This preserves 94.84% of any-selected hours and operationalizes the
preregistered singular “primary activity” construct without duplicating
outcomes. It excludes 1,421 multi-label hours. Multiplicity would comprise
one activity omnibus plus all seven activity-versus-home contrasts in one
declared family, with site heterogeneity separate.

### Option C: deterministic adapted or combination factor

The current five-level mapping retains 25,090 hours: 169 participants, 1,249
participant-days, and all nine sites. It excludes 1,004 exactly-one `other`
hours and combines bike/on-foot travel, outdoor work, and outdoor free time.
It preserves the recognizable five-level manuscript display, but changes
the declared constructs and reduces the contrast family to four. A
deterministic ninth “multi-label” level would retain all 27,515 any-selected
hours but collapse 46 substantively different combinations into one
heterogeneous category; it is not recommended as the primary estimand.

## Outcome-blind recommendation and approval gate

Use **Option B, the exactly-one original eight-category factor, as the H04
primary analysis** because it most directly matches the preregistered
singular primary-activity estimand and prevents outcome duplication. Use
Option A as the predeclared multi-label sensitivity, reporting whether the
global activity conclusion and standardized exact-one contrasts are stable.
Use the recognizable adapted five-level mapping as a separate named
sensitivity rather than silently discarding `other` or redefining active
travel and outdoor activity.

This recommendation changes the current adapted five-level primary analysis,
excludes multi-label hours from the primary model, and defines new
multiplicity families. It therefore requires explicit author approval before
H04 fitting. If the author confirms that concurrent co-activities, rather
than one primary activity, were the intended questionnaire construct, Option
A should be reconsidered as primary at the same major gate.

No support count establishes an exposure association. Every H03/H04 effect,
interval, model, diagnostic, and claim remains unopened.

## Artifacts and reopening

Aggregate outputs and their row counts and hashes are listed in
`audit/reconciliation/preparation06/category_support/artifact_manifest.csv`.
The manifest hash is
`95e7f2b22da08732dc3439ba0c46e08cf57acaeb32f1b18ee7109fe62438af91`.

Reopen this gate after any change to the normalized diary, interval-time
mapping, primary-light factor, activity flags, questionnaire interpretation,
site set, category dictionary, minimum-support rule, placement-independent
join key, or approved H04 estimand.
