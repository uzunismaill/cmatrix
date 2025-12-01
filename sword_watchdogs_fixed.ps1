# ==========================================
# CROSS-PLATFORM HACKER TERMINAL (WIN + LINUX)
# ==========================================

# 1. AYARLAR: Video dosyanızın adı
$VideoDosyaAdi = "Welcome to the Game - Hacking Alert - Napsilon (720p, h264, youtube).mp4"

# --- PART 1: AKILLI VIDEO OYNATICI ---
function Play-VideoIntro {
    param([string]$VideoName)
    
    $videoPath = Join-Path $PSScriptRoot $VideoName
    
    if (-not (Test-Path $videoPath)) { 
        Write-Warning "Video dosyası bulunamadı: $videoPath"
        Start-Sleep -Seconds 2
        return 
    }

    # İŞLETİM SİSTEMİ KONTROLÜ
    if ($IsWindows) {
        # --- WINDOWS İÇİN (WPF - Çerçevesiz Pencere) ---
        try {
            Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms
            $xaml = @"
            <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    Title="ALERT" Height="600" Width="800"
                    WindowStyle="None" ResizeMode="NoResize" Background="Black" Topmost="True" WindowState="Maximized">
                <Grid>
                    <MediaElement Name="MyPlayer" Source="$videoPath" LoadedBehavior="Play" Stretch="Uniform" Volume="1"/>
                </Grid>
            </Window>
"@
            $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
            $window = [System.Windows.Markup.XamlReader]::Load($reader)
            $player = $window.FindName("MyPlayer")
            $player.Add_MediaEnded({ $window.Close() })
            $player.Add_MediaFailed({ $window.Close() })
            $window.Add_MouseLeftButtonDown({ $window.Close() })
            $null = $window.ShowDialog()
        } catch {
            # Windows'ta WPF hatası olursa varsayılan oynatıcıyı dene
            Start-Process $videoPath
            Start-Sleep -Seconds 5
        }
    }
    else {
        # --- LINUX İÇİN (MPV veya VLC veya FFMPEG) ---
        # Linux terminalinde pencere çizemeyiz, harici oynatıcıyı tam ekran çağırmalıyız.
        
        if (Get-Command "mpv" -ErrorAction SilentlyContinue) {
            # MPV varsa (En temizi budur)
            Write-Host "Linux: MPV ile başlatılıyor..." -ForegroundColor DarkGray
            Start-Process "mpv" -ArgumentList "--fs", "$videoPath" -Wait
        }
        elseif (Get-Command "vlc" -ErrorAction SilentlyContinue) {
            # VLC varsa
            Write-Host "Linux: VLC ile başlatılıyor..." -ForegroundColor DarkGray
            # --play-and-exit: Video bitince kapat
            # --fullscreen: Tam ekran
            # --no-video-title-show: Video adını gösterme
            Start-Process "vlc" -ArgumentList "--fullscreen", "--play-and-exit", "--no-video-title-show", "-I", "dummy", "$videoPath" -Wait
        }
        elseif (Get-Command "ffplay" -ErrorAction SilentlyContinue) {
            # FFPLAY varsa
            Write-Host "Linux: FFPLAY ile başlatılıyor..." -ForegroundColor DarkGray
            Start-Process "ffplay" -ArgumentList "-autoexit", "-fs", "-noborder", "$videoPath" -Wait
        }
        else {
            # Hiçbir şey yoksa uyarı ver
            Clear-Host
            Write-Warning "Linux'ta video izlemek için 'vlc' veya 'mpv' yüklü olmalıdır."
            Write-Warning "Video atlanıyor..."
            Start-Sleep -Seconds 3
        }
    }
}

# --- PART 2: MATRIX EFFEKTİ ---

Play-VideoIntro -VideoName $VideoDosyaAdi

# Konsol ayarları
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($IsWindows) { [Console]::InputEncoding = [System.Text.Encoding]::UTF8 }

Set-StrictMode -Version 2

$global:stopRequested = $false
$null = Register-EngineEvent PowerShell.Exiting -Action { $global:stopRequested = $true }

# Ekran Boyutlarını Al (Linux uyumlu yöntem)
try {
    $script:Width = [int]$host.UI.RawUI.WindowSize.Width
    $script:Height = [int]$host.UI.RawUI.WindowSize.Height
} catch {
    # Eğer Linux'ta boyut alamazsa varsayılan değerler
    $script:Width = 80
    $script:Height = 24
}

function Set-Cursor {
    param([int]$X, [int]$Y)
    $w = [int]$script:Width
    $h = [int]$script:Height
    if ($X -ge 0 -and $X -lt $w -and $Y -ge 0 -and $Y -lt $h) {
        try {
            $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($X, $Y)
        } catch {}
    }
}

