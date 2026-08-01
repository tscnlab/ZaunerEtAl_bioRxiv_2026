# Superseded H01 response diagnostics

These two files preserve the diagnostic evidence that opened the H01 response
gate. They are not current analysis outputs.

- `H01_pre_sleep_three_hour_diagnostic.csv` tested a three-hour ceiling that
  the author subsequently rejected. The approved outcome is the cumulative
  calendar-day pre-sleep duration, with no three- or six-hour truncation and a
  warning only for values strictly above six hours.
- `H01_l10_noon_conversion_diagnostic.csv` tested the submitted noon
  conversion. The approved primary conversion now shifts clock times strictly
  later than 16:00; the noon conversion remains a named sensitivity.

Current results and identities are in
`../H01_gate_a_pre_sleep_calendar_day.csv`,
`../H01_gate_b_l10_conversion.csv`, and
`../H01_major_gate_provenance.csv`.
