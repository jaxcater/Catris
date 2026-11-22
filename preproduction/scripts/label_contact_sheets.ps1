param([string]$ReferenceDirectory = (Join-Path $PSScriptRoot '..\references'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$catrisReferenceRoot = (Resolve-Path -LiteralPath $ReferenceDirectory).Path
$catrisMeta = Get-Content -LiteralPath (Join-Path $catrisReferenceRoot 'video-metadata.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$catrisFont = New-Object System.Drawing.Font('Arial', 15)
try {
    foreach ($catrisGroup in ($catrisMeta.frames | Group-Object group)) {
        $catrisRows = [int][Math]::Ceiling($catrisGroup.Count / 4.0)
        $catrisBitmap = New-Object System.Drawing.Bitmap(1940, (304 * $catrisRows + 4))
        $catrisGraphics = [System.Drawing.Graphics]::FromImage($catrisBitmap)
        try {
            $catrisGraphics.Clear([System.Drawing.Color]::FromArgb(23,27,28))
            $catrisIndex = 0
            foreach ($catrisFrame in $catrisGroup.Group) {
                $catrisX = 4 + ($catrisIndex % 4) * 484
                $catrisY = 4 + [int][Math]::Floor($catrisIndex / 4.0) * 304
                $catrisImage = [System.Drawing.Image]::FromFile((Join-Path $catrisReferenceRoot $catrisFrame.path))
                try { $catrisGraphics.DrawImage($catrisImage, $catrisX, $catrisY, 480, 270) }
                finally { $catrisImage.Dispose() }
                $catrisLabel = '{0}  |  {1:00.00}s' -f $catrisGroup.Name, [double]$catrisFrame.requested_seconds
                $catrisGraphics.DrawString($catrisLabel, $catrisFont, [System.Drawing.Brushes]::White, $catrisX, ($catrisY + 274))
                $catrisIndex++
            }
            $catrisName = if ($catrisGroup.Name -eq 'frames') { 'contact-sheet-labeled.jpg' } else { $catrisGroup.Name + '-labeled.jpg' }
            $catrisBitmap.Save((Join-Path $catrisReferenceRoot $catrisName), [System.Drawing.Imaging.ImageFormat]::Jpeg)
        } finally { $catrisGraphics.Dispose(); $catrisBitmap.Dispose() }
    }
} finally { $catrisFont.Dispose() }
Write-Output 'Labeled all four contact sheets.'
