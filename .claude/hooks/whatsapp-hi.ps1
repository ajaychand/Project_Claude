# Claude Code hook: opens a WhatsApp Web chat to each contact with $Message typed in,
# and (if $AutoSend is on) presses Enter to send it once the chat has loaded.
#
# Phone numbers are NOT stored in this file (it is committed to git).
# Put them in .claude/hooks/whatsapp-phone.local (gitignored), one per line,
# or set WHATSAPP_PHONE to a comma-separated list. Include the country code,
# e.g. 919876543210 (a leading + and spaces are fine).
#
# Auto-send is best effort: for each contact it opens the chat, waits
# $SendDelaySeconds, focuses the browser window showing WhatsApp and presses
# Enter. If the page loads slower than that, the message may stay unsent in the
# box. Enter is only pressed when that exact browser window is in the
# foreground, so it never types into another app.

param([switch]$SendNow, [string]$Numbers)

$Message          = "Hi! (This is an auto-generated message.)"
$AutoSend         = $true
$SendDelaySeconds = 12     # time for WhatsApp Web to load the chat before pressing Enter

function Open-Chat([string]$digits) {
    $text = [uri]::EscapeDataString($Message)
    Start-Process "https://web.whatsapp.com/send?phone=$digits&text=$text"
}

if ($SendNow) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WaWin {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@
    $shell = New-Object -ComObject WScript.Shell

    # One contact at a time: each chat opens as the active tab, gets sent,
    # then the next one opens.
    foreach ($digits in ($Numbers -split ',' | Where-Object { $_ })) {
        Open-Chat $digits
        Start-Sleep -Seconds $SendDelaySeconds

        # Wait up to 30 more seconds for a browser window showing WhatsApp Web.
        $deadline = (Get-Date).AddSeconds(30)
        $proc = $null
        while (-not $proc -and (Get-Date) -lt $deadline) {
            $proc = Get-Process -ErrorAction SilentlyContinue |
                Where-Object { $_.MainWindowTitle -match 'WhatsApp' -and $_.ProcessName -match 'firefox|chrome|msedge|brave|opera' } |
                Select-Object -First 1
            if (-not $proc) { Start-Sleep -Seconds 1 }
        }
        if (-not $proc) { continue }

        if (-not $shell.AppActivate($proc.Id)) { continue }
        Start-Sleep -Milliseconds 800

        # Safety check: only press Enter if that exact browser window is focused
        # (a title match alone would also accept e.g. an editor showing this file).
        if ([WaWin]::GetForegroundWindow() -eq $proc.MainWindowHandle) {
            $shell.SendKeys('{ENTER}')
        }
        Start-Sleep -Seconds 2   # let the send go through before opening the next chat
    }
    exit 0
}

# Claude Code sends hook details as JSON on stdin; read it so the pipe is drained.
$null = [Console]::In.ReadToEnd()

$raw = $env:WHATSAPP_PHONE
$localFile = Join-Path $PSScriptRoot 'whatsapp-phone.local'
if (-not $raw -and (Test-Path $localFile)) {
    $raw = Get-Content -Raw $localFile
}

# Split on newlines/commas/semicolons, then keep only the digits of each entry.
$list = @("$raw" -split '[,;\r\n]+' |
    ForEach-Object { $_ -replace '[^\d]', '' } |
    Where-Object { $_ })

if ($list.Count -eq 0) {
    [Console]::Error.WriteLine("whatsapp-hi hook: put numbers in .claude/hooks/whatsapp-phone.local (one per line) or set WHATSAPP_PHONE")
    exit 0
}

if ($AutoSend) {
    # Open and send in a detached, hidden process so the hook returns
    # immediately instead of blocking Claude Code while WhatsApp Web loads.
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"", '-SendNow', '-Numbers', ($list -join ',')
    )
} else {
    foreach ($digits in $list) { Open-Chat $digits }
}
exit 0
