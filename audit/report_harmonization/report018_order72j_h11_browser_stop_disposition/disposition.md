# H11 Order72j browser-policy stop disposition

Date: 2026-09-11.

Status: STOP_ACCEPTED_OPTIONAL_CANDIDATE_UNPROMOTED. No replacement browser
lease, retry, alternate route or promotion is authorized by this record.

## Verified state

The historical independent static acceptance remains valid only for the
bounded candidate structure and exact inverse proof. Candidate SHA-256 remains
ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e.
The 20-member historical owner seal and the 14-member new stopped QA seal
reproduce exactly. No intrinsic, 642-pixel or 708-pixel browser comparison
was completed. Actual Arial appearance, note containment, legibility and
renderer compatibility remain unverified.

The owner returned the following verbatim rejection from the retained tool
evidence without repeating the navigation:

> Browser Use rejected this action due to browser security policy. Reason: The browser URL policy blocks this action. Browser use cannot visit the requested page because its URL is blocked by the Browser use URL policy. The agent must not attempt to achieve the same outcome via workaround, indirect execution, raw CDP or browser commands, alternate browser surfaces, or policy circumvention. Proceed only with a materially safer alternative that does not require this blocked browser action; if none exists, stop and request user input.

The rejected call was `cua.createBrowserTab("iab", URL, { visible: true })`,
where URL was the file URL for the accepted H11 SVG:

`file:///Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`

This is an explicit anti-workaround denial, not merely a reported inability
to display a file URL. This disposition therefore does not authorize serving
that SVG over loopback, another browser surface, indirect navigation or raw
browser commands to obtain the same blocked comparison. The current lease
was properly released. The task-created blank tab was closed; the owner
records no server or listener was created and no SVG loaded.

## Controlling continuation boundary

- Preserve all H11 source, candidate, static and stopped QA evidence unchanged.
- Retain the previously accepted SVG. The optional candidate does not supersede
  it without the still-uncompleted visual and native-application checks.
- Do not request another task to perform the blocked H11 navigation.
- H07 and H09 remain independent tasks under their existing component-export
  authority. This optional H11 stop is not a dependency or a reason to suspend
  their static work. Their distinct visual work remains subject to the existing
  single-lease rule and to any browser-policy rejection encountered there.
- No Quarto, Word, LibreOffice, rasterization, source integration, scientific
  computation, canonical promotion or replacement render is released.

Authority is the existing Order72j component boundary and the actual browser
policy rejection. This is a stop classification only, not a new export order.

## Pins

- QA manifest: 546e387948c18b728c0810aa409324573b46b2fef9b6f724677876d8eb947281.
- Stop record: 099ab3159afe3010394e0e2f095f7b718b9378e590ca65e4b8e78abed3e3f7fb.
- QA return: b7240b7d00662afaf5898a917b29aeb13c344fad67303252cf00a3716d4ed076.
- Historical static owner manifest: eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0.
- Independent static manifest: 0380aa97d71d44a34184c2ffda92741c56b67a3a2ad27754b53c2fc5f73eea7b.

The non-circular manifest accompanying this disposition records its inputs,
read-only R verification and exact output identity. No prior seal is rewritten.
