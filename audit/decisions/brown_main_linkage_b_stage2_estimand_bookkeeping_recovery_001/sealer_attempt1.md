# Central seal parser stop

The first central sealer stopped before copying any replay/code file or writing
the dispatch manifest. Python's infrastructure test CSV serializes booleans as
`True`; base R imported that column as character, so `all(s$pass)` raised the
expected character-to-logical warning under warn=2. The unsealed central sealer
was corrected only to require all 19 exact `True` strings. No prospective code,
independent result, owner file, scientific job or dispatch changed. Error:
`Error in all(s$pass): (converted from warning) coercing argument of type 'character' to logical`.
