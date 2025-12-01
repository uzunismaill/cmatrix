# ==========================================
# Sword Watchdogs Fixed PowerShell Script
$VideoDosyaAdi = "Welcome to the Game - Hacking Alert - Napsilon (720p, h264, youtube).mp4"

# --- PART 1: VIDEO INTRO (WPF GUI) ---
function Play-VideoIntro {
    param([string]$VideoName)
    
    $videoPath = Join-Path $PSScriptRoot $VideoName
    
    if (-not (Test-Path $videoPath)) { 
        Write-Warning "Video dosyası bulunamadı: $videoPath"
        Start-Sleep -Seconds 2
        return 
    }

    try {
        Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms
    } catch {
        Write-Warning "WPF Kütüphaneleri yüklenemedi. Video atlanıyor."
        return
    }

   
    $xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="HACKING_ALERT" Height="600" Width="800"
            WindowStyle="None" ResizeMode="NoResize" Background="Black" Topmost="True" WindowState="Maximized">
        <Grid>
            <MediaElement Name="MyPlayer" Source="$videoPath" LoadedBehavior="Play" Stretch="Uniform" Volume="1"/>
        </Grid>
    </Window>
"@

    try {
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)

        $player = $window.FindName("MyPlayer")
        $player.Add_MediaEnded({ $window.Close() })
        $player.Add_MediaFailed({ $window.Close() })
        $window.Add_MouseLeftButtonDown({ $window.Close() })

        $null = $window.ShowDialog()
    } catch {
        Write-Warning "Video penceresi oluşturulamadı."
    }
}



Play-VideoIntro -VideoName $VideoDosyaAdi

# ==========================================
# --- PART 2: CONSOLE MATRIX RAIN EFFECT ---
# ==========================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Version 2

if ($null -eq $host.UI.RawUI.WindowSize) {
    Write-Warning "Lütfen bu scripti PowerShell.exe veya Windows Terminal içinde çalıştırın."
    return
}

$global:stopRequested = $false
$null = Register-EngineEvent PowerShell.Exiting -Action { $global:stopRequested = $true }


$script:Width = [int]$host.UI.RawUI.WindowSize.Width
$script:Height = [int]$host.UI.RawUI.WindowSize.Height

function Set-Cursor {
    param([int]$X, [int]$Y)
   
    $w = [int]$script:Width
    $h = [int]$script:Height
    if ($X -ge 0 -and $X -lt $w -and $Y -ge 0 -and $Y -lt $h) {
        $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($X, $Y)
    }
}

function Write-Centered {
    param(
        [string[]]$Lines,
        [string]$Color = "White",
        [int]$Delay = 0
    )
    if (-not $Lines -or $Lines.Count -eq 0) { return }

    $h = [int]$script:Height
    $w = [int]$script:Width

    $startY = [Math]::Floor(($h - $Lines.Length) / 2)
    foreach ($rawLine in $Lines) {
        $line = $rawLine -replace "[\u200B\uFEFF\u3164]", ''
        $line = $line.TrimEnd()
        if ($line.Length -gt $w) { $line = $line.Substring(0, $w) }
        $startX = [Math]::Floor(($w - $line.Length) / 2)
        if ($startX -lt 0) { $startX = 0 }
        Set-Cursor $startX $startY
        try { Write-Host $line -ForegroundColor $Color } catch { Write-Host $line }
        $startY++
        if ($Delay -gt 0) { Start-Sleep -Milliseconds $Delay }
    }
}

function Split-Text {
    param([string]$Text, [int]$LineWidth)
    if (-not $Text) { return @() }
    $words = $Text -split '\s+'
    $lines = @()
    $line = ""
    foreach ($w in $words) {
        if (($line.Length + $w.Length + 1) -le $LineWidth) {
            $line += "$w "
        } else {
            $lines += $line.Trim()
            $line = "$w "
        }
    }
    if ($line) { $lines += $line.Trim() }
    return $lines
}


