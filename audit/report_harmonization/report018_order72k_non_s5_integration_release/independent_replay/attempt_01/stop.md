# Independent review harness stop

The first temporary coordinator review reproduced H07 32/32, H09 41/41,
the combined 30/30 checks, and all source-authority pins. It then stopped
because its evidence extractor expected literal figure containers in the
selection QMD. That QMD uses heading/image/caption blocks for the selected
endpoints, while the manuscript supplement uses literal figure containers.
No author file changed. The corrected evidence extractor uses exact section
headings for the selection source and preserves the existing supplement
container extraction. Numbered-display counts are reconciled to the frozen
explicit SVG mapping, not counts of one source-markup representation.
