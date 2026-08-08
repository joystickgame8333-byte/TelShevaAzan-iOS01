param(
    [string]$OutputDirectory = "TelShevaAzan/Resources/Quran/MushafSVG",
    [string]$SourceCommit = "5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2",
    [string]$DownloadCacheDirectory = "",
    [int]$RetryCount = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pageCount = 604
$repositoryURL = "https://github.com/quranpedia/quran-svg"
$sourceDirectory = "mushafs/hafs/kfqc/svg"
$sourceLicenseURL = "$repositoryURL/blob/$SourceCommit/LICENSE"
$sourceNoticeURL = "$repositoryURL/blob/$SourceCommit/NOTICE.md"
$rawRoot = "https://raw.githubusercontent.com/quranpedia/quran-svg/$SourceCommit/$sourceDirectory"
$auditedContentSetSha256 = "03a766c2b68d8fdd10dff49b6b4b1000ac911e54260dc0369cb4d835103978e3"
$repositoryRoot = Split-Path -Parent $PSScriptRoot

if ($SourceCommit -notmatch '^[0-9a-fA-F]{40}$') {
    throw "SourceCommit must be a full 40-character Git commit SHA."
}
if ($RetryCount -lt 1) {
    throw "RetryCount must be at least 1."
}

function Resolve-GeneratorPath([string]$Path, [string]$BasePath) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

$resolvedOutputDirectory = Resolve-GeneratorPath $OutputDirectory $repositoryRoot
if ([string]::IsNullOrWhiteSpace($DownloadCacheDirectory)) {
    $DownloadCacheDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "telsheva-quran-svg-$SourceCommit"
}
$resolvedCacheDirectory = Resolve-GeneratorPath $DownloadCacheDirectory $repositoryRoot

New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $resolvedCacheDirectory -Force | Out-Null

Add-Type -AssemblyName System.Net.Http
$httpHandler = New-Object System.Net.Http.HttpClientHandler
$httpHandler.AutomaticDecompression =
    [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
$httpClient = New-Object System.Net.Http.HttpClient($httpHandler)
$httpClient.Timeout = [TimeSpan]::FromSeconds(120)
$httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("TelShevaAzan-QuranSVG-Generator/1.0")

function Get-RemoteBytes([string]$Uri, [string]$CachePath) {
    if ((Test-Path -LiteralPath $CachePath) -and (Get-Item -LiteralPath $CachePath).Length -gt 1024) {
        return [System.IO.File]::ReadAllBytes($CachePath)
    }

    $temporaryPath = "$CachePath.download"
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        try {
            $bytes = $httpClient.GetByteArrayAsync($Uri).GetAwaiter().GetResult()
            if ($bytes.Length -le 1024) {
                throw "Downloaded SVG is unexpectedly small ($($bytes.Length) bytes)."
            }
            [System.IO.File]::WriteAllBytes($temporaryPath, $bytes)
            Move-Item -LiteralPath $temporaryPath -Destination $CachePath -Force
            return $bytes
        } catch {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
            if ($attempt -eq $RetryCount) {
                throw
            }
            Start-Sleep -Seconds ([Math]::Min($attempt * 2, 10))
        }
    }
}

function ConvertFrom-StrictUtf8([byte[]]$Bytes) {
    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    $text = $encoding.GetString($Bytes)
    if ($text.Length -gt 0 -and [int]$text[0] -eq 0xFEFF) {
        return $text.Substring(1)
    }
    return $text
}

function Read-SafeXml([string]$Text) {
    $settings = New-Object System.Xml.XmlReaderSettings
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null

    $stringReader = New-Object System.IO.StringReader($Text)
    $xmlReader = $null
    try {
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader, $settings)
        $document = New-Object System.Xml.XmlDocument
        $document.PreserveWhitespace = $true
        $document.XmlResolver = $null
        $document.Load($xmlReader)
        return $document
    } finally {
        if ($null -ne $xmlReader) { $xmlReader.Dispose() }
        $stringReader.Dispose()
    }
}

