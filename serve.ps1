$prefix = "http://127.0.0.1:8877/"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$file = Join-Path $root "web\designer.html"
if (-not (Test-Path $file)) {
  Write-Host "Missing $file"
  exit 1
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
  $listener.Start()
} catch {
  Write-Host "Could not listen on $prefix"
  Write-Host "Run this once in an elevated PowerShell, then start the server again:"
  Write-Host "netsh http add urlacl url=http://127.0.0.1:8877/ user=$env:USERNAME"
  exit 1
}
Write-Host "abapPDF designer at $prefix"
try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $context.Response.StatusCode = 200
    $context.Response.ContentType = "text/html; charset=utf-8"
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
  }
} finally {
  $listener.Stop()
}
