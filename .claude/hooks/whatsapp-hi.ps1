# Claude Code hook: opens WhatsApp Web with a chat to the contact, "hi" typed in,
# and (if $AutoSend is on) presses Enter to send it once the page has loaded.
#
# The phone number is NOT stored in this file (it is committed to git).
# Put it in .claude/hooks/whatsapp-phone.local (gitignored), or set the
# WHATSAPP_PHONE environment variable. Country code, digits only, e.g. 919876543210.
#
# Auto-send is best effort: it focuses the browser window whose title contains
# "WhatsApp" and presses Enter. If the page loads slower than $SendDelaySeconds,
# the message may stay unsent in the box. It only presses Enter when the
# focused window really is the WhatsApp one, so it never types into another app.

param([switch]$SendNow)

$Message          = "Hi! (This is an auto-generated message.)"
$AutoSend         = $true
$SendDelaySeconds = 12     # time for WhatsApp Web to load the chat before pressing Enter

if ($SendNow) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class WaWin {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@
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
    if (-not $proc) { exit 0 }

    $shell = New-Object -ComObject WScript.Shell
    if (-not $shell.AppActivate($proc.Id)) { exit 0 }
    Start-Sleep -Milliseconds 800

    # Safety check: only press Enter if that exact browser window is focused
    # (a title match alone would also accept e.g. an editor showing this file).
    if ([WaWin]::GetForegroundWindow() -eq $proc.MainWindowHandle) {
        $shell.SendKeys('{ENTER}')
    }
    exit 0
}

# Claude Code sends hook details as JSON on stdin; read it so the pipe is drained.
$null = [Console]::In.ReadToEnd()

$Phone = $env:WHATSAPP_PHONE
$localFile = Join-Path $PSScriptRoot 'whatsapp-phone.local'
if (-not $Phone -and (Test-Path $localFile)) {
    $Phone = (Get-Content -Raw $localFile)
}

$digits = "$Phone" -replace '[^\d]', ''
if (-not $digits) {
    [Console]::Error.WriteLine("whatsapp-hi hook: put your number in .claude/hooks/whatsapp-phone.local or set WHATSAPP_PHONE")
    exit 0
}

$text = [uri]::EscapeDataString($Message)
Start-Process "https://web.whatsapp.com/send?phone=$digits&text=$text"

if ($AutoSend) {
    # Send in a detached, hidden process so the hook returns immediately
    # instead of blocking Claude Code while WhatsApp Web loads.
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"", '-SendNow'
    )
}
exit 0
