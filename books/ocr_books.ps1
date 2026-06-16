$tesseract = "$env:ProgramFiles\Tesseract-OCR\tesseract.exe"
$tessdata = "$env:LOCALAPPDATA\Tesseract-OCR\tessdata"
$resultsFile = "C:\Users\user\Documents\pa-finance.2\books\ocr_results.json"

$folders = @(
    "D:\Книги\Детская энциклопедия",
    "D:\Книги\Искусство",
    "D:\Книги\Металлы и наука",
    "D:\Книги\Однотомники классической литературы",
    "D:\Книги\Писатели о писателях",
    "D:\Книги\Продано2",
    "D:\Книги\Серия БВЛ",
    "D:\Книги\Серия ЖЗЛ",
    "D:\Книги\Серия История эстетики в памятниках и документах",
    "D:\Книги\Серия Матера современной прозы",
    "D:\Книги\Снятые",
    "D:\Книги"
)

$results = @{}

foreach ($folder in $folders) {
    $folderName = Split-Path $folder -Leaf
    Write-Host "`n=== $folderName ===" -ForegroundColor Green
    
    if (-not (Test-Path $folder)) { continue }
    
    $files = Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    $lots = @{}
    
    foreach ($file in $files) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $lotKey = $baseName -replace '_\d+$', '' -replace '\(\d+\)$', ''
        if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
        $lots[$lotKey] += $file.Name
    }
    
    $lotCount = 0
    foreach ($lotKey in ($lots.Keys | Sort-Object)) {
        $lotCount++
        $bestText = ""
        $ocrDir = "$env:TEMP\ocr_$lotCount"
        
        foreach ($fname in $lots[$lotKey]) {
            $fpath = Join-Path $folder $fname
            $outPath = "$env:TEMP\ocr_out.txt"
            & $tesseract $fpath $outPath --tessdata-dir $tessdata -l rus --psm 6 2>$null
            if (Test-Path "$outPath.txt") {
                $text = Get-Content "$outPath.txt" -Encoding UTF8 -Raw
                Remove-Item "$outPath.txt" -Force -ErrorAction SilentlyContinue
                if ($text.Length -gt $bestText.Length) { $bestText = $text }
            }
        }
        
        $lines = ($bestText -split "`n") | Where-Object { $_.Trim().Length -gt 5 }
        $clean = @()
        foreach ($line in $lines) {
            $c = $line.Trim() -replace '[^\w\s\.,:;!?«»()\-\–\']', ' '
            $c = ($c -replace '\s+', ' ').Trim()
            if ($c.Length -gt 10) { $clean += $c }
        }
        
        $series = if ($folderName -eq 'Книги') { "" } else { $folderName }
        
        $results[$lotKey] = @{
            series = $series
            folder = $folder
            files = $lots[$lotKey]
            best_lines = $clean | Select-Object -First 15
        }
        
        if ($clean.Count -gt 0) {
            Write-Host "  $lotKey : $($clean[0])"
        } else {
            Write-Host "  $lotKey : (no readable text)"
        }
    }
}

$results | ConvertTo-Json -Depth 3 | Set-Content $resultsFile -Encoding UTF8
Write-Host "`nResults saved to $resultsFile" -ForegroundColor Green
