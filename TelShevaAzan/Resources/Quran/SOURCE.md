# Quran text source

- Text: QPC Hafs text distributed through the Quran Foundation API.
- API documentation: https://api-docs.quran.com/docs/category/quran.com-api
- Reading font: KFGQPC Hafs Uthmanic Script, distributed through the Quran Foundation font CDN.
- Font rendering guide: https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/
- Page and line metadata: Madani Mushaf page layout exposed by the same API.
- Generator: `tools/generate-quran-data.ps1`

The generated application resource is `quran-pages-v1.json`. It contains text and structural metadata only; no recitation audio is bundled.
