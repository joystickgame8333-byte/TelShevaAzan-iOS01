param(
    [int]$PageNumber = 293
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "TelShevaAzan\Resources\Quran\QCF"
$outputPath = Join-Path $outputDirectory "qcf-page-$PageNumber-v2.json"
$fontPath = Join-Path $outputDirectory "p$PageNumber.woff2"
$surahTitle = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String("2LPZj9mI2LHZjtip2Y8g2KfZhNmS2YPZjtmH2ZLZgdmQ")
)
$bismillah = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String("2KjZkNiz2ZLZhdmQINin2YTZhNmR2Y7Zh9mQINin2YTYsdmR2Y7YrdmS2YXZjtmw2YbZkCDYp9mE2LHZkdmO2K3ZkNmK2YXZkA==")
)

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$apiUrl = "https://api.quran.com/api/v4/verses/by_page/$PageNumber" +
    "?language=ar&words=true&word_fields=code_v2,text_qpc_hafs,line_number,page_number&per_page=50"
$response = Invoke-RestMethod -Uri $apiUrl

$tokensByLine = @{}
foreach ($verse in $response.verses) {
    foreach ($word in $verse.words) {
        $lineNumber = [int]$word.line_number
        if (-not $tokensByLine.ContainsKey($lineNumber)) {
            $tokensByLine[$lineNumber] = [System.Collections.Generic.List[object]]::new()
        }

        $tokensByLine[$lineNumber].Add([ordered]@{
            kind = $word.char_type_name
            qcf = $word.code_v2
            unicode = $word.text_qpc_hafs
        })
    }
}

$lines = [System.Collections.Generic.List[object]]::new()
for ($lineNumber = 1; $lineNumber -le 15; $lineNumber++) {
    if ($lineNumber -eq 10) {
        $lines.Add([ordered]@{
            number = $lineNumber
            kind = "surah"
            text = $surahTitle
            tokens = @()
        })
    }
    elseif ($lineNumber -eq 11) {
        $lines.Add([ordered]@{
            number = $lineNumber
            kind = "bismillah"
            text = $bismillah
            tokens = @()
        })
    }
    else {
        if (-not $tokensByLine.ContainsKey($lineNumber)) {
            throw "The Quran API did not return text for page $PageNumber line $lineNumber."
        }

        $lines.Add([ordered]@{
            number = $lineNumber
            kind = "text"
            text = ""
            tokens = @($tokensByLine[$lineNumber])
        })
    }
}

$payload = [ordered]@{
    schemaVersion = 1
    rendering = "qcf-v2"
    page = $PageNumber
    juz = [int]$response.verses[0].juz_number
    lines = @($lines)
}

$json = $payload | ConvertTo-Json -Depth 8 -Compress
[System.IO.File]::WriteAllText($outputPath, $json, [System.Text.UTF8Encoding]::new($false))

$fontUrl = "https://verses.quran.foundation/fonts/quran/hafs/v2/woff2/p$PageNumber.woff2"
Invoke-WebRequest -Uri $fontUrl -OutFile $fontPath

Write-Host "Generated QCF V2 prototype page $PageNumber"
Write-Host "  Data: $outputPath"
Write-Host "  Font: $fontPath"