function Start-MP3 {
    param([string]$fileName, [switch]$Loop)
    $path = Join-Path $PSScriptRoot $fileName
    if (-not (Test-Path $path)) { return $null }

    try { Add-Type -AssemblyName presentationCore } catch { return $null }

    $player = New-Object System.Windows.Media.MediaPlayer
    try { $player.Open([Uri]$path) } catch { return $null }

    if ($Loop) {
        $null = Register-ObjectEvent $player MediaEnded -Action { try { $this.Position = [TimeSpan]::Zero; $this.Play() } catch {} }
    }

    try { $player.Play() } catch {}
    return $player
}

function Stop-MP3 {
    param($player)
    if ($null -ne $player) {
        try { $player.Stop() } catch {}
        try { $player.Close() } catch {}
    }
}


function Glitch-Lines {
    param([string[]]$Lines, [int]$intensity = 8)
    if (-not $Lines) { return @() }
    $out = @()
    foreach ($L in $Lines) {
        $chars = $L.ToCharArray()
        for ($i = 0; $i -lt $chars.Length; $i++) {
            if ((Get-Random -Maximum $intensity) -eq 0) {
                $chars[$i] = [char](Get-Random -Minimum 33 -Maximum 126)
            }
        }
        $out += (-join $chars)
    }
    return $out
}


$oldBG = $host.UI.RawUI.BackgroundColor
$oldFG = $host.UI.RawUI.ForegroundColor
try { $oldCursorVisible = $host.UI.RawUI.CursorVisible } catch { $oldCursorVisible = $true }


$bootLines = @(
    "BOOT: Kernel initializing...",
    "BOOT: Loading modules [auth,net,crypto]...",
    "SECURITY: Verifying security sectors...",
    "CRYPTO: Decrypting firmware fragments...",
    "NETWORK: Establishing tunnel to 198.51.100.23...",
    "NETWORK: Route established. Latency=18ms",
    "AV: Signatures bypassed...",
    "SYSTEM: Handshake complete. Ready."
)

function Play-BootSequence {
    param([int]$speedMs = 200)
    Clear-Host
    foreach ($l in $bootLines) {
        Write-Host $l -ForegroundColor DarkGray
        Start-Sleep -Milliseconds $speedMs
        if ($global:stopRequested) { return }
    }
    Start-Sleep -Milliseconds 300
}


function Show-Access {
    param([switch]$Granted)
    $text = if ($Granted) { "ACCESS GRANTED" } else { "ACCESS DENIED" }
    $color = if ($Granted) { "Green" } else { "Red" }
    
    
    $w = [int]$script:Width
    
    for ($i=0; $i -lt 5; $i++) {
        $lines = Glitch-Lines (Split-Text $text ([int]($w/2))) 3
        Clear-Host
        Write-Centered $lines $color 40
        Start-Sleep -Milliseconds 220
    }
    Start-Sleep -Seconds 1
}

