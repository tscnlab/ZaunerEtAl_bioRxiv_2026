# Input checker class correction

The first pre-generation input check stopped at `identical()` because openssl
2.4.2 retains a `hash` class on its character representation. All four observed
manifest strings exactly matched their expected strings. The independent R
inspection printed those values and their class. The checker now strips that
class with `unclass()` before strict comparison. No expected identity, member,
size check or content test changed. No render or capture was attempted.

The initial source-normalisation check also retained an empty YAML line when
removing the newly added, authorized selection CSS key. The independent diff
of `selection_comparison_before.txt` and `selection_comparison_after.txt` shows
this single blank line and nothing else. The checker now removes the newline
with that exact metadata line. The initial result is retained separately.
No visible text, scientific token, caption or source-content test was waived.
