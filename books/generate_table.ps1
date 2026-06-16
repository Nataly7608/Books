$tesseract = "$env:ProgramFiles\Tesseract-OCR\tesseract.exe"
$tessdata = "$env:LOCALAPPDATA\Tesseract-OCR\tessdata"
$outDir = "$env:TEMP\ocr_batch"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$folders = @(
    @{Path="D:\Книги\Детская энциклопедия"; Series="Детская энциклопедия"}
    @{Path="D:\Книги\Искусство"; Series="Искусство"}
    @{Path="D:\Книги\Металлы и наука"; Series="Металлы и наука"}
    @{Path="D:\Книги\Однотомники классической литературы"; Series="Однотомники классической литературы"}
    @{Path="D:\Книги\Писатели о писателях"; Series="Писатели о писателях"}
    @{Path="D:\Книги\Серия БВЛ"; Series="Серия БВЛ"}
    @{Path="D:\Книги\Серия ЖЗЛ"; Series="Серия ЖЗЛ"}
    @{Path="D:\Книги\Серия История эстетики в памятниках и документах"; Series="Серия: История эстетики"}
    @{Path="D:\Книги\Серия Матера современной прозы"; Series="Серия: Мастера современной прозы"}
    @{Path="D:\Книги\Снятые"; Series="Снятые"}
)

$allResults = @()

foreach ($f in $folders) {
    $folder = $f.Path
    $series = $f.Series
    $folderName = Split-Path $folder -Leaf
    
    if (-not (Test-Path $folder)) { continue }
    Write-Host "Processing $folderName..." -ForegroundColor Yellow
    
    $files = Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    $lots = @{}
    
    foreach ($file in $files) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $lotKey = $baseName -replace '_\d+$', '' -replace '\(\d+\)$', ''
        if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
        $lots[$lotKey] += $file
    }
    
    $count = 0
    foreach ($lotKey in ($lots.Keys | Sort-Object)) {
        $count++
        
        # Try OCR on first and _1 photos
        $bestText = ""
        $candidateFiles = $lots[$lotKey] | Where-Object { $_.BaseName -match '_\d+$' -or $lots[$lotKey].Count -eq 1 }
        if (-not $candidateFiles) { $candidateFiles = $lots[$lotKey] }
        $targetFile = $candidateFiles | Select-Object -First 1
        
        if ($targetFile) {
            $outPath = Join-Path $outDir "ocr_$lotCount"
            & $tesseract $targetFile.FullName $outPath --tessdata-dir $tessdata -l rus --psm 6 2>$null
            $txtPath = "$outPath.txt"
            if (Test-Path $txtPath) {
                $bestText = Get-Content $txtPath -Encoding UTF8 -Raw
                Remove-Item $txtPath -Force -ErrorAction SilentlyContinue
            }
        }
        
        $lines = $bestText -split "`n" | Where-Object { $_.Trim().Length -gt 8 }
        $clean = @()
        foreach ($line in $lines) {
            $c = $line.Trim()
            if ($c.Length -gt 8) { $clean += $c }
        }
        
        $fileList = ($lots[$lotKey].Name) -join ", "
        
        $allResults += [PSCustomObject]@{
            Folder = $folderName
            Series = $series
            Lot = $lotKey
            Files = $fileList
            OCR_Text = ($clean -join " | ")
        }
        
        if ($clean.Count -gt 0) {
            Write-Host "  $lotKey : $($clean[0].Substring(0, [Math]::Min(80, $clean[0].Length)))"
        }
    }
}

$allResults | Export-Csv "C:\Users\user\Documents\pa-finance.2\books\ocr_results.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "Done! Results saved to ocr_results.csv" -ForegroundColor Green
