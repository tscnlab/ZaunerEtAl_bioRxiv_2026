# Prospective geometry test, first attempt

Date: 2026-09-02

Status: stopped before rendering for coordinator disposition.

The temporary-only test passed all substantive geometry checks before failing one additional raw-serialization assertion:

- base portrait page size: 11,901 by 16,840 twips;
- generated portrait page size: 11,901 by 16,840 twips;
- generated landscape page size: 16,840 by 11,901 twips with landscape orientation;
- accepted landscape margins: left and right 648 twips, top and bottom 792 twips, with the reference header, footer, and gutter values retained;
- final portrait page size: 11,901 by 16,840 twips;
- final portrait margin attributes: exactly equal to the reference margin attributes;
- former US Letter geometry 12,240 by 15,840 twips: absent.

The failed extra assertion compared the raw serialization of an isolated copied `<w:pgMar>` element with that of the element after attachment to the document tree. A read-only probe showed identical attributes and zero children in both elements. The serialization differed only because the attached element inherited additional namespace declarations from the document root. No semantic OOXML or geometry difference was present.

No render, postprocessing pass, canonical output replacement, HTML render, or website write occurred after this stop.

Coordinator disposition `report018_order69_namespace_serialization_preflight_disposition.md` authorized replacing only the temporary raw-serialization comparison with recursive semantic element equivalence. The corrected temporary test passed on its single authorized run. Its full result is recorded in `prospective_geometry_test.json`.
