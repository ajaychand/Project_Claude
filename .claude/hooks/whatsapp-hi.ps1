# Claude Code hook: opens WhatsApp Web with a chat to the contact and "hi" typed in.
# You press Enter (or click Send) to send it.

$Phone   = "PHONE_NUMBER"   # country code, no + or spaces, e.g. 919876543210
$Message = "hi"

# Claude Code sends hook details as JSON on stdin; read it so the pipe is drained.
$null = [Console]::In.ReadToEnd()

$digits = $Phone -replace '[^\d]', ''
if (-not $digits) {
    [Console]::Error.WriteLine("whatsapp-hi hook: set `$Phone in .claude/hooks/whatsapp-hi.ps1")
    exit 0
}

$text = [uri]::EscapeDataString($Message)
Start-Process "https://web.whatsapp.com/send?phone=$digits&text=$text"
exit 0
