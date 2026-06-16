$tesseract = "$env:ProgramFiles\Tesseract-OCR\tesseract.exe"
$tessdata = "$env:LOCALAPPDATA\Tesseract-OCR\tessdata"
$outDir = "$env:TEMP\ocr_jobs"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$base = "D:\"

$subdirs = Get-ChildItem -LiteralPath $base -Directory | Where-Object { $_.Name -match "Книги" }

$results = @()
$jobList = @()

foreach ($bd in $subdirs) {
    $subs = Get-ChildItem -LiteralPath $bd.FullName -Directory
    foreach ($sub in $subs) {
        $subName = $sub.Name
        $subPath = $sub.FullName
        $files = Get-ChildItem -LiteralPath $subPath -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
        if ($files.Count -eq 0) { continue }
        
        $lots = @{}
        foreach ($file in $files) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $lotKey = $baseName -replace '_\d+$','' -replace '\(\d+\)$',''
            if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
            $lots[$lotKey] += $file
        }
        
        foreach ($lotKey in $lots.Keys) {
            $jobList += @{
                Folder = "$($bd.Name)\$subName"
                LotKey = $lotKey
                Files = $lots[$lotKey]
                Path = $subPath
            }
        }
    }
    
    # Also process root files of this книг folder
    $rootFiles = Get-ChildItem -LiteralPath $bd.FullName -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    if ($rootFiles.Count -gt 0) {
        $lots = @{}
        foreach ($file in $rootFiles) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $lotKey = $baseName -replace '_\d+$','' -replace '\(\d+\)$',''
            if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
            $lots[$lotKey] += $file
        }
        foreach ($lotKey in $lots.Keys) {
            $jobList += @{
                Folder = "$($bd.Name) (root)"
                LotKey = $lotKey
                Files = $lots[$lotKey]
                Path = $bd.FullName
            }
        }
    }
}

Write-Host "Total jobs: $($jobList.Count)" -ForegroundColor Yellow
$processed = 0

foreach ($job in $jobList) {
    $processed++
    $lotKey = $job.LotKey
    $folder = $job.Folder
    $files = $job.Files
    $fpath = $job.Path
    
    $candidates = $files | Where-Object { $_.BaseName -match '_\d+$' }
    if (-not $candidates) { $candidates = $files }
    $target = $candidates | Select-Object -First 1
    
    $outPath = Join-Path $outDir "ocr_$lotKey"
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
        $c = $l.Trim()
        if ($c.Length -gt 5) { $clean += $c }
    }
    
    $results += [PSCustomObject]@{
        N = $processed
        Folder = $folder
        Lot = $lotKey
        OCR_Summary = ($clean | Select-Object -First 5) -join " || "
    }
    
    if ($processed % 50 -eq 0) {
        Write-Host "Progress: $processed / $($jobList.Count)" -ForegroundColor Green
    }
}

$results | Export-Csv "C:\Users\user\Documents\pa-finance.2\books\ocr_results_full.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "Complete! Processed $processed lots." -ForegroundColor Green
