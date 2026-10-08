Add-Type -AssemblyName System.Drawing
$srcPath = "$PSScriptRoot\..\assets\images\timerin.png"
$resRoot = "$PSScriptRoot\..\android\app\src\main\res"

$sizes = @{
    'mipmap-mdpi'    = 48
    'mipmap-hdpi'    = 72
    'mipmap-xhdpi'   = 96
    'mipmap-xxhdpi'  = 144
    'mipmap-xxxhdpi' = 192
}

$srcImage = [System.Drawing.Image]::FromFile($srcPath)

foreach ($dir in $sizes.Keys) {
    $dim = $sizes[$dir]
    $destFolder = Join-Path $resRoot $dir
    $destPath = Join-Path $destFolder 'ic_launcher.png'
    
    $destBmp = New-Object System.Drawing.Bitmap $dim, $dim
    $graphics = [System.Drawing.Graphics]::FromImage($destBmp)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    
    $graphics.DrawImage($srcImage, 0, 0, $dim, $dim)
    $graphics.Dispose()
    
    $destBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Generated $dir/ic_launcher.png ($dim x $dim px)"
}

$srcImage.Dispose()
Write-Host "All launcher icons generated successfully!"
