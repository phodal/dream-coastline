# Story Movie Review

`tools/build_story_movie.py` builds a hands-off review movie from story scene
JSON, story-review illustrations, subtitles, and generated audio. The rendered
movie is intentionally ignored by Git because full review exports are large and
should be reproducible from tracked data and assets.

## Dependencies

Run this before rendering on a new machine:

```sh
python3 tools/build_story_movie.py --check-deps
```

Required tools:

- `ffmpeg`
- `ffprobe`
- `pango-view`

The script checks `PATH` first and then the Homebrew defaults under
`/opt/homebrew/bin/`. The check prints the resolved path and version for each
tool so review failures can be tied to the local rendering stack.

## Smoke Test

The automated test suite includes a small reproducibility gate:

```sh
python3 tools/run_automated_tests.py --only story-movie-smoke
```

That renders only `00-prologue-lights-out` at low resolution into the ignored
`artifacts/story-movie/` directory. It catches missing external tools, broken
subtitle rendering, invalid story/movie inputs, and ffmpeg muxing failures
without committing large media files.

## Full Review Export

```sh
python3 tools/build_story_movie.py \
  --output artifacts/story-movie/dream-coastline-story-movie.mp4
```

The adjacent JSON manifest records scene ids, card count, duration, image paths,
music, SFX, and voice samples used for the render. Regenerate the movie after
changing story scenes, chapter illustrations, generated audio, or subtitle
timing rules.
