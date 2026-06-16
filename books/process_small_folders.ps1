$tesseract = "$env:ProgramFiles\Tesseract-OCR\tesseract.exe"
$tessdata = "$env:LOCALAPPDATA\Tesseract-OCR\tessdata"
$outDir = "$env:TEMP\ocr_out"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$smallFolders = @(
    "Детская энциклопедия"
    "Металлы и наука"
    "Однотомники классической литературы"
    "Писатели о писателях"
    "Серия БВЛ"
    "Серия ЖЗЛ"
    "Серия История эстетики в памятниках и документах"
    "Серия Мастера современной прозы"
    "Снятые"
)

$results = @()
$base = "D:\Книги"

foreach ($folderName in $smallFolders) {
    $folder = Join-Path $base $folderName
    if (-not (Test-Path $folder)) { continue }
    
    Write-Host "Processing: $folderName" -ForegroundColor Yellow
    $files = Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    
    $lots = @{}
    foreach ($file in $files) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $lotKey = $baseName -replace '_\d+$','' -replace '\(\d+\)$',''
        if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
        $lots[$lotKey] += $file
    }
    
    $jobScript = {
        param($tesseract, $tessdata, $files, $lotKey, $outDir)
        $bestText = ""
        $candidates = $files | Where-Object { $_.BaseName -match '_\d+$' }
        if (-not $candidates) { $candidates = $files }
        $target = $candidates | Select-Object -First 1
        
        $outPath = Join-Path $outDir "ocr_$lotKey"
        & $tesseract $target.FullName $outPath --tessdata-dir $tessdata -l rus --psm 6 2>&1 | Out-Null
        $txtPath = "$outPath.txt"
        if (Test-Path $txtPath) {
            $bestText = Get-Content $txtPath -Encoding UTF8 -Raw
            Remove-Item $txtPath -Force -ErrorAction SilentlyContinue
        }
        
        $lines = $bestText -split "`n" | Where-Object { $_.Trim().Length -gt 5 }
        $clean = @()
        foreach ($l in $lines) {
            $c = $l.Trim()
            if ($c.Length -gt 5) { $clean += $c }
        }
        
        return @{
            LotKey = $lotKey
            Text = ($clean -join ' || ')
            FileNames = ($files.Name -join '; ')
        }
    }
    
    $jobs = @()
    foreach ($lotKey in $lots.Keys) {
        $jobs += Start-Job -ScriptBlock $jobScript -ArgumentList $tesseract, $tessdata, $lots[$lotKey], $lotKey, $outDir
        if ($jobs.Count -ge 4) {
            $jobs | Wait-Job | Receive-Job | ForEach-Object {
                $results += [PSCustomObject]@{
                    Folder = $folderName
                    Lot = $_.LotKey
                    Files = $_.FileNames
                    OCR = $_.Text
                }
                if ($_.Text.Length -gt 5) { Write-Host "  $($_.LotKey): OK" } else { Write-Host "  $($_.LotKey): no text" }
            }
            $jobs = @()
        }
    }
    $jobs | Wait-Job | Receive-Job | ForEach-Object {
        $results += [PSCustomObject]@{
            Folder = $folderName
            Lot = $_.LotKey
            Files = $_.FileNames
            OCR = $_.Text
        }
    }
}

$results | Export-Csv "C:\Users\user\Documents\pa-finance.2\books\ocr_small.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "Done! $(@($results).Count) lots processed." -ForegroundColor Green
