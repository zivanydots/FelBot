# Create the CurseForge PNG and WoW TGA from the square FB master artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $PSScriptRoot 'FelBot-icon-source.png'
$pngPath = Join-Path $PSScriptRoot 'FelBot-icon.png'
$mediaPath = Join-Path $PSScriptRoot '../Media'
if (-not (Test-Path -LiteralPath $mediaPath)) { $mediaPath = Join-Path $PSScriptRoot '../FelBot/Media' }
if (-not (Test-Path -LiteralPath $mediaPath)) { throw 'Cannot locate the addon Media directory.' }
$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
    if ($source.Width -ne $source.Height) { throw 'The master icon must be square.' }
    foreach ($size in @(400,256)) {
        $bitmap = New-Object System.Drawing.Bitmap $size,$size
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Black)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.DrawImage($source,0,0,$size,$size)
            } finally { $graphics.Dispose() }
            if ($size -eq 400) {
                $bitmap.Save($pngPath,[System.Drawing.Imaging.ImageFormat]::Png)
            } else {
                $rectangle = New-Object System.Drawing.Rectangle 0,0,$size,$size
                $data = $bitmap.LockBits($rectangle,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                try {
                    $pixels = New-Object byte[] ($size*$size*4)
                    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
                } finally { $bitmap.UnlockBits($data) }
                # Uncompressed true-colour, 256 x 256, BGRA, top-left origin.
                $header = [byte[]](0,0,2,0,0,0,0,0,0,0,0,0,0,1,0,1,32,40)
                $stream = [System.IO.File]::Create((Join-Path $mediaPath 'Icon.tga'))
                try { $stream.Write($header,0,$header.Length); $stream.Write($pixels,0,$pixels.Length) }
                finally { $stream.Dispose() }
            }
        } finally { $bitmap.Dispose() }
    }
} finally { $source.Dispose() }
Write-Output 'Created 400x400 CurseForge PNG and 256x256 addon TGA.'
