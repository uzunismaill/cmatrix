<#
.SYNOPSIS
    Professional CMatrix effect with ASCII MR.SWORD logo, Oscar Wilde quote, and Matrix rain.
#>

Set-StrictMode -Off

# Konsol uygunluğu kontrolü
if ($null -eq $host.UI.RawUI.WindowSize) {
    Write-Warning "This script only runs in a real console host (PowerShell.exe or Windows Terminal)."
    return
}

# --- Yardımcı Fonksiyonlar ---
function Set-Cursor {
    param([int]$X, [int]$Y)
    if ($X -ge 0 -and $X -lt $script:Width -and $Y -ge 0 -and $Y -lt $script:Height) {
        $host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates ($X, $Y)
    }
}

function Write-Centered {
    param([string[]]$Lines, [string]$Color = "White")
    $totalHeight = $Lines.Length
    $startY = [Math]::Floor(($script:Height - $totalHeight) / 2)
    for ($i = 0; $i -lt $Lines.Length; $i++) {
        $line = $Lines[$i]
        $startX = [Math]::Floor(($script:Width - $line.Length) / 2)
        Set-Cursor $startX ($startY + $i)
        Write-Host $line -ForegroundColor $Color
    }
}

function Split-Text {
    param([string]$Text, [int]$LineWidth)
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

# --- Ayarları kaydet ---
$oldBG = $host.UI.RawUI.BackgroundColor
$oldFG = $host.UI.RawUI.ForegroundColor
try { $oldCursorVisible = $host.UI.RawUI.CursorVisible } catch { $oldCursorVisible = $true }

$script:Width = $host.UI.RawUI.WindowSize.Width
$script:Height = $host.UI.RawUI.WindowSize.Height

try {
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "Green"
    try { $host.UI.RawUI.CursorVisible = $false } catch {}

    Clear-Host

    # --- MR.SWORD LOGOSU ---
    $logo = @"
M"""""`'"""`YM                   MP""""""`MM                                    dP 
M  mm.  mm.  M                   M  mmmmm..M                                    88 
M  MMM  MMM  M 88d888b.          M.      `YM dP  dP  dP .d8888b. 88d888b. .d888b88 
M  MMM  MMM  M 88'  `88 88888888 MMMMMMM.  M 88  88  88 88'  `88 88'  `88 88'  `88 
M  MMM  MMM  M 88                M. .MMM'  M 88.88b.88' 88.  .88 88       88.  .88 
M  MMM  MMM  M dP                Mb.     .dM 8888P Y8P  `88888P' dP       `88888P8 
MMMMMMMMMMMMMM                   MMMMMMMMMMM                                       
"@ -split "`n"

    Write-Centered -Lines $logo -Color "White"
    Start-Sleep -Seconds 3
    Clear-Host

    # --- OSCAR WILDE QUOTE ---
    $quote = "Man is least himself when he talks in his own person. Give him a mask, and he will tell you the truth. - Oscar Wilde"
    $quoteLines = Split-Text -Text $quote -LineWidth ([int]($script:Width / 2))
    Write-Centered -Lines $quoteLines -Color "Green"
    Start-Sleep -Seconds 5
    Clear-Host

    # --- MATRIX RAIN ---
    $charList = New-Object System.Collections.Generic.List[string]
    $charList.Add('0')
    $charList.Add('1')
    # Katakana karakterleri ekle
    0x30A0..0x30FF | ForEach-Object {
        try { $charList.Add([char]$_) } catch {}
    }
    # Ek olarak bazı semboller (UTF-8 uyumsuz konsollar için)
    $extra = @('#', '$', '%', '&', '@')
    foreach ($e in $extra) { $charList.Add($e) }

    $charSet = $charList.ToArray()
    $columns = @{}
    $maxColumns = [Math]::Max(1, [Math]::Floor($script:Width / 4))

    while ($true) {
        # Konsol boyutu değiştiyse ayarla
        $currentWidth = $host.UI.RawUI.WindowSize.Width
        $currentHeight = $host.UI.RawUI.WindowSize.Height
        if ($currentWidth -ne $script:Width -or $currentHeight -ne $script:Height) {
            $script:Width = $currentWidth
            $script:Height = $currentHeight
            $maxColumns = [Math]::Max(1, [Math]::Floor($script:Width / 4))
            Clear-Host
        }

        # Yeni sütun oluştur
        if ($columns.Count -lt $maxColumns -and (Get-Random -Maximum 10) -lt 4) {
            $x = Get-Random -Minimum 0 -Maximum $script:Width
            if (-not $columns.ContainsKey($x)) {
                $columns[$x] = [PSCustomObject]@{
                    YHead = 0
                    YFade = 0
                    Length = Get-Random -Minimum ($script:Height / 3) -Maximum ($script:Height - 2)
                    Speed = Get-Random -Minimum 0 -Maximum 2
                    Counter = 0
                }
            }
        }

        # Her sütunu işle
        $remove = @()
        foreach ($x in $columns.Keys) {
            $col = $columns[$x]
            if ($col.Counter -lt $col.Speed) {
                $col.Counter++
                continue
            }
            $col.Counter = 0

            $randomChar = $charSet[(Get-Random -Maximum $charSet.Count)]
            if ($col.YHead -lt $script:Height) {
                Set-Cursor $x $col.YHead
                [Console]::ForegroundColor = "White"
                [Console]::Write($randomChar)
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
        Start-Sleep -Milliseconds 30
    }

}
finally {
    [Console]::ResetColor()
    $host.UI.RawUI.BackgroundColor = $oldBG
    $host.UI.RawUI.ForegroundColor = $oldFG
    try { $host.UI.RawUI.CursorVisible = $oldCursorVisible } catch {}
    Clear-Host
    Write-Host "CMatrix stopped. Console settings restored."
}
