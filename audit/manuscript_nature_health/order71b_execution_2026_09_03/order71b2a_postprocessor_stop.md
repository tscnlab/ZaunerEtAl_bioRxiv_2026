# Order 71b2a postprocessor stop

Date: 2026-09-03

Disposition: `STOP_BEFORE_BOOKMARK_MUTATION_OR_SAVE`

The amended 19-row dispatch manifest reproduced exactly under R 4.6.1, and
the focused source patch reversed exactly to the sealed postprocessor
preimage. The one authorized postprocessor invocation then stopped inside the
bookmark helper while recording the protected pre-existing bookmark XML:

```text
AttributeError: 'lxml.etree._Element' object has no attribute 'xml'
```

The failure occurred before the helper added any bookmark and before
`document.save()`. The intended new candidate path is absent. The frozen raw
DOCX, stopped candidate, canonical DOCX, accepted QMD, accepted HTML, and
integrated website retain their sealed identities.

The bounded implementation correction is to serialize generic bookmark
elements with `lxml.etree.tostring()` instead of using the python-docx `.xml`
convenience property. No page render, canonical promotion, Quarto render,
capture refresh, scientific or visible-content edit, or second artifact
marker occurred. A sealed recovery continuation is required before patching
or invoking the postprocessor again.
