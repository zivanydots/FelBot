# Convert the generated PNG to WoW's uncompressed 32-bit TGA texture format.
Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $PSScriptRoot 'FelBot-wordmark.png'
$outputPath = Join-Path $PSScriptRoot '../Media/Wordmark.tga'
$source = [System.Drawing.Image]::FromFile($sourcePath)
$bitmap = New-Object System.Drawing.Bitmap 512,256
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.DrawImage($source, 0, 0, 512, 256)
$graphics.Dispose()
$source.Dispose()
$rectangle = New-Object System.Drawing.Rectangle 0,0,512,256
$data = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pixels = New-Object byte[] (512 * 256 * 4)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $pixels.Length)
$bitmap.UnlockBits($data)
$bitmap.Dispose()
# Type 2, 512 x 256, BGRA, top-left origin and 8 alpha bits.
$header = [byte[]](0,0,2,0,0,0,0,0,0,0,0,0,0,2,0,1,32,40)
$stream = [System.IO.File]::Create($outputPath)
try { $stream.Write($header,0,$header.Length); $stream.Write($pixels,0,$pixels.Length) }
finally { $stream.Dispose() }