function Get-SvgMetadata([string]$SvgText) {
    $document = Read-SafeXml $SvgText
    if ($null -eq $document.DocumentElement -or $document.DocumentElement.LocalName -ne "svg") {
        throw "Downloaded document is not an SVG."
    }

    $viewBox = $document.DocumentElement.GetAttribute("viewBox")
    if ([string]::IsNullOrWhiteSpace($viewBox)) {
        throw "SVG has no viewBox."
    }

    $polygonNodes = @(
        $document.SelectNodes(
            "//*[contains(concat(' ', normalize-space(@class), ' '), ' ayahPolygon ')]"
        )
    )

    foreach ($node in $polygonNodes) {
        if ($node.LocalName -ne "path") {
            throw "ayahPolygon element is not a path."
        }
        foreach ($requiredAttribute in @("id", "number", "surah", "ayah", "d", "fill-opacity")) {
            if (-not $node.HasAttribute($requiredAttribute)) {
                throw "ayahPolygon is missing required attribute '$requiredAttribute'."
            }
        }

        $opacity = 0.0
        $parsed = [double]::TryParse(
            $node.GetAttribute("fill-opacity"),
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$opacity
        )
        if (-not $parsed -or $opacity -ne 0.0) {
            throw "Refusing to remove a non-transparent ayahPolygon."
        }
        if ($node.HasChildNodes) {
            throw "Refusing to remove a non-empty ayahPolygon element."
        }
    }

    return [ordered]@{
        document = $document
        viewBox = $viewBox
        polygonCount = $polygonNodes.Count
    }
}

function Remove-TransparentAyahPolygons([string]$SvgText) {
    $before = Get-SvgMetadata $SvgText
    $pathPattern = @'
(?is)<path\b(?=[^>]*\bclass\s*=\s*(?:"[^"]*\bayahPolygon\b[^"]*"|'[^']*\bayahPolygon\b[^']*'))[^>]*/>
'@.Trim()
    $matches = [System.Text.RegularExpressions.Regex]::Matches($SvgText, $pathPattern)

    if ($matches.Count -ne $before.polygonCount) {
        throw "Could not match every ayahPolygon without rewriting the SVG ($($matches.Count) of $($before.polygonCount))."
    }

    $removedCharacters = 0
    foreach ($match in $matches) {
        $removedCharacters += $match.Length
    }

    $cleanSvg = [System.Text.RegularExpressions.Regex]::Replace($SvgText, $pathPattern, "")
    if (($SvgText.Length - $cleanSvg.Length) -ne $removedCharacters) {
        throw "Unexpected SVG content change while removing ayahPolygon elements."
    }

    $after = Get-SvgMetadata $cleanSvg
    if ($after.polygonCount -ne 0) {
        throw "ayahPolygon elements remain after cleaning."
    }
    if ($after.viewBox -ne $before.viewBox) {
        throw "SVG viewBox changed while cleaning."
    }

    return [ordered]@{
        svg = $cleanSvg
        viewBox = $before.viewBox
        polygonsRemoved = $before.polygonCount
    }
}

function Get-Adler32([byte[]]$Bytes) {
    [uint64]$a = 1
    [uint64]$b = 0
    [uint64]$modulus = 65521

    foreach ($value in $Bytes) {
        $a = ($a + $value) % $modulus
        $b = ($b + $a) % $modulus
    }
    return [uint32](($b -shl 16) -bor $a)
}

function ConvertTo-BigEndianUInt32([uint32]$Value) {
    return [byte[]]@(
        [byte](($Value -shr 24) -band 0xFF),
        [byte](($Value -shr 16) -band 0xFF),
        [byte](($Value -shr 8) -band 0xFF),
        [byte]($Value -band 0xFF)
    )
}

