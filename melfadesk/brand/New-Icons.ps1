# Renders icon.svg with Microsoft Edge and writes every icon the Windows build uses. Run it only when the mark changes.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$brand = $PSScriptRoot
$root = (Resolve-Path "$brand\..\..").Path
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$work = Join-Path ([IO.Path]::GetTempPath()) "melfadesk-icons-$([guid]::NewGuid().ToString('N'))"
New-Item $work -ItemType Directory | Out-Null
try {
    $svg = (Get-Content "$brand\icon.svg" -Raw) -replace 'width="48" height="48"', 'width="512" height="512"'
    "<!doctype html><style>html,body{margin:0;background:transparent;overflow:hidden}svg{display:block}</style>$svg" |
        Set-Content "$work\icon.html" -Encoding utf8NoBOM
    $png = "$work\icon.png"
    $arguments = "--headless=new", "--disable-gpu", "--no-first-run", "--user-data-dir=`"$work\profile`"", "--hide-scrollbars",
        "--force-device-scale-factor=1", "--default-background-color=00000000", "--window-size=512,512",
        "--screenshot=`"$png`"", "`"file:///$($work -replace '\\','/')/icon.html`""
    Start-Process $edge $arguments -Wait -WindowStyle Hidden
    for ($i = 0; $i -lt 100 -and -not (Test-Path $png); $i++) { Start-Sleep -Milliseconds 100 }
    $source = [System.Drawing.Image]::FromFile($png)
    if ($source.Width -ne 512 -or $source.Height -ne 512) { throw "Unexpected picture size $($source.Size)." }

    function Get-Png([int]$size) {
        $bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.InterpolationMode = "HighQualityBicubic"; $graphics.PixelOffsetMode = "HighQuality"
        $graphics.CompositingMode = "SourceCopy"
        $graphics.DrawImage($source, 0, 0, $size, $size)
        $graphics.Dispose()
        $stream = New-Object System.IO.MemoryStream
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png); $bitmap.Dispose()
        , $stream.ToArray()
    }
    function Save-Icon([string]$path, [int[]]$sizes) {
        $images = @($sizes | ForEach-Object { [pscustomobject]@{ Size = $_; Bytes = [byte[]](Get-Png $_) } })
        $file = New-Object System.IO.MemoryStream
        $writer = New-Object System.IO.BinaryWriter $file
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$images.Count)
        $offset = 6 + 16 * $images.Count
        foreach ($image in $images) {
            $dimension = [byte]($image.Size -ge 256 ? 0 : $image.Size)
            $writer.Write($dimension); $writer.Write($dimension); $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$image.Bytes.Length); $writer.Write([uint32]$offset)
            $offset += $image.Bytes.Length
        }
        foreach ($image in $images) { $writer.Write([byte[]]$image.Bytes) }
        $writer.Flush()
        [IO.File]::WriteAllBytes($path, $file.ToArray())
    }

    $sizes = 16, 24, 32, 48, 64, 128, 256
    Save-Icon "$root\res\icon.ico" $sizes
    Save-Icon "$root\flutter\windows\runner\resources\app_icon.ico" $sizes
    Save-Icon "$root\res\tray-icon.ico" @(32)
    foreach ($item in @(@(32, "32x32.png"), @(64, "64x64.png"), @(128, "128x128.png"), @(256, "128x128@2x.png"), @(1024, "icon.png"))) {
        [IO.File]::WriteAllBytes("$root\res\$($item[1])", [byte[]](Get-Png $item[0]))
    }
    Copy-Item "$brand\icon.svg" "$root\flutter\assets\icon.svg" -Force
    $source.Dispose()
}
finally { Remove-Item $work -Recurse -Force -ErrorAction Continue }
