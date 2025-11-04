# ---------------------------
# sword_watchdogs_v4 - Part 1/3
# Helper functions, MP3 player, console save/restore
# SAVE THIS FILE AS UTF-8 BEFORE RUNNING
# ---------------------------

# Ensure proper UTF-8 for block characters and Turkish text
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Off

if ($null -eq $host.UI.RawUI.WindowSize) {
    Write-Warning "This script should be run inside PowerShell.exe or Windows Terminal."
    return
}

# ---------------------------
# Console helpers
# ---------------------------
function Set-Cursor {
    param([int]$X, [int]$Y)
    if ($X -ge 0 -and $X -lt $script:Width -and $Y -ge 0 -and $Y -lt $script:Height) {
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
    $startY = [Math]::Floor(([Math]::Max(0, $script:Height - $Lines.Length)) / 2)
    for ($i = 0; $i -lt $Lines.Length; $i++) {
        $line = $Lines[$i] -replace "`r",""
        # Truncate if longer than width to avoid positioning exception
        if ($line.Length -gt $script:Width) { $line = $line.Substring(0, $script:Width) }
        $startX = [Math]::Floor(([Math]::Max(0, $script:Width - $line.Length)) / 2)
        Set-Cursor $startX ($startY + $i)
        Write-Host $line -ForegroundColor $Color
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

# ---------------------------
# MP3 playback helpers (MediaPlayer)
# - Use ${fileName} interpolation to avoid parser issues
# ---------------------------
function Start-MP3 {
    param([string]$fileName, [switch]$Loop)
    $path = Join-Path $PSScriptRoot $fileName
    if (-not (Test-Path $path)) {
        Write-Warning "${fileName} not found in script folder."
        return $null
    }

    # Load PresentationCore once
    Add-Type -AssemblyName presentationCore

    $player = New-Object System.Windows.Media.MediaPlayer
    try {
        $player.Open([Uri]$path)
    } catch {
        Write-Warning "Failed to open ${fileName}: $_"
        return $null
    }

    if ($Loop) {
        # Register event to loop playback. We don't capture the subscription object here
        Register-ObjectEvent $player MediaEnded -Action {
            try { $this.Position = [TimeSpan]::Zero; $this.Play() } catch {}
        } | Out-Null
    }

    try { $player.Play() } catch { Write-Warning "Couldn't play ${fileName}: $_" }
    return $player
}

function Stop-MP3 {
    param($player)
    if ($null -ne $player) {
        try { $player.Stop() } catch {}
        try { $player.Close() } catch {}
        # Also try to unregister events - best effort (if we had stored them we'd remove explicit)
    }
}

# ---------------------------
# Simple glitch helper: randomly replace characters
# intensity = lower -> more glitches
# ---------------------------
function Glitch-Lines {
    param([string[]]$Lines, [int]$intensity = 8)
    if (-not $Lines) { return @() }
    $out = @()
    foreach ($L in $Lines) {
        $chars = $L.ToCharArray()
        for ($i = 0; $i -lt $chars.Length; $i++) {
            if ((Get-Random -Maximum $intensity) -eq 0) {
                # printable ascii substitution
                $chars[$i] = [char](Get-Random -Minimum 33 -Maximum 126)
            }
        }
        $out += (-join $chars)
    }
    return $out
}

# ---------------------------
# Save console state for restore in finally
# ---------------------------
$oldBG = $host.UI.RawUI.BackgroundColor
$oldFG = $host.UI.RawUI.ForegroundColor
try { $oldCursorVisible = $host.UI.RawUI.CursorVisible } catch { $oldCursorVisible = $true }

$script:Width = $host.UI.RawUI.WindowSize.Width
$script:Height = $host.UI.RawUI.WindowSize.Height

# ---------------------------
# Quick local test helper (prints debug only if env var set)
# ---------------------------
function Debug-Log {
    param([string]$msg)
    if ($env:SW_DEBUG -eq "1") {
        Write-Host "[DEBUG] $msg" -ForegroundColor DarkCyan
    }
}

# End of Part 1/3
Write-Host "Part 1/3 loaded. Next: Part 2/3 (frames & intro flow) incoming..." -ForegroundColor Cyan
# ---------------------------
# sword_watchdogs_v4 - Part 2/3
# Skull frames + intro animation flow (laugh sync + glitch)
# ---------------------------

# ASCII skull frames (each frame is an array of lines)
$skullFrame0 = @"
      ███████████████
   ████░░░░░░░░░░░░████
  ██░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░█▀▀▀▀▀▀▀▀█░░░░░░░██
██░░░░░█  ●  ●  █░░░░░░░██
██░░░░░█   ▄▄   █░░░░░░░██
██░░░░░█▄▄▄▄▄▄▄▄█░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
  ██░░░░░░░░░░░░░░░░░░██
   ████░░░░░░░░░░░░████
      ███████████████
"@ -split "`n"

$skullFrame1 = @"
      ███████████████
   ████░░░░░░░░░░░░████
  ██░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░█▀▀▀▀▀▀▀▀█░░░░░░░██
██░░░░░█  ●  ●  █░░░░░░░██
██░░░░░█   ▄    █░░░░░░░██
██░░░░░█▄▄▄▄▄▄▄▄█░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
  ██░░░░░░░░░░░░░░░░░░██
   ████░░░░░░░░░░░░████
      ███████████████
"@ -split "`n"

$skullFrame2 = @"
      ███████████████
   ████░░░░░░░░░░░░████
  ██░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░█▀▀▀▀▀▀▀▀█░░░░░░░██
██░░░░░█  ●  ●  █░░░░░░░██
██░░░░░█  ▄▄▄▄▄ █░░░░░░░██
██░░░░░█▄▄▄▄▄▄▄▄█░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
  ██░░░░░░░░░░░░░░░░░░██
   ████░░░░░░░░░░░░████
      ███████████████
"@ -split "`n"

$skullFrame3 = @"
      ███████████████
   ████░░░░░░░░░░░░████
  ██░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░░░░░██
██░░░░░█▀▀▀▀▀▀▀▀█░░░░░░░██
██░░░░░█  ●  ●  █░░░░░░░██
██░░░░░█   ▄    █░░░░░░░██
██░░░░░█▄▄▄▄▄▄▄▄█░░░░░░░██
██░░░░░░▀▀▀▀▀▀▀▀░░░░░░░░██
 ██░░░░░░░░░░░░░░░░░░░░██
  ██░░░░░░░░░░░░░░░░░░██
   ████░░░░░░░░░░░░████
      ███████████████
"@ -split "`n"

$skullFrames = @($skullFrame0, $skullFrame1, $skullFrame2, $skullFrame3)

# Defensive check
if (-not $skullFrames -or $skullFrames.Count -eq 0) {
    Write-Warning "Skull frames not loaded correctly. Aborting intro animation."
    return
}

# Intro animation flow
function Play-Intro {
    param(
        [int]$durationSeconds = 4
    )
    # Start laugh sound
    $introPlayer = Start-MP3 "sword_sound.mp3"
    $end = (Get-Date).AddSeconds($durationSeconds)

    while ((Get-Date) -lt $end) {
        # compute a wave index for smoother jaw movement
        $ms = (Get-Date).Millisecond
        $idx = [int]((($ms / 150) % 6))
        switch ($idx) {
            0 { $frame = $skullFrames[0] }
            1 { $frame = $skullFrames[1] }
            2 { $frame = $skullFrames[2] }
            3 { $frame = $skullFrames[3] }
            4 { $frame = $skullFrames[2] }
            default { $frame = $skullFrames[1] }
        }

        # eye flash occasionally
        $eyeColor = if ((Get-Random -Maximum 6) -eq 0) { "Red" } else { "DarkGray" }

        # sometimes glitch
        if ((Get-Random -Maximum 10) -lt 2) {
            $gl = Glitch-Lines $frame 6
            Write-Centered $gl $eyeColor 10
        } else {
            Write-Centered $frame $eyeColor 10
        }

        Start-Sleep -Milliseconds 110
        Clear-Host
    }

    # stop intro sound (if still playing)
    if ($introPlayer) { Stop-MP3 $introPlayer }
}

# Expose Intro function for the main flow (Part 3 will call Play-Intro)
Write-Host "Part 2/3 loaded: skull frames and Play-Intro() ready." -ForegroundColor Cyan
# ---------------------------
# sword_watchdogs_v4 - Part 3/3
# Final stage: access screen + matrix rain
# ---------------------------

# Show access effect (red for DENIED, green for GRANTED)
function Show-Access {
    param([switch]$Granted)

    $text = if ($Granted) { "ACCESS GRANTED" } else { "ACCESS DENIED" }
    $color = if ($Granted) { "Green" } else { "Red" }

    for ($i = 0; $i -lt 4; $i++) {
        $lines = Glitch-Lines (Split-Text $text 40) 4
        Write-Centered $lines $color 30
        Start-Sleep -Milliseconds 200
        Clear-Host
    }

    Write-Centered (Split-Text $text 40) $color
    Start-Sleep -Seconds 2
    Clear-Host
}

# Matrix Rain (same as before but cleaned)
function Start-MatrixRain {
    $charSet = @('0','1')
    $columns = @{}
    $maxColumns = [Math]::Max(1, [Math]::Floor($script:Width / 3))

    $rain = Start-MP3 "matrix_rain.mp3" -Loop

    while ($true) {
        $currentWidth = $host.UI.RawUI.WindowSize.Width
        $currentHeight = $host.UI.RawUI.WindowSize.Height
        if ($currentWidth -ne $script:Width -or $currentHeight -ne $script:Height) {
            $script:Width = $currentWidth
            $script:Height = $currentHeight
            Clear-Host
        }

        if ($columns.Count -lt $maxColumns -and (Get-Random -Maximum 10) -lt 4) {
            $x = Get-Random -Minimum 0 -Maximum $script:Width
            if (-not $columns.ContainsKey($x)) {
                $columns[$x] = [PSCustomObject]@{
                    YHead=0; YFade=0;
                    Length=Get-Random -Minimum ($script:Height/3) -Maximum ($script:Height-2);
                    Speed=Get-Random -Minimum 0 -Maximum 2;
                    Counter=0
                }
            }
        }

        $remove = @()
        foreach ($x in $columns.Keys) {
            $col = $columns[$x]
            if ($col.Counter -lt $col.Speed) { $col.Counter++; continue }
            $col.Counter = 0

            $c = $charSet[(Get-Random -Maximum $charSet.Count)]
            if ($col.YHead -lt $script:Height) {
                Set-Cursor $x $col.YHead
                [Console]::ForegroundColor="White"
                [Console]::Write($c)
            }

            $greenY = $col.YHead - 1
            if ($greenY -ge 0) {
                Set-Cursor $x $greenY
                [Console]::ForegroundColor="Green"
                [Console]::Write($charSet[(Get-Random -Maximum $charSet.Count)])
            }

            $darkY = $col.YHead - 2
            if ($darkY -ge 0) {
                Set-Cursor $x $darkY
                [Console]::ForegroundColor="DarkGreen"
                [Console]::Write($charSet[(Get-Random -Maximum $charSet.Count)])
            }

            if ($col.YHead -ge $col.Length) {
                if ($col.YFade -lt $script:Height) {
                    Set-Cursor $x $col.YFade
                    [Console]::Write(" ")
                }
                $col.YFade++
            }

            $col.YHead++
            if ($col.YFade -ge $script:Height) { $remove += $x }
        }

        foreach ($r in $remove) { $columns.Remove($r) }
        Start-Sleep -Milliseconds 35
    }
}

# === MAIN EXECUTION FLOW ===
try {
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "Green"
    try { $host.UI.RawUI.CursorVisible = $false } catch {}
    Clear-Host

    # Stage 1: Logo
    $logo = @"
M"""""`'"""`YM                   MP""""""`MM                                    dP 
M  mm.  mm.  M                   M  mmmmm..M                                    88 
M  MMM  MMM  M 88d888b.          M.      `YM dP  dP  dP .d8888b. 88d888b. .d888b88 
M  MMM  MMM  M 88'  `88 88888888 MMMMMMM.  M 88  88  88 88'  `88 88'  `88 88'  `88 
M  MMM  MMM  M 88                M. .MMM'  M 88.88b.88' 88.  .88 88       88.  .88 
M  MMM  MMM  M dP                Mb.     .dM 8888P Y8P  `88888P' dP       `88888P8 
MMMMMMMMMMMMMM                   MMMMMMMMMMM 
"@ -split "`n"
    Write-Centered $logo "White" 20
    Start-Sleep -Seconds 1
    Clear-Host

    # Stage 2: Quote
    $quote = "Man is least himself when he talks in his own person. Give him a mask, and he will tell you the truth. - Oscar Wilde"
    Write-Centered (Split-Text $quote ([int]($script:Width / 2))) "Green" 30
    Start-Sleep -Seconds 4
    Clear-Host

    # Stage 3: Laughing Skull
    Play-Intro -durationSeconds 5
    Clear-Host

    # Stage 4: Access Glitch
    if ((Get-Random -Maximum 10) -gt 4) {
        Show-Access -Granted
    } else {
        Show-Access
    }

    # Stage 5: Matrix rain (infinite)
    Start-MatrixRain

} finally {
    [Console]::ResetColor()
    $host.UI.RawUI.BackgroundColor = $oldBG
    $host.UI.RawUI.ForegroundColor = $oldFG
    try { $host.UI.RawUI.CursorVisible = $oldCursorVisible } catch {}
    Clear-Host
    Write-Host "`nCMatrix durduruldu. Konsol ayarları geri yüklendi." -ForegroundColor Cyan
}
