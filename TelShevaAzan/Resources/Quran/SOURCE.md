# Quran reader sources

The full-screen reader and page preview render the 604 Hafs/KFQC Mushaf al-Madinah
pages from the open Quranpedia `quran-svg` project. The generator pins one audited
upstream commit, removes only transparent verse hit-regions, verifies every page,
and packages the unchanged visible vector artwork in a lossless compressed form.

- Source: https://github.com/quranpedia/quran-svg
- Generator: `tools/generate-quran-svg-pages.ps1`
- Validator: `tools/validate-quran-svg-pages.py`
- Packaged pages: `MushafSVG/p001.qsvg` through `MushafSVG/p604.qsvg`
- Detailed source, license and KFQC terms: `MushafSVG/NOTICE.md`

`quran-pages-v1.json` remains as the existing application index for page, juz and
surah navigation. It is not used to shape or draw Qur'anic text in the reader.
