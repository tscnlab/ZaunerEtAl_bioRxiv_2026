# Pre-dispatch helper-path resolution

14 September 2026. This is a coordinator staging correction before any Writer dispatch or production operation.

The first dispatch-sealer attempt assigned two accepted helper hashes to their same-named older canonical script paths and stopped before writing a dispatch seal. The accepted archival preflight identifies their actual paths:

- `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/helpers/prepare_word_manuscript.py`, SHA-256 `e89329f60bb477bf726fb1ccc0f3acecd107bab81d4541a1fca2633cf54415aa`.
- `audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/helpers/embed_accepted_svg_figures.py`, SHA-256 `75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b`.

The two untouched files under `scripts/manuscript_nature_health/` instead have SHA-256 `830511ae26935cc596d242dcc04cc2db8ae168723718af4d26b6485f1fe9cf7e` and `2b5533b192013b7efabbbc6eb963d40f8a8ec1cfb9bd1286a4be30eb1f2197d6`, respectively. They are not the accepted helper baselines. This was a metadata path error, not evidence that either helper changed during the handoff.

Only the new coordinator order and sealer path bindings were corrected. No helper, source, table, image, accepted manifest, HTML, Word file or scientific input was changed, and no owner was woken. The final dispatch seal records both accepted baselines and the preserved same-named live files explicitly.
