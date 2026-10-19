# Settings and pause music

`settings_music.ogg`: **Elven Dawn** (loop version), by **alkakrab**.
Source: https://alkakrab.itch.io/free-fantasy-medieval-ambient-music-pack
Exact source member: `Loops/ogg/10. Elven Dawn.ogg`, upload 14501884,
`10 Medieval Tracks Music pack.zip`. The OGG bytes are unmodified.

The author's pack page states: **“Absolutely Free For Commercial use”**.
This is the author's explicit game-use permission, not a claim of CC0 or an
invented SPDX license. Credit is retained here and in THIRD_PARTY_NOTICES.md.
The game distributes only the necessary track, not the source pack.

Selection compared this medieval fantasy pack with petrichord's Ambient Music
Loops pack. The latter declares CC BY-ND 4.0 with narrower jam-use guidance;
it was not adopted. The local pool returned no eligible music result.

The registered itch.io downloader failed to resolve this pack. No registered
materialization target was supplied. The policy's direct-acquisition fallback
was used: read the public pack page, resolve its free upload, inspect its ZIP
central directory with bounded HTTP ranges, and extract only the exact loop.
The full archive exceeded the bounded download limit and was not retained.
ZIP member name, OGG signature, uncompressed length and CRC were checked.
This source provenance is not a Host materialization receipt. Native import,
audible comparison and product mix acceptance still require Host/Tester.

Existing effects remain the licensed Kenney sounds under assets/dialogue and
assets/training; their original licenses and acquisition receipts are retained.

## Veyne creature voice and elemental skills

The Veyne pack uses CC0 recordings by Darsycho (Monster snarls and Big scary troll sounds) and AntumDeluge (Fire Crackling), edited and layered with original procedural electric, wind and stone effects. Exact URLs, source checksums, generated-clip checksums and processing are in `veyne/SOURCE.json`; author credits and CC0 terms are in `veyne/LICENSES.md`.

## World and sword effects (2026-10-19)
Original deterministic DSP in world_effects/: portal_hum, chapter_farewell, chapter_passage, sword_whirl. CC0-1.0. Rebuild and hashes: tools/build_world_audio.py, world_effects/SOURCE.json.
