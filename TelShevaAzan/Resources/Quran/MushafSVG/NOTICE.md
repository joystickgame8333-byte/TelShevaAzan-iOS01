# Quran Mushaf SVG Resources - Source and License Notice

These 604 packaged pages were generated from **Quranpedia / quran-svg**, Hafs narration,
King Fahd Glorious Qur'an Printing Complex (KFQC) edition of Mushaf al-Madinah.

- Repository: https://github.com/quranpedia/quran-svg
- Pinned source commit: `5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2`
- Source directory: `mushafs/hafs/kfqc/svg`
- Upstream license: https://github.com/quranpedia/quran-svg/blob/5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2/LICENSE
- Upstream notice and publisher terms: https://github.com/quranpedia/quran-svg/blob/5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2/NOTICE.md

## Rights and permitted use

Quranpedia's original ayah-polygon overlay, JSON metadata, and repository tooling are
dedicated to the public domain under **CC0 1.0**. The underlying rendered Mushaf page
glyphs and calligraphy are not CC0; they remain subject to the KFQC terms reproduced in
the upstream notice. Those terms permit free digital publishing, websites, software,
media, institutional, governmental, personal, and business use. Physical printing or
importing Mushafs for commercial sale is restricted as described by KFQC.

The Qur'anic text must never be altered, truncated, or misrepresented and must be handled
with due respect.

## Packaging performed by this project

The generator validated each SVG as XML and removed only transparent, empty
`path.ayahPolygon` hit-regions. It did not rewrite the rendered Mushaf calligraphy.
Each remaining SVG was UTF-8 encoded, compressed as an RFC 1950 zlib stream, and prefixed
with a four-byte big-endian original byte length. See `manifest.json` for the pinned
source, per-page hashes and sizes, and generation totals.