function ConvertFrom-BigEndianUInt32([byte[]]$Bytes, [int]$Offset) {
    if ($Bytes.Length -lt ($Offset + 4)) {
        throw "Not enough bytes for a UInt32 value."
    }
    return [uint32](
        ([uint32]$Bytes[$Offset] -shl 24) -bor
        ([uint32]$Bytes[$Offset + 1] -shl 16) -bor
        ([uint32]$Bytes[$Offset + 2] -shl 8) -bor
        [uint32]$Bytes[$Offset + 3]
    )
}

function Compress-QuranSvg([byte[]]$SvgBytes) {
    if ([uint64]$SvgBytes.Length -gt [uint32]::MaxValue) {
        throw "SVG is too large for the qsvg length prefix."
    }

    $deflateBuffer = New-Object System.IO.MemoryStream
    try {
        $deflater = New-Object System.IO.Compression.DeflateStream(
            $deflateBuffer,
            [System.IO.Compression.CompressionLevel]::Optimal,
            $true
        )
        try {
            $deflater.Write($SvgBytes, 0, $SvgBytes.Length)
        } finally {
            $deflater.Dispose()
        }
        $deflated = $deflateBuffer.ToArray()
    } finally {
        $deflateBuffer.Dispose()
    }

    $output = New-Object System.IO.MemoryStream
    try {
        $lengthPrefix = ConvertTo-BigEndianUInt32 ([uint32]$SvgBytes.Length)
        $output.Write($lengthPrefix, 0, $lengthPrefix.Length)

        # RFC 1950 zlib header: deflate, 32 KiB window, maximum compression.
        [byte[]]$zlibHeader = @(0x78, 0xDA)
        $output.Write($zlibHeader, 0, $zlibHeader.Length)
        $output.Write($deflated, 0, $deflated.Length)

        $checksum = ConvertTo-BigEndianUInt32 (Get-Adler32 $SvgBytes)
        $output.Write($checksum, 0, $checksum.Length)
        return $output.ToArray()
    } finally {
        $output.Dispose()
    }
}

function Expand-QuranSvg([byte[]]$QsvgBytes) {
    if ($QsvgBytes.Length -lt 11) {
        throw "qsvg payload is too small."
    }

    $expectedLength = ConvertFrom-BigEndianUInt32 $QsvgBytes 0
    $cmf = [int]$QsvgBytes[4]
    $flg = [int]$QsvgBytes[5]
    if (($cmf -band 0x0F) -ne 8 -or (($cmf * 256 + $flg) % 31) -ne 0 -or ($flg -band 0x20) -ne 0) {
        throw "Invalid or unsupported zlib header."
    }

    $deflateLength = $QsvgBytes.Length - 10
    $input = New-Object System.IO.MemoryStream(,$QsvgBytes)
    $output = New-Object System.IO.MemoryStream
    try {
        $input.Position = 6
        $boundedInput = New-Object System.IO.MemoryStream
        try {
            $boundedInput.Write($QsvgBytes, 6, $deflateLength)
            $boundedInput.Position = 0
            $inflater = New-Object System.IO.Compression.DeflateStream(
                $boundedInput,
                [System.IO.Compression.CompressionMode]::Decompress,
                $true
            )
            try {
                $inflater.CopyTo($output)
            } finally {
                $inflater.Dispose()
            }
        } finally {
            $boundedInput.Dispose()
        }
        $expanded = $output.ToArray()
    } finally {
        $input.Dispose()
        $output.Dispose()
    }

    if ([uint32]$expanded.Length -ne $expectedLength) {
        throw "qsvg length prefix mismatch: expected $expectedLength, got $($expanded.Length)."
    }
    $expectedChecksum = ConvertFrom-BigEndianUInt32 $QsvgBytes ($QsvgBytes.Length - 4)
    $actualChecksum = Get-Adler32 $expanded
    if ($actualChecksum -ne $expectedChecksum) {
        throw "qsvg Adler-32 checksum mismatch."
    }
    return $expanded
}

function Get-Sha256Hex([byte[]]$Bytes) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha256.ComputeHash($Bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

function Test-EqualBytes([byte[]]$Left, [byte[]]$Right) {
    if ($Left.Length -ne $Right.Length) { return $false }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) { return $false }
    }
    return $true
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$pageEntries = New-Object System.Collections.ArrayList
[uint64]$totalSourceBytes = 0
[uint64]$totalSvgBytes = 0
[uint64]$totalQsvgBytes = 0
[uint64]$totalPolygonsRemoved = 0
$contentSetHasher = [System.Security.Cryptography.IncrementalHash]::CreateHash(
    [System.Security.Cryptography.HashAlgorithmName]::SHA256
)

try {
    foreach ($page in 1..$pageCount) {
        $pageStem = $page.ToString("000", [System.Globalization.CultureInfo]::InvariantCulture)
        $sourceFile = "$pageStem.svg"
        $sourceURL = "$rawRoot/$sourceFile"
        $cachePath = Join-Path $resolvedCacheDirectory $sourceFile

        if ($page -eq 1 -or $page % 25 -eq 0 -or $page -eq $pageCount) {
            Write-Host "Generating Quran SVG page $page of $pageCount..."
        }

        $sourceBytes = Get-RemoteBytes $sourceURL $cachePath
        $sourceText = ConvertFrom-StrictUtf8 $sourceBytes
        $cleaned = Remove-TransparentAyahPolygons $sourceText
        $svgBytes = $utf8NoBom.GetBytes([string]$cleaned.svg)
        $qsvgBytes = Compress-QuranSvg $svgBytes
        $contentSetHasher.AppendData((ConvertTo-BigEndianUInt32 ([uint32]$svgBytes.Length)))
        $contentSetHasher.AppendData($svgBytes)

        $expanded = Expand-QuranSvg $qsvgBytes
        if (-not (Test-EqualBytes $svgBytes $expanded)) {
            throw "qsvg round-trip verification failed for page $page."
        }

        $outputFile = "p$pageStem.qsvg"
        $outputPath = Join-Path $resolvedOutputDirectory $outputFile
        $temporaryOutputPath = "$outputPath.tmp"
        [System.IO.File]::WriteAllBytes($temporaryOutputPath, $qsvgBytes)
        Move-Item -LiteralPath $temporaryOutputPath -Destination $outputPath -Force

        $totalSourceBytes += [uint64]$sourceBytes.Length
        $totalSvgBytes += [uint64]$svgBytes.Length
        $totalQsvgBytes += [uint64]$qsvgBytes.Length
        $totalPolygonsRemoved += [uint64]$cleaned.polygonsRemoved

        [void]$pageEntries.Add([ordered]@{
            number = $page
            file = $outputFile
            sourceFile = "$sourceDirectory/$sourceFile"
            viewBox = [string]$cleaned.viewBox
            ayahPolygonsRemoved = [int]$cleaned.polygonsRemoved
            sourceBytes = $sourceBytes.Length
            svgBytes = $svgBytes.Length
            qsvgBytes = $qsvgBytes.Length
            svgSha256 = Get-Sha256Hex $svgBytes
            qsvgSha256 = Get-Sha256Hex $qsvgBytes
        })
    }
} finally {
    $httpClient.Dispose()
    $httpHandler.Dispose()
}

$contentSetSha256 = ([System.BitConverter]::ToString($contentSetHasher.GetHashAndReset())).Replace("-", "").ToLowerInvariant()
$contentSetHasher.Dispose()
if ($contentSetSha256 -ne $auditedContentSetSha256) {
    throw "Generated Mushaf content does not match the audited 604-page source set."
}

$expectedNames = @(
    1..$pageCount | ForEach-Object { "p$($_.ToString('000')).qsvg" }
)
$generatedFiles = @(
    Get-ChildItem -LiteralPath $resolvedOutputDirectory -File -Filter "p*.qsvg" |
        Where-Object { $_.Name -match '^p\d{3}\.qsvg$' } |
        Sort-Object Name
)
if ($generatedFiles.Count -ne $pageCount) {
    throw "Expected exactly $pageCount qsvg files; found $($generatedFiles.Count)."
}
$actualNames = @($generatedFiles | ForEach-Object { $_.Name })
$nameDifferences = @(Compare-Object -ReferenceObject $expectedNames -DifferenceObject $actualNames)
if ($nameDifferences.Count -ne 0) {
    throw "Generated qsvg page names are incomplete or unexpected."
}

$manifest = [ordered]@{
    schemaVersion = 1
    format = "qsvg-zlib"
    lengthPrefix = "uint32-big-endian-original-svg-byte-count"
    source = [ordered]@{
        name = "Quranpedia quran-svg - Hafs/KFQC Mushaf al-Madinah"
        repository = $repositoryURL
        commit = $SourceCommit
        directory = $sourceDirectory
        license = "Quranpedia ayah polygon metadata: CC0 1.0; underlying KFQC Mushaf calligraphy: KFQC digital-use terms"
        licenseURL = $sourceLicenseURL
        noticeURL = $sourceNoticeURL
    }
    processing = [ordered]@{
        ayahPolygonPolicy = "Removed only after XML validation confirmed every matched element was a transparent, empty path with the expected Quranpedia metadata attributes"
        compression = "RFC 1950 zlib containing RFC 1951 deflate at optimal compression"
        verification = "Every qsvg was decompressed and compared byte-for-byte with its cleaned SVG"
    }
    totals = [ordered]@{
        pageCount = $pageEntries.Count
        ayahPolygonsRemoved = $totalPolygonsRemoved
        sourceBytes = $totalSourceBytes
        svgBytes = $totalSvgBytes
        qsvgBytes = $totalQsvgBytes
    }
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    pages = $pageEntries.ToArray()
}

$manifestPath = Join-Path $resolvedOutputDirectory "manifest.json"
$serializerAssembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
if ($null -eq $serializerAssembly) {
    throw "System.Web.Extensions is required to write the Mushaf manifest."
}
$serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$serializer.MaxJsonLength = [int]::MaxValue
$serializer.RecursionLimit = 16
$manifestJson = $serializer.Serialize($manifest)
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8NoBom)

$notice = @"
# Quran Mushaf SVG Resources - Source and License Notice

These 604 packaged pages were generated from **Quranpedia / quran-svg**, Hafs narration,
King Fahd Glorious Qur'an Printing Complex (KFQC) edition of Mushaf al-Madinah.

- Repository: $repositoryURL
- Pinned source commit: ``$SourceCommit``
- Source directory: ``$sourceDirectory``
- Upstream license: $sourceLicenseURL
- Upstream notice and publisher terms: $sourceNoticeURL

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
``path.ayahPolygon`` hit-regions. It did not rewrite the rendered Mushaf calligraphy.
Each remaining SVG was UTF-8 encoded, compressed as an RFC 1950 zlib stream, and prefixed
with a four-byte big-endian original byte length. See ``manifest.json`` for the pinned
source, per-page hashes and sizes, and generation totals.
"@
$noticePath = Join-Path $resolvedOutputDirectory "NOTICE.md"
[System.IO.File]::WriteAllText($noticePath, $notice.TrimStart(), $utf8NoBom)

$compressionRatio = if ($totalSvgBytes -eq 0) { 0 } else { $totalQsvgBytes / [double]$totalSvgBytes }
Write-Host "Generated and verified Quran SVG resources:"
Write-Host "  pages: $($pageEntries.Count)"
Write-Host "  transparent ayah polygons removed: $totalPolygonsRemoved"
Write-Host "  cleaned SVG bytes: $totalSvgBytes"
Write-Host "  qsvg bytes: $totalQsvgBytes"
Write-Host "  compression ratio: $($compressionRatio.ToString('P2'))"
Write-Host "  output: $resolvedOutputDirectory"
