# H01 METRIC-010 production-bootstrap review

Status: **PRODUCTION - 1,000 successful joint bootstrap refits**

## Execution summary

Production completed all 8 targets with 1,000 successful joint refits retained per target (8000 used refits in total). There were 2 failed and 2 warning refits.

Observed target wall time summed to 320.9 seconds using four refit workers per sequential target.

Eight completed-target checkpoints and draw files are present. The production draws occupy 458,952 bytes. Peak memory was not instrumented per child process.

The current-input bridge passed for all eight MDER targets, and all 1169 canonical H01 artifacts checked before and after production were byte-identical.

## Production uncertainty summary



|Dataset                    |Placement |Sample        |Marginal R²          |Conditional R²       |Participant-associated share |Site part R²         |Photoperiod part R²  |Latitude part R²     |
|:--------------------------|:---------|:-------------|:--------------------|:--------------------|:----------------------------|:--------------------|:--------------------|:--------------------|
|Primary dataset            |Chest     |All available |0.084 [0.056, 0.205] |0.886 [0.862, 0.911] |0.801 [0.686, 0.836]         |0.077 [0.046, 0.188] |0.022 [0.000, 0.082] |0.052 [0.005, 0.124] |
|Primary dataset            |Chest     |Paired/common |0.296 [0.216, 0.413] |0.641 [0.572, 0.713] |0.345 [0.244, 0.430]         |0.110 [0.063, 0.210] |0.192 [0.101, 0.285] |0.027 [0.001, 0.078] |
|Primary dataset            |Near eye  |All available |0.278 [0.213, 0.381] |0.605 [0.546, 0.682] |0.327 [0.241, 0.400]         |0.096 [0.060, 0.178] |0.130 [0.067, 0.206] |0.027 [0.003, 0.069] |
|Primary dataset            |Near eye  |Paired/common |0.226 [0.159, 0.341] |0.516 [0.435, 0.610] |0.289 [0.192, 0.372]         |0.074 [0.041, 0.166] |0.110 [0.045, 0.182] |0.009 [0.000, 0.041] |
|Gap-timing-unaware dataset |Chest     |All available |0.084 [0.056, 0.204] |0.889 [0.866, 0.915] |0.805 [0.691, 0.837]         |0.077 [0.046, 0.189] |0.021 [0.000, 0.074] |0.051 [0.006, 0.124] |
|Gap-timing-unaware dataset |Chest     |Paired/common |0.299 [0.221, 0.424] |0.639 [0.578, 0.719] |0.340 [0.233, 0.427]         |0.112 [0.063, 0.218] |0.195 [0.104, 0.286] |0.028 [0.002, 0.081] |
|Gap-timing-unaware dataset |Near eye  |All available |0.280 [0.219, 0.376] |0.603 [0.542, 0.676] |0.323 [0.242, 0.391]         |0.094 [0.058, 0.174] |0.131 [0.068, 0.203] |0.027 [0.003, 0.066] |
|Gap-timing-unaware dataset |Near eye  |Paired/common |0.228 [0.159, 0.351] |0.516 [0.431, 0.606] |0.288 [0.192, 0.360]         |0.076 [0.040, 0.171] |0.110 [0.043, 0.191] |0.009 [0.000, 0.046] |

Values are point R² summaries with production 95% joint parametric percentile intervals. Term components can overlap and must not be summed.

## Integration status

The production bootstrap itself passed. Accepted H01 report integration remains pending the focused production verifier and disposition check.
