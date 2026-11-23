# Claude Code Notification hook.
# Shows a Windows message box when Claude Code needs your attention.
# Claude Code sends the hook input as JSON on stdin; the "message" field holds the notification text.

$message = 'Claude Code needs your attention'

try {
    $raw = [Console]::In.ReadToEnd()
    if ($raw) {
        $data = $raw | ConvertFrom-Json
        if ($data.message) { $message = $data.message }
    }
} catch {
    # Fall back to the default message if stdin is empty or not valid JSON.
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show($message, 'Claude Code') | Out-Null
