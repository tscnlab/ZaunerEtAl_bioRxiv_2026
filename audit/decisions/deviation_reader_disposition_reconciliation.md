# Reader-facing deviation disposition reconciliation

Decision ID: **REPORT-016**  
Date: 2026-08-12  
Status: **verified reader-disposition overlay; deviation-register history preserved**

## Decision

The central `deviation_register.csv` remains the preserved historical audit
record of what was discovered, proposed, or still undecided at the time each
row was entered. It must not be translated verbatim into a document that
purports to describe the analyses now accepted by the author.

`audit/ledgers/deviation_reader_dispositions.csv` is the authoritative current
reader-disposition overlay. It contains exactly one row for every stable ID in
the historical register. The reader page must keep each register ID and
preregistered/expected statement but use the overlay's reader section, current
status, current implementation, current rationale, current interpretive
consequence, related/superseding IDs, and current source locators.

The underscore-delimited `current_status` values are validation codes, not
reader prose. The generated page must translate them into short plain labels
such as **Implemented**, **Still open**, **Resolved historical issue**, or
**Technical record**, while retaining the exact code in machine-readable
source data for verification.

No reader-generation code may silently infer a current disposition from a
worker handoff or substitute the historical `observed_or_approved` wording for
the overlay.

## Reader sections

The consolidated preregistration-deviation page must distinguish four kinds of
records:

1. **Current scientific deviations.** These are departures from the
   preregistered population, construct, metric, estimand, model, sample, or
   multiplicity specification that remain relevant to interpretation. They
   receive full reader entries.
2. **Current qualifications.** These are scientifically relevant items whose
   project-wide sensitivity or closure remains incomplete. They must be
   labelled open rather than implied to be resolved.
3. **Resolved implementation history.** These records explain consequential
   errors or pre-repair implementations that have been corrected or
   superseded. They belong in a separately labelled history section and must
   never be described as the current method.
4. **Technical provenance.** Documentation and environment/API migration
   records belong in a compact technical-provenance section, not in the main
   scientific-deviation narrative.

The 86-row overlay contains 60 current scientific deviations, one current
qualification, 19 resolved implementation-history records, and six
technical-provenance records.

Only `DEV-*` rows and the small subset of `IMP-*`/`REP-*` rows that change a
scientific population, construct, signal-validity rule, metric, estimand, or
interpretation belong in the full main scientific section. A prefix alone
does not determine placement: `IMP-*`, `REP-*`, and `DOC-*` rows classified by
the overlay as resolved history or technical provenance must stay in those
separate sections. This prevents a repaired code defect or runtime migration
from being presented as if it were a current preregistration departure.

## Scientific reconciliation

The accepted H03-H11 worker handoffs replace the pre-repair descriptions in
DEV-022 through DEV-048 and the associated IMP rows. In particular:

- H03 and H04 now separate study-site-average category associations from
  category-by-site interactions and use complete FDR families;
- H04 uses the author-approved weighted long activity representation;
- H05 uses the accepted site-adjusted 17-metric by four-factor model package;
- main H06 uses the accepted hourly population-average robust route and
  separate declared families;
- H07 retains all nine metrics and uses the derivative-defined descriptive
  plateau rule rather than a ceiling claim;
- H08 separates average associations from site interactions;
- H09 includes distinct MCTQ and MEQ models and four complete five-outcome
  families;
- H10 includes both age-by-site and biological-sex-by-site inference with four
  complete 17-metric families; and
- H11 uses the inherited H02 temporal architecture, a global robust complete-
  curve test, secondary level/shape attribution, pointwise rather than
  simultaneous local intervals, and an explicitly non-causal activity-context
  sensitivity.

The overlay also keeps DEV-003 open as a current population-generalization
qualification, distinguishes true ongoing downstream resealing under
DEV-052-DEV-054 from already repaired shared preparation, and moves resolved
IMP records and R/LightLogR migration records out of the main scientific
narrative.

## Fail-closed generation contract

R 4.6.1 generation must stop unless all of the following hold:

- the deviation register and hypothesis crosswalk retain unique and identical
  stable-ID sets and matching historical statuses;
- the overlay has exactly one row for every register row and no other row;
- the overlay sections and current statuses are non-empty and valid;
- all current source locators resolve;
- the merge preserves all 86 stable IDs and their lower-case Quarto anchors;
- no row from the overlay is replaced with historical `observed_or_approved`
  wording; and
- current scientific deviations, current qualifications, resolved history,
  and technical provenance remain visibly distinct.

Dynamic Quarto links must target
`preregistration_deviations.qmd#<lower-case-stable-id>` and must not hard-code
rendered HTML paths.

## Execution boundary

This reconciliation changes no scientific input, model, metric, estimate,
interval, p-value, multiplicity decision, figure, table, or claim. It
authorizes deterministic reader-document generation only. `DOC-001` remains
labelled as closing on a successfully verified render and link audit of the
new page; that later closure must be recorded without rewriting its historical
register row.
