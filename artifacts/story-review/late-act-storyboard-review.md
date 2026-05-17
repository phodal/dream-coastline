# Late Act Storyboard Review

Reviewed: 2026-05-18

Scope:

- `04-continuation-institute`
- `05-century-continuation`
- `06-return-star-plan`
- `07-lights-on-again`

Validation and playback:

- `python3 tools/run_automated_tests.py --only json-data,python-tools,story-review-panels,smoke-chapter-illustrations,smoke-story-review-mode`
- `python3 tools/record_story_review.py --scene <scene> --output artifacts/story-review/<scene>-storyboards`
- Contact sheets:
  - `artifacts/story-review/04-continuation-institute-storyboards/contact.png`
  - `artifacts/story-review/05-century-continuation-storyboards/contact.png`
  - `artifacts/story-review/06-return-star-plan-storyboards/contact.png`
  - `artifacts/story-review/07-lights-on-again-storyboards/contact.png`

## Pass

Fourth act now reads as an institution-building arc instead of plain text.
The generated panels cover the shared table, public school, workshop flow, mine
safety board, and Seal Character Tower crisis. The Seal Tower panel correctly
turns forgetting into pressure on students, dictionaries, and archives.

Fifth act communicates the century jump better than the old placeholder. The
night school, statebook anchor, astral tower, darkening modern star, and
star-chart moth all line up with the script's education, network, engineering,
and coordinate-risk beats.

Sixth act is mostly aligned. The council, dockyard, backup-chain core, return
gate, and silence probe now make the rescue mission look public, technical, and
cross-civilizational instead of a generic portal chapter.

Seventh act playback now completes all 43 story-review steps after increasing
the recording frame cap. The bottom subtitle layout remains readable and does
not cover the main visual focus.

## Differences To Fix

`07-lights-on-again/lights-continue.png` is too bright and polished compared
with the ink-paper late-act style. It communicates "lights return", but the
tone is closer to a modern scenic illustration than a restrained RPG storyboard.
Regenerate it with darker ink texture, visible Moqi classroom/workshop/archive
echoes, and less postcard color.

`07-lights-on-again/return-bridge-traveler.png` currently reuses the parents lab
bridge composition because the generated lab panel already contains the traveler
silhouette. The script wants a city-street bridge-traveler beat, so it should
get a dedicated street/lab hybrid panel.

`07-lights-on-again/final-silence-protocol.png` currently reuses the sixth-act
silence-probe composition. The script wants an orbital final protocol that
deletes party/interface names and is answered by the whole civilization. It
needs a dedicated final-battle/system panel.

The fourth-act first-members table composition is good, but it repeats several
times in playback because multiple commands resolve to the same review panel.
That is acceptable for the current hands-off review mode, but future polishing
could add command-level subpanels if the chapter feels slow.

## Script Alignment Summary

- Act 4: aligned; no major script gap.
- Act 5: aligned; no major script gap.
- Act 6: aligned; no major script gap.
- Act 7: structurally aligned in playback, but three visual beats still need
  more precise dedicated artwork before treating the ending as visually locked.
