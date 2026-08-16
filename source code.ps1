$ErrorActionPreference = "Stop"

function Get-AppDirectory {

    if (
        -not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and
        (Test-Path -LiteralPath $PSScriptRoot)
    ) {
        return [System.IO.Path]::GetFullPath($PSScriptRoot)
    }

    try {
        $CommandPath = $MyInvocation.MyCommand.Path

        if (
            -not [string]::IsNullOrWhiteSpace($CommandPath) -and
            (Test-Path -LiteralPath $CommandPath)
        ) {
            return [System.IO.Path]::GetFullPath(
                (Split-Path -Parent $CommandPath)
            )
        }
    }
    catch {
    }

    try {
        $ProcessPath =
            [System.Diagnostics.Process]::GetCurrentProcess().
            MainModule.FileName

        if (
            -not [string]::IsNullOrWhiteSpace($ProcessPath)
        ) {
            return [System.IO.Path]::GetFullPath(
                (Split-Path -Parent $ProcessPath)
            )
        }
    }
    catch {
    }

    return [System.IO.Directory]::GetCurrentDirectory()
}

$AppDir = Get-AppDirectory

$BinDir = Join-Path `
    $AppDir `
    "bin"

$YtDlpPath = Join-Path `
    $BinDir `
    "yt-dlp.exe"

$FFmpegPath = Join-Path `
    $BinDir `
    "ffmpeg.exe"

$FFprobePath = Join-Path `
    $BinDir `
    "ffprobe.exe"

$BaseDir = "D:\Top4Top"

$DownloadDir = Join-Path `
    $BaseDir `
    "Downloads"

$MP3Dir = Join-Path `
    $BaseDir `
    "MP3"

$DebugDir = Join-Path `
    $BaseDir `
    "Debug"

