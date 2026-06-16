$tesseract = "$env:ProgramFiles\Tesseract-OCR\tesseract.exe"
$tessdata = "$env:LOCALAPPDATA\Tesseract-OCR\tessdata"
$outDir = "$env:TEMP\ocr_jobs"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$base = "D:\"
$bookDir = Get-ChildItem -LiteralPath $base -Directory | Where-Object { $_.Name -match "Книги" } | Select-Object -First 1
if (-not $bookDir) { Write-Host "Books dir not found"; exit }

$allItems = @()
$subs = Get-ChildItem -LiteralPath $bookDir.FullName -Directory

foreach ($sub in $subs) {
    $folder = $sub.FullName
    $folderLabel = $sub.Name
    $files = Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    if ($files.Count -eq 0) { continue }
    
    $lots = @{}
    foreach ($file in $files) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $lotKey = $baseName -replace '_\d+$','' -replace '\(\d+\)$',''
        if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
        $lots[$lotKey] += $file
    }
    
    $i = 0
    foreach ($lotKey in ($lots.Keys | Sort-Object)) {
        $i++
        $filesOfLot = $lots[$lotKey]
        $candidates = $filesOfLot | Where-Object { $_.BaseName -match '_\d+$' }
        if (-not $candidates) { $candidates = $filesOfLot }
        $target = $candidates | Select-Object -First 1
        
        $outPath = Join-Path $outDir "ocr"
        & $tesseract $target.FullName $outPath --tessdata-dir $tessdata -l rus --psm 6 2>&1 | Out-Null
        $txtPath = "$outPath.txt"
        
        $bestText = ""
        if (Test-Path $txtPath) {
            $bestText = Get-Content $txtPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
            Remove-Item $txtPath -Force -ErrorAction SilentlyContinue
        }
        
        $lines = $bestText -split "`n" | Where-Object { $_.Trim().Length -gt 5 }
        $clean = @()
        foreach ($l in $lines) {
            $c = ($l.Trim() -replace '[^\w\s\.\,\:\;\!\?\(\)\-\–\«\»]',' ').Trim()
            $c = ($c -replace '\s+',' ').Trim()
            if ($c.Length -gt 10) { $clean += $c }
        }
        
        $ocrSummary = if ($clean.Count -gt 0) { $clean[0..[Math]::Min(2,$clean.Count-1)] -join " | " } else { "" }
        
        $fnames = ($filesOfLot.Name) -join "; "
        $allItems += [PSCustomObject]@{
            Folder = $folderLabel
            Lot = $lotKey
            Files = $fnames
            OCR = $ocrSummary
        }
        
        Write-Host "$($folderLabel): $lotKey"
    }
}

$allItems | Export-Csv "C:\Users\user\Documents\pa-finance.2\books\ocr_subdirs.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "Done. $($allItems.Count) lots."