# ---- Matrix Rain
function Start-MatrixRain {
    $charSet = @('0','1')
    $columns = @{}
    
    # İlk genişlik/yükseklik ataması
    $script:Width = [int]$host.UI.RawUI.WindowSize.Width
    $script:Height = [int]$host.UI.RawUI.WindowSize.Height

    $maxColumns = [Math]::Max(1, [Math]::Floor([int]$script:Width / 3))
    
    $rainPlayer = Start-MP3 "matrix_rain.mp3" -Loop

    $miniMsgs = @(
        "NEXUS: Connection alive",
        "PROXY: Chain active",
        "PING: 12ms",
        "FIREWALL: Bypassed",
        "PAYLOAD: Uploading..."
    )

    while (-not $global:stopRequested) {
        $currentWidth = [int]$host.UI.RawUI.WindowSize.Width
        $currentHeight = [int]$host.UI.RawUI.WindowSize.Height

        # Pencere boyutu değişirse güncelle
        if ($currentWidth -ne $script:Width -or $currentHeight -ne $script:Height) {
            $script:Width = $currentWidth
            $script:Height = $currentHeight
            Clear-Host
        }
        
        # Değişkenleri yerel, güvenli integerlara alalım
        $w = [int]$script:Width
        $h = [int]$script:Height

        if ($columns.Count -lt $maxColumns -and (Get-Random -Maximum 10) -lt 4) {
            $x = Get-Random -Minimum 0 -Maximum $w
            if (-not $columns.ContainsKey($x)) {
                $columns[$x] = [PSCustomObject]@{
                    YHead = 0
                    YFade = 0
                    Length = Get-Random -Minimum ([Math]::Max(3, [int]($h/4))) -Maximum ($h-2)
                    Speed = Get-Random -Minimum 0 -Maximum 2
                    Counter = 0
                }
            }
        }

        $remove = @()
        foreach ($x in $columns.Keys) {
            $col = $columns[$x]
            if ($col.Counter -lt $col.Speed) { $col.Counter++; continue }
            $col.Counter = 0

            $c = $charSet[(Get-Random -Maximum $charSet.Count)]
            if ($col.YHead -lt $h) {
                Set-Cursor $x $col.YHead
                [Console]::ForegroundColor = "White"
                [Console]::Write($c)
            }

            $greenY = $col.YHead - 1
            if ($greenY -ge 0) {
                Set-Cursor $x $greenY
                [Console]::ForegroundColor = "Green"
                [Console]::Write($charSet[(Get-Random -Maximum $charSet.Count)])
            }

            $darkY = $col.YHead - 2
            if ($darkY -ge 0) {
                Set-Cursor $x $darkY
                [Console]::ForegroundColor = "DarkGreen"
                [Console]::Write($charSet[(Get-Random -Maximum $charSet.Count)])
            }

            if ($col.YHead -ge $col.Length) {
                if ($col.YFade -lt $h) {
                    Set-Cursor $x $col.YFade
                    [Console]::Write(" ")
                }
                $col.YFade++
            }

            $col.YHead++
            if ($col.YFade -ge $h) { $remove += $x }
        }

        foreach ($r in $remove) { $columns.Remove($r) }

        if ((Get-Random -Maximum 100) -lt 4) {
            $msg = $miniMsgs[(Get-Random -Maximum $miniMsgs.Count)]
            
            
            
            $maxX = [Math]::Max(2, ($w - 30))
            $maxY = [Math]::Max(3, ($h - 4))
            
            $rx = Get-Random -Minimum 2 -Maximum $maxX
            $ry = Get-Random -Minimum 2 -Maximum $maxY
            
            Set-Cursor $rx $ry
            Write-Host $msg -ForegroundColor Cyan
        }

        Start-Sleep -Milliseconds 38
    }

    if ($rainPlayer) { Stop-MP3 $rainPlayer }
}

# ---- MAIN EXECUTION
try {
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "Green"
    try { $host.UI.RawUI.CursorVisible = $false } catch {}
    Clear-Host

    Write-Host "[Info] Video oynatılıyor..." -ForegroundColor DarkGray
    
  # Animation 
    Play-BootSequence -speedMs 50
    
    # Erişim onayı/reddi animasyonu
    Write-Host "SYSTEM: Authenticating user..." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 500
    Write-Host "SYSTEM: Challenge accepted." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 600

    $granted = (Get-Random -Maximum 10) -gt 2
    Show-Access -Granted:($granted)
    if ($global:stopRequested) { return }

    # Ve yağmur başlasın
    Start-MatrixRain

} finally {
    [Console]::ResetColor()
    $host.UI.RawUI.BackgroundColor = $oldBG
    $host.UI.RawUI.ForegroundColor = $oldFG
    try { $host.UI.RawUI.CursorVisible = $oldCursorVisible } catch {}
    Clear-Host
    Write-Host "`nSession ended. Console settings restored." -ForegroundColor Cyan
}