foreach ($Folder in @(
    $BaseDir,
    $DownloadDir,
    $MP3Dir,
    $DebugDir
)) {

    if (
        !(Test-Path `
            -LiteralPath $Folder)
    ) {

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force |
            Out-Null
    }
}

function Test-Bin {

    Write-Host ""
    Write-Host "[*] Mengecek dependency..." `
        -ForegroundColor DarkGray

    Write-Host ""

    Write-Host "Folder aplikasi:" `
        -ForegroundColor DarkGray

    Write-Host $AppDir `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Folder bin:" `
        -ForegroundColor DarkGray

    Write-Host $BinDir `
        -ForegroundColor Yellow

    Write-Host ""

    if (
        !(Test-Path `
            -LiteralPath $YtDlpPath `
            -PathType Leaf)
    ) {

        throw @"

yt-dlp.exe tidak ditemukan.

Program mencari:

$YtDlpPath

Pastikan struktur folder:

Top4Top.exe
bin\
    yt-dlp.exe
    ffmpeg.exe
    ffprobe.exe

"@
    }

    Write-Host "[OK] yt-dlp.exe ditemukan." `
        -ForegroundColor Green

    if (
        !(Test-Path `
            -LiteralPath $FFmpegPath `
            -PathType Leaf)
    ) {

        throw @"

ffmpeg.exe tidak ditemukan.

Program mencari:

$FFmpegPath

Pastikan file berada di:

bin\ffmpeg.exe

"@
    }

    Write-Host "[OK] ffmpeg.exe ditemukan." `
        -ForegroundColor Green

    if (
        !(Test-Path `
            -LiteralPath $FFprobePath `
            -PathType Leaf)
    ) {

        throw @"

ffprobe.exe tidak ditemukan.

Program mencari:

$FFprobePath

Pastikan file berada di:

bin\ffprobe.exe

"@
    }

    Write-Host "[OK] ffprobe.exe ditemukan." `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "[OK] Semua dependency ditemukan." `
        -ForegroundColor Green
}

function Download-Media {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host "[1/4] DOWNLOAD MEDIA" `
        -ForegroundColor Cyan

    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Get-ChildItem `
        -LiteralPath $DownloadDir `
        -File `
        -ErrorAction SilentlyContinue |
        Remove-Item `
        -Force `
        -ErrorAction SilentlyContinue

    $OutputTemplate = Join-Path `
        $DownloadDir `
        "%(title).200s.%(ext)s"

    Write-Host "[*] Mendeteksi situs..." `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "URL:" `
        -ForegroundColor DarkGray

    Write-Host $Url `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "[*] Download media..." `
        -ForegroundColor Cyan

    Write-Host ""

    & $YtDlpPath `
        --no-playlist `
        --newline `
        --retries 3 `
        --fragment-retries 3 `
        --file-access-retries 3 `
        --ffmpeg-location "$BinDir" `
        -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b" `
        --merge-output-format mp4 `
        --restrict-filenames `
        -o "$OutputTemplate" `
        "$Url" |
        Out-Host

    $ExitCode = $LASTEXITCODE

    $Video = Get-ChildItem `
        -LiteralPath $DownloadDir `
        -File `
        -Filter "*.mp4" `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (
        $null -eq $Video -or
        $ExitCode -ne 0
    ) {

        throw @"

Download media gagal.

Exit code yt-dlp:

$ExitCode

Program:

$YtDlpPath

URL:

$Url

"@
    }

    $VideoPath =
        [System.IO.Path]::GetFullPath(
            $Video.FullName
        )

    Write-Host ""
    Write-Host "[OK] Media berhasil didownload." `
        -ForegroundColor Green

    Write-Host ""

    Write-Host "File:" `
        -ForegroundColor DarkGray

    Write-Host $Video.Name `
        -ForegroundColor Yellow

    Write-Host ""

    return [string]$VideoPath
}

function Convert-ToMP3 {

    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host "[2/4] KONVERSI KE MP3" `
        -ForegroundColor Cyan

    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host ""

    if (
        !(Test-Path `
            -LiteralPath $VideoPath `
            -PathType Leaf)
    ) {

        throw "File video tidak ditemukan: $VideoPath"
    }

    $VideoInfo =
        Get-Item `
            -LiteralPath $VideoPath

    $BaseName =
        [System.IO.Path]::GetFileNameWithoutExtension(
            $VideoInfo.Name
        )

    $MP3Path =
        Join-Path `
            $MP3Dir `
            "$BaseName.mp3"

    if (
        Test-Path `
            -LiteralPath $MP3Path
    ) {

        Remove-Item `
            -LiteralPath $MP3Path `
            -Force
    }

    Write-Host "Input:" `
        -ForegroundColor DarkGray

    Write-Host $VideoPath `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Output:" `
        -ForegroundColor DarkGray

    Write-Host $MP3Path `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "[*] Mengubah audio menjadi MP3..." `
        -ForegroundColor Cyan

    Write-Host ""

    & $FFmpegPath `
        -y `
        -i "$VideoPath" `
        -vn `
        -codec:a libmp3lame `
        -b:a 192k `
        -map_metadata 0 `
        "$MP3Path" |
        Out-Host

    if (
        $LASTEXITCODE -ne 0
    ) {

        throw "FFmpeg gagal mengubah media menjadi MP3."
    }

    if (
        !(Test-Path `
            -LiteralPath $MP3Path `
            -PathType Leaf)
    ) {

        throw "File MP3 tidak ditemukan setelah proses FFmpeg."
    }

    $MP3Info =
        Get-Item `
            -LiteralPath $MP3Path

    Write-Host ""
    Write-Host "[OK] MP3 berhasil dibuat." `
        -ForegroundColor Green

    Write-Host ""

    Write-Host "File MP3:" `
        -ForegroundColor DarkGray

    Write-Host $MP3Info.Name `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Ukuran:" `
        -ForegroundColor DarkGray

    Write-Host (
        "{0:N2} MB" -f (
            $MP3Info.Length / 1MB
        )
    ) `
        -ForegroundColor Yellow

    Write-Host ""

    return [string](
        [System.IO.Path]::GetFullPath(
            $MP3Path
        )
    )
}

function Upload-Top4Top {

    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host "[3/4] UPLOAD MP3 KE TOP4TOP" `
        -ForegroundColor Cyan

    Write-Host "============================================" `
        -ForegroundColor Cyan

    Write-Host ""

    $FilePath = [string]$FilePath

    if (
        !(Test-Path `
            -LiteralPath $FilePath `
            -PathType Leaf)
    ) {

        throw "File MP3 tidak ditemukan: $FilePath"
    }

    $FileInfo =
        Get-Item `
            -LiteralPath $FilePath

    $FileName =
        $FileInfo.Name

    Write-Host "File:" `
        -ForegroundColor DarkGray

    Write-Host $FileName `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Ukuran:" `
        -ForegroundColor DarkGray

    Write-Host (
        "{0:N2} MB" -f (
            $FileInfo.Length / 1MB
        )
    ) `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "[*] Membaca file MP3..." `
        -ForegroundColor DarkGray

    $FileBytes =
        [System.IO.File]::ReadAllBytes(
            $FilePath
        )

    $Boundary =
        "----PowerShellTop4Top" +
        [Guid]::NewGuid().ToString("N")

    $Body =
        New-Object System.Collections.Generic.List[byte]

    function Add-Bytes {

        param(
            [byte[]]$Bytes
        )

        foreach ($Byte in $Bytes) {
            $Body.Add($Byte)
        }
    }

    function Add-Text {

        param(
            [string]$Text
        )

        Add-Bytes (
            [System.Text.Encoding]::UTF8.GetBytes(
                $Text
            )
        )
    }

    Add-Text "--$Boundary`r`n"

    Add-Text (
        "Content-Disposition: form-data; " +
        "name=`"file_1_`"; " +
        "filename=`"$FileName`"`r`n"
    )

    Add-Text (
        "Content-Type: audio/mpeg`r`n"
    )

    Add-Text "`r`n"

    Add-Bytes $FileBytes

    Add-Text "`r`n"

    Add-Text "--$Boundary`r`n"

    Add-Text (
        "Content-Disposition: form-data; " +
        "name=`"submitr`"`r`n"
    )

    Add-Text "`r`n"

    Add-Text "[ رفع الملفات ]"

    Add-Text "`r`n"

    Add-Text "--$Boundary--`r`n"

    $Headers = @{

        "User-Agent" =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/151.0 Safari/537.36"

        "Accept" =
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

        "Accept-Language" =
            "en-US,en;q=0.9"

        "Referer" =
            "https://top4top.io/"

        "Origin" =
            "https://top4top.io"
    }

    Write-Host "[*] Mengupload MP3..." `
        -ForegroundColor Cyan

    Write-Host ""

    try {

        $Response =
            Invoke-WebRequest `
                -Uri "https://top4top.io/index.php" `
                -Method POST `
                -Headers $Headers `
                -ContentType (
                    "multipart/form-data; boundary=$Boundary"
                ) `
                -Body ([byte[]]$Body) `
                -MaximumRedirection 10
    }
    catch {

        throw (
            "Upload Top4toP gagal: " +
            $_.Exception.Message
        )
    }

    $Html =
        [string]$Response.Content

    $DebugFile =
        Join-Path `
            $DebugDir `
            "top4top-response.html"

    $Html |
        Out-File `
        -LiteralPath $DebugFile `
        -Encoding UTF8

    $Patterns = @(

        'href\s*=\s*["''](https?://(?:[a-zA-Z0-9-]+\.)?top4top\.(?:io|me)/[^"'']+\.mp3)["'']',

        'https?://(?:[a-zA-Z0-9-]+\.)?top4top\.(?:io|me)/[^\s"''<>]+\.mp3',

        'value\s*=\s*["''](https?://(?:[a-zA-Z0-9-]+\.)?top4top\.(?:io|me)/[^"'']+\.mp3)["'']'
    )

    $FoundUrl = $null

    foreach ($Pattern in $Patterns) {

        $Match =
            [regex]::Match(
                $Html,
                $Pattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

        if ($Match.Success) {

            if (
                $Match.Groups.Count -gt 1 -and
                ![string]::IsNullOrWhiteSpace(
                    $Match.Groups[1].Value
                )
            ) {

                $FoundUrl =
                    $Match.Groups[1].Value
            }
            else {

                $FoundUrl =
                    $Match.Value
            }

            break
        }
    }

    if ($FoundUrl) {

        $FoundUrl =
            $FoundUrl `
                -replace '&amp;', '&' `
                -replace '\\/', '/' `
                -replace '["''<>]', ''
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $FoundUrl
        )
    ) {

        Write-Host ""
        Write-Host "Response server disimpan di:" `
            -ForegroundColor Yellow

        Write-Host $DebugFile `
            -ForegroundColor DarkYellow

        throw @"

Upload berhasil diakses, tetapi direct link MP3 tidak ditemukan.

Response Top4toP:

$DebugFile

"@
    }

    return [string]$FoundUrl
}

function Show-Banner {

    Clear-Host

    Write-Host ""

    Write-Host "██████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██████╗ ██╗   ██╗██╗  ██╗" `
        -ForegroundColor Cyan

    Write-Host "██╔══██╗██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██║ ██╔╝" `
        -ForegroundColor Cyan

    Write-Host "██████╔╝██║   ██║██████╔╝██████╔╝ ╚████╔╝ ███████╗██████╔╝██████╔╝ ╚████╔╝ █████╔╝ " `
        -ForegroundColor Cyan

    Write-Host "██╔══██╗██║   ██║██╔══██╗██╔══██╗  ╚██╔╝  ╚════██║██╔═══╝ ██╔══██╗  ╚██╔╝  ██╔═██╗ " `
        -ForegroundColor Cyan

    Write-Host "██║  ██║╚██████╔╝██████╔╝██████╔╝   ██║   ███████║██║     ██║  ██║   ██║   ██║  ██╗" `
        -ForegroundColor Cyan

    Write-Host "╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Created by: Afreldo AKA robby5pryk-sudo, Visit on Youtube: https://www.youtube.com/@BibzS4mpwats" `
        -ForegroundColor DarkCyan

    Write-Host ""

    Write-Host "============================================" `
        -ForegroundColor DarkCyan

    Write-Host "       YouTube -> MP3 -> Top4toP" `
        -ForegroundColor Cyan

    Write-Host "============================================" `
        -ForegroundColor DarkCyan

    Write-Host ""

    Write-Host "Application:" `
        -ForegroundColor DarkGray

    Write-Host $AppDir `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "BIN:" `
        -ForegroundColor DarkGray

    Write-Host $BinDir `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "Download:" `
        -ForegroundColor DarkGray

    Write-Host $DownloadDir `
        -ForegroundColor Yellow

    Write-Host ""

    Write-Host "MP3:" `
        -ForegroundColor DarkGray

    Write-Host $MP3Dir `
        -ForegroundColor Yellow

    Write-Host ""
}

Show-Banner

try {

    Test-Bin
}
catch {

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor Red

    Write-Host "SETUP ERROR" `
        -ForegroundColor Red

    Write-Host "============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    Write-Host ""

    Read-Host "Tekan ENTER untuk keluar"

    exit
}

while ($true) {

    Write-Host ""
    Write-Host "============================================" `
        -ForegroundColor DarkCyan

    Write-Host "          MASUKKAN LINK MEDIA" `
        -ForegroundColor Cyan

    Write-Host "              YouTube" `
        -ForegroundColor DarkGray

    Write-Host "          Ketik Q untuk keluar" `
        -ForegroundColor DarkGray

    Write-Host "============================================" `
        -ForegroundColor DarkCyan

    Write-Host ""

    $MediaUrl =
        Read-Host "Masukkan link"

    if (
        $MediaUrl.Trim() -match "^[Qq]$"
    ) {

        Write-Host ""
        Write-Host "Program dihentikan." `
            -ForegroundColor Yellow

        break
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $MediaUrl
        )
    ) {

        Write-Host ""
        Write-Host "URL tidak boleh kosong." `
            -ForegroundColor Red

        continue
    }

    if (
        $MediaUrl -notmatch
        "^https?://(?:www\.)?(?:youtube\.com|youtu\.be)/"
    ) {

        Write-Host ""
        Write-Host "URL YouTube tidak valid." `
            -ForegroundColor Red

        continue
    }

    try {

        $VideoFile =
            Download-Media `
            -Url $MediaUrl

        $VideoFile =
            [string]$VideoFile

        $MP3File =
            Convert-ToMP3 `
            -VideoPath $VideoFile

        $MP3File =
            [string]$MP3File

        $Top4TopUrl =
            Upload-Top4Top `
            -FilePath $MP3File

        $Top4TopUrl =
            [string]$Top4TopUrl

        Write-Host ""

        Write-Host "============================================" `
            -ForegroundColor Green

        Write-Host "                 SELESAI!" `
            -ForegroundColor Green

        Write-Host "============================================" `
            -ForegroundColor Green

        Write-Host ""

        Write-Host "LINK MP3 TOP4TOP:" `
            -ForegroundColor Yellow

        Write-Host ""

        Write-Host $Top4TopUrl `
            -ForegroundColor Cyan

        Write-Host ""

        Write-Host "============================================" `
            -ForegroundColor Green

        try {

            Set-Clipboard `
                -Value $Top4TopUrl

            Write-Host ""
            Write-Host "Link MP3 sudah disalin ke clipboard." `
                -ForegroundColor Green
        }
        catch {

            Write-Host ""
            Write-Host "Clipboard tidak tersedia." `
                -ForegroundColor Yellow
        }

        Write-Host ""

        Write-Host "File MP3:" `
            -ForegroundColor DarkGray

        Write-Host $MP3File `
            -ForegroundColor Yellow

        Write-Host ""

        $DeleteVideo =
            Read-Host `
                "Hapus file MP4 setelah selesai? (Y/N)"

        if (
            $DeleteVideo -match "^[Yy]$"
        ) {

            if (
                Test-Path `
                    -LiteralPath $VideoFile
            ) {

                Remove-Item `
                    -LiteralPath $VideoFile `
                    -Force

                Write-Host ""
                Write-Host "File MP4 telah dihapus." `
                    -ForegroundColor Green
            }
        }

        Write-Host ""

        $DeleteMP3 =
            Read-Host `
                "Hapus file MP3 setelah upload? (Y/N)"

        if (
            $DeleteMP3 -match "^[Yy]$"
        ) {

            if (
                Test-Path `
                    -LiteralPath $MP3File
            ) {

                Remove-Item `
                    -LiteralPath $MP3File `
                    -Force

                Write-Host ""
                Write-Host "File MP3 telah dihapus." `
                    -ForegroundColor Green
            }
        }

        Write-Host ""

        Write-Host "============================================" `
            -ForegroundColor DarkGreen

        Write-Host "Siap memproses link berikutnya..." `
            -ForegroundColor Green

        Write-Host "============================================" `
            -ForegroundColor DarkGreen
    }
    catch {

        Write-Host ""

        Write-Host "============================================" `
            -ForegroundColor Red

        Write-Host "                    ERROR" `
            -ForegroundColor Red

        Write-Host "============================================" `
            -ForegroundColor Red

        Write-Host ""

        Write-Host $_.Exception.Message `
            -ForegroundColor Red

        Write-Host ""

        Write-Host "Proses gagal, tetapi program tetap berjalan." `
            -ForegroundColor Yellow

        Write-Host "Silakan masukkan link berikutnya." `
            -ForegroundColor Yellow
    }

    Start-Sleep `
        -Milliseconds 800
}

Write-Host ""

Write-Host "============================================" `
    -ForegroundColor DarkCyan

Write-Host "Program selesai." `
    -ForegroundColor Cyan

Write-Host "============================================" `
    -ForegroundColor DarkCyan

Write-Host ""