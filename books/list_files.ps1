$folders = @(
    "D:\Книги\Детская энциклопедия"
    "D:\Книги\Искусство"
    "D:\Книги\Металлы и наука"
    "D:\Книги\Однотомники классической литературы"
    "D:\Книги\Писатели о писателях"
    "D:\Книги\Серия БВЛ"
    "D:\Книги\Серия ЖЗЛ"
    "D:\Книги\Серия История эстетики в памятниках и документах"
    "D:\Книги\Серия Мастера современной прозы"
    "D:\Книги\Снятые"
    "D:\Книги\"
)

$results = @()
$lotCount = 0

foreach ($folder in $folders) {
    $folderName = if ($folder -eq "D:\Книги\") {"Книги (корень)"} else {Split-Path $folder -Leaf}
    if (-not (Test-Path $folder)) { continue }
    
    $files = Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '\.(JPG|JPEG|PNG|jpg|jpeg|png)$' }
    $lots = @{}
    
    foreach ($file in $files) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $lotKey = $baseName -replace '_\d+$', '' -replace '\(\d+\)$', ''
        if (-not $lots.ContainsKey($lotKey)) { $lots[$lotKey] = @() }
        $lots[$lotKey] += $file.Name
    }
    
    foreach ($lotKey in ($lots.Keys | Sort-Object)) {
        $lotCount++
        $fileList = ($lots[$lotKey]) -join "<br>"
        $results += [PSCustomObject]@{
            N = $lotCount
            Folder = $folderName
            Lot = $lotKey
            Files = $fileList
        }
    }
}

$results | Export-Csv "C:\Users\user\Documents\pa-finance.2\books\file_listing.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "Total lots: $lotCount"