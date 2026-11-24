# Claude Code hook: opens WhatsApp Web with a chat to the contact and "hi" typed in.
# You press Enter (or click Send) to send it.
#
# The phone number is NOT stored in this file (it is committed to git).
# Put it in .claude/hooks/whatsapp-phone.local (gitignored), or set the
# WHATSAPP_PHONE environment variable. Country code, digits only, e.g. 919876543210.

$Message = "hi"

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
exit 0
