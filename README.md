# harfbuzz

Standalone Haskell bindings for a small vendored HarfBuzz build.

This package vendors the upstream HarfBuzz source release and builds it
directly through Cabal instead of relying on a system HarfBuzz installation.

The initial scope is intentionally small:

- buffer creation and UTF-8 input
- direction, script, and language configuration
- shaping
- glyph info and position extraction
- FreeType integration through `hb-ft`
