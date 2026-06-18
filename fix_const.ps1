# fix_const_v3.ps1 
# Final sweep: Remove 'const' before SizedBox, Container, Center, Padding, etc.
# that contain non-const children (AppColors-using widgets).
# Strategy: in files with AppColors, const SizedBox(child: X) where X has AppColors can't be const.
# Simplest: Remove const from SizedBox that immediately contains a CircularProgressIndicator child.

$pattern = 'const (SizedBox\()'

$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | 
    Where-Object { (Get-Content $_.FullName -Raw) -match "AppColors\." } |
    ForEach-Object { $_.FullName }

$totalFixed = 0

foreach ($file in $files) {
    $content = Get-Content $file -Raw -Encoding UTF8
    $newContent = [regex]::Replace($content, $pattern, '$1')
    
    if ($newContent -ne $content) {
        Set-Content -Path $file -Value $newContent -Encoding UTF8 -NoNewline
        $totalFixed++
        Write-Host "Fixed: $(Split-Path $file -Leaf)"
    }
}

Write-Host "`nDone. Modified $totalFixed files."
