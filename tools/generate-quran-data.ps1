param(
    [string]$OutputPath = "TelShevaAzan/Resources/Quran/quran-pages-v1.json"
)

$ErrorActionPreference = "Stop"
$apiRoot = "https://api.quran.com/api/v4"
$sourceURL = "https://api-docs.quran.com/docs/category/quran.com-api"

function Get-ApiJson([string]$Uri) {
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            return Invoke-RestMethod -Uri $Uri -TimeoutSec 60
        } catch {
            if ($attempt -eq 4) { throw }
            Start-Sleep -Seconds $attempt
        }
    }
}

$chapterResponse = Get-ApiJson "$apiRoot/chapters?language=ar"
$chapters = @($chapterResponse.chapters)
$pageLines = @{}
$pageJuz = @{}
$verseEndingCount = 0

function Add-PageToken([int]$Page, [int]$Line, [string]$Token) {
    $key = "$Page`:$Line"
    if (-not $pageLines.ContainsKey($key)) {
        $pageLines[$key] = [System.Collections.Generic.List[string]]::new()
    }
    $pageLines[$key].Add($Token)
}

foreach ($juz in 1..30) {
    Write-Host "Downloading juz $juz of 30..."
    $uri = "$apiRoot/verses/by_juz/$juz`?language=ar&words=true&word_fields=text_qpc_hafs,line_number,page_number&per_page=1000"
    $response = Get-ApiJson $uri

    foreach ($verse in @($response.verses)) {
        foreach ($word in @($verse.words)) {
            $page = [int]$word.page_number
            $line = [int]$word.line_number
            if (-not $pageJuz.ContainsKey($page)) {
                $pageJuz[$page] = [int]$verse.juz_number
            }

            if ($word.char_type_name -eq "word") {
                Add-PageToken $page $line ([string]$word.text_qpc_hafs)
            } elseif ($word.char_type_name -eq "end") {
                # The QPC Hafs font draws the verse number itself inside its ornamental seal.
                Add-PageToken $page $line ([string]$word.text_qpc_hafs)
                $verseEndingCount++
            }
        }
    }
}

$surahStarts = @{}
foreach ($chapter in $chapters) {
    $surahID = [int]$chapter.id
    $firstVerse = Get-ApiJson "$apiRoot/verses/by_key/$surahID`:1?language=ar&words=true&word_fields=text_qpc_hafs,line_number,page_number"
    $firstWord = @($firstVerse.verse.words | Where-Object { $_.char_type_name -eq "word" })[0]
    $firstLine = [int]$firstWord.line_number
    $page = [int]$firstWord.page_number
    $headerLine = if ($firstLine -ge 3 -and $surahID -ne 1 -and $surahID -ne 9) {
        $firstLine - 2
    } else {
        $firstLine - 1
    }

    # A handful of Madani pages begin directly with verse text. Keep that text intact;
    # the reader header still shows the active surah name for those pages.
    if ($headerLine -lt 1) { continue }

    $surahStarts["$page`:$headerLine"] = [pscustomobject]@{
        kind = "surah"
        text = "سُورَةُ $($chapter.name_arabic)"
    }

    if ($firstLine -ge 3 -and $surahID -ne 1 -and $surahID -ne 9) {
        $surahStarts["$page`:$($headerLine + 1)"] = [pscustomobject]@{
            kind = "bismillah"
            text = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
        }
    }
}

$pages = [System.Collections.Generic.List[object]]::new()
foreach ($page in 1..604) {
    $lines = [System.Collections.Generic.List[object]]::new()
    foreach ($line in 1..15) {
        $key = "$page`:$line"
        if ($surahStarts.ContainsKey($key)) {
            $entry = $surahStarts[$key]
            $lines.Add([ordered]@{ number = $line; kind = $entry.kind; text = $entry.text })
        } elseif ($pageLines.ContainsKey($key)) {
            $lines.Add([ordered]@{ number = $line; kind = "text"; text = ($pageLines[$key] -join " ") })
        }
    }

    if ($lines.Count -eq 0) {
        throw "Quran page $page has no content"
    }

    $surahIDs = @(
        $chapters |
            Where-Object { [int]$_.pages[0] -le $page -and [int]$_.pages[1] -ge $page } |
            ForEach-Object { [int]$_.id }
    )

    $pages.Add([ordered]@{
        number = $page
        juz = [int]$pageJuz[$page]
        surahIDs = $surahIDs
        lines = $lines
    })
}

if ($chapters.Count -ne 114) { throw "Expected 114 surahs, found $($chapters.Count)" }
if ($verseEndingCount -ne 6236) { throw "Expected 6236 verse endings, found $verseEndingCount" }
if ($pages.Count -ne 604) { throw "Expected 604 pages, found $($pages.Count)" }

$surahs = @($chapters | ForEach-Object {
    [ordered]@{
        id = [int]$_.id
        name = [string]$_.name_arabic
        verses = [int]$_.verses_count
        startPage = [int]$_.pages[0]
        endPage = [int]$_.pages[1]
        revelationPlace = [string]$_.revelation_place
    }
})

$payload = [ordered]@{
    schemaVersion = 1
    sourceName = "Quran Foundation - QPC Hafs text"
    sourceURL = $sourceURL
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    pages = $pages
    surahs = $surahs
}

$resolvedOutput = Join-Path (Get-Location) $OutputPath
$outputDirectory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$json = $payload | ConvertTo-Json -Depth 8 -Compress
$utf8WithoutBOM = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($resolvedOutput, $json, $utf8WithoutBOM)

Write-Host "Wrote $($pages.Count) pages, $($surahs.Count) surahs, and $verseEndingCount verses to $resolvedOutput"