function Write-Centered {
    param([string[]]$Lines, [string]$Color = "White", [int]$Delay = 0)
    if (-not $Lines) { return }
    $h = [int]$script:Height
    $w = [int]$script:Width
    $startY = [Math]::Floor(($h - $Lines.Length) / 2)
    foreach ($line in $Lines) {
        $cleanLine = $line.Trim()
        if ($cleanLine.Length -gt $w) { $cleanLine = $cleanLine.Substring(0, $w) }
        $startX = [Math]::Floor(($w - $cleanLine.Length) / 2)
        if ($startX -lt 0) { $startX = 0 }
        Set-Cursor $startX $startY
        try { Write-Host $cleanLine -ForegroundColor $Color } catch { Write-Host $cleanLine }
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
        if (($line.Length + $w.Length + 1) -le $LineWidth) { $line += "$w " } 
        else { $lines += $line.Trim(); $line = "$w " }
    }
    if ($line) { $lines += $line.Trim() }
    return $lines
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

# Boot Log
$bootLines = @(
    "BOOT: Kernel initializing...",
    "BOOT: Loading modules [auth,net,crypto]...",
    "SECURITY: Verifying security sectors...",
    "NETWORK: Establishing tunnel...",
    "SYSTEM: Handshake complete. Ready."
)

function Play-BootSequence {
    Clear-Host
    foreach ($l in $bootLines) {
        Write-Host $l -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 150
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

function Start-MatrixRain {
    $charSet = @('0','1')
    $columns = @{}
    
    # Boyutları güncelle
    try {
        $script:Width = [int]$host.UI.RawUI.WindowSize.Width
        $script:Height = [int]$host.UI.RawUI.WindowSize.Height
    } catch {}

    $maxColumns = [Math]::Max(1, [Math]::Floor([int]$script:Width / 3))
    $miniMsgs = @("NEXUS: Alive", "PROXY: Active", "PING: 12ms", "FIREWALL: Down")

    while (-not $global:stopRequested) {
        # Linux için boyut kontrolünü try-catch içine alıyoruz
        try {
            $currW = [int]$host.UI.RawUI.WindowSize.Width
            $currH = [int]$host.UI.RawUI.WindowSize.Height
            if ($currW -ne $script:Width -or $currH -ne $script:Height) {
                $script:Width = $currW; $script:Height = $currH; Clear-Host
            }
        } catch {}
        
        $w = [int]$script:Width
        $h = [int]$script:Height

        if ($columns.Count -lt $maxColumns -and (Get-Random -Maximum 10) -lt 4) {
            $x = Get-Random -Minimum 0 -Maximum $w
            if (-not $columns.ContainsKey($x)) {
                $columns[$x] = [PSCustomObject]@{
                    YHead = 0; YFade = 0; Counter = 0
                    Length = Get-Random -Minimum 3 -Maximum ($h-2)
                    Speed = Get-Random -Minimum 0 -Maximum 2
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
                if ($IsWindows) { [Console]::ForegroundColor = "White"; [Console]::Write($c) } 
                else { Write-Host $c -NoNewline -ForegroundColor White } # Linux fallback
            }
            if (($col.YHead - 1) -ge 0) {
                Set-Cursor $x ($col.YHead - 1)
                if ($IsWindows) { [Console]::ForegroundColor = "Green"; [Console]::Write($c) }
                else { Write-Host $c -NoNewline -ForegroundColor Green }
            }
            if ($col.YHead -ge $col.Length) {
                if ($col.YFade -lt $h) {
                    Set-Cursor $x $col.YFade
                    if ($IsWindows) { [Console]::Write(" ") } else { Write-Host " " -NoNewline }
                }
                $col.YFade++
            }
            $col.YHead++
            if ($col.YFade -ge $h) { $remove += $x }
        }
        foreach ($r in $remove) { $columns.Remove($r) }

        # Random Mesajlar
        if ((Get-Random -Maximum 100) -lt 4) {
             $maxX = [Math]::Max(2, ($w - 20))
             $maxY = [Math]::Max(3, ($h - 4))
             Set-Cursor (Get-Random -Min 2 -Max $maxX) (Get-Random -Min 2 -Max $maxY)
             Write-Host ($miniMsgs | Get-Random) -ForegroundColor Cyan
        }
        Start-Sleep -Milliseconds 50
    }
}

# --- MAIN EXECUTION ---
try {
    Clear-Host
    Write-Host "[Info] Video oynatılıyor..." -ForegroundColor DarkGray
    Play-BootSequence
    Write-Host "SYSTEM: Authenticating..." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 600
    Show-Access -Granted:((Get-Random)%2 -eq 0)
    if (-not $global:stopRequested) { Start-MatrixRain }
} finally {
    if ($IsWindows) { [Console]::ResetColor() }
    Clear-Host
    Write-Host "`nSession ended." -ForegroundColor Cyan
}
