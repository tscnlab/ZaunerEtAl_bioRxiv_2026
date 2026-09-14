# Descriptives shared-change request

Status: **RESOLVED on 2026-08-11**.

The earlier stop correctly detected that the descriptives-side provenance
pins predated METRIC-010. The task-owned descriptive contract now consumes the
verified metric, base-data, site-context, and preanalysis manifests produced by
that shared rebuild. No shared preparation file was edited by the descriptive
refresh.

The controlling refresh evidence is recorded in
`audit/handoffs/descriptives_mder_METRIC-010_handoff.md`.
