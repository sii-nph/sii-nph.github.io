# Convert one original artwork image into the file used by the site:
#   long edge 1600px (JPEG) -> assets/images/works/<Name>.jpg
#
# Aspect ratio is kept. The artwork itself is never cropped. The output is
# redrawn into a new bitmap, so EXIF data (including GPS) is NOT carried over.
# Colors are not adjusted.
#
# Usage (from the repository root):
#   powershell -ExecutionPolicy Bypass -File _tools\make-images.ps1 -Source "_inbox\scan-001.jpg" -Name 2024-01
#
# Optional -Crop "left,top,right,bottom" (pixels of the ORIGINAL image) trims the
# scanner bed that shows around the paper. Keep the edges about 60px inside the
# paper edge so no shadow or gray strip remains:
#   ... -Source "_inbox\scan-003.jpg" -Name 2025-01 -Crop "0,0,4400,6590"
#
# NOTE: keep this file ASCII-only. Windows PowerShell 5.1 reads a BOM-less
# UTF-8 file as ANSI, which garbles Japanese text.

param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Crop = '',
    [int]$FullSize = 1600,
    [int]$Quality = 85
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
if (-not [System.IO.Path]::IsPathRooted($Source)) { $Source = Join-Path $root $Source }
if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)

function Save-Resized {
    param($Image, [System.Drawing.Rectangle]$Src, [int]$LongEdge, [string]$OutPath)

    $scale = [Math]::Min(1.0, $LongEdge / [Math]::Max($Src.Width, $Src.Height))
    $w = [int][Math]::Round($Src.Width * $scale)
    $h = [int][Math]::Round($Src.Height * $scale)

    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    try {
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $dest = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
        $g.DrawImage($Image, $dest, $Src.X, $Src.Y, $Src.Width, $Src.Height,
            [System.Drawing.GraphicsUnit]::Pixel, $attr)

        $dir = Split-Path $OutPath -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $bmp.Save($OutPath, $jpegCodec, $encoderParams)
    }
    finally {
        $attr.Dispose(); $g.Dispose(); $bmp.Dispose()
    }
    return [pscustomobject]@{ Path = $OutPath; Width = $w; Height = $h; KB = [int]((Get-Item -LiteralPath $OutPath).Length / 1KB) }
}

$img = [System.Drawing.Image]::FromFile($Source)
try {
    # Apply the EXIF orientation (tag 0x0112) so the output is upright.
    if ($img.PropertyIdList -contains 0x0112) {
        $orientation = $img.GetPropertyItem(0x0112).Value[0]
        switch ($orientation) {
            3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
            6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
            8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
        }
    }

    # Area of the original to use: the whole image, or the -Crop box.
    $src = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $img.Height)
    if ($Crop) {
        $v = @($Crop -split '\s*,\s*' | ForEach-Object { [int]$_ })
        if ($v.Count -ne 4) { throw "-Crop needs 4 numbers: left,top,right,bottom" }
        $left, $top, $right, $bottom = $v
        if ($left -lt 0 -or $top -lt 0 -or $right -gt $img.Width -or $bottom -gt $img.Height -or
            $right -le $left -or $bottom -le $top) {
            throw "-Crop '$Crop' is outside the image ($($img.Width)x$($img.Height)) or reversed"
        }
        $src = New-Object System.Drawing.Rectangle($left, $top, ($right - $left), ($bottom - $top))
    }
    "source: {0}x{1}  using: x={2} y={3} {4}x{5}" -f $img.Width, $img.Height, $src.X, $src.Y, $src.Width, $src.Height

    $full = Save-Resized $img $src $FullSize (Join-Path $root "assets\images\works\$Name.jpg")
}
finally {
    $img.Dispose()
}

"full: {0}x{1}  {2} KB  {3}" -f $full.Width, $full.Height, $full.KB, $full.Path
""
"Paste into _data/works.yml:"
"  image: /assets/images/works/$Name.jpg"
"  width: $($full.Width)"
"  height: $($full.Height)"
