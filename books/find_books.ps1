$dRoot = [System.IO.Directory]::GetDirectories('D:\')
$found = @()
foreach ($dir in $dRoot) {
    $name = [System.IO.Path]::GetFileName($dir)
    # Check byte pattern for 'К' (U+041A = 0x1A 0x04 in Unicode)
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($name)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0x1A -and $bytes[1] -eq 0x04) {
        $found += $dir
        $nameUtf = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Convert([System.Text.Encoding]::Unicode, [System.Text.Encoding]::UTF8, $bytes))
        Write-Host "Found: $dir (name: $nameUtf)"
    }
}
Write-Host "Total matching dirs: $($found.Count)"
