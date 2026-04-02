# HPD Tracker - Pure PowerShell HTTP Server (no Node/Python required)
$port = 8080
$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$url = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
$listener.Start()

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "   HPD Projects Tracker - PowerShell Server" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:$port/HPD_Tracker.html" -ForegroundColor Green
Write-Host "   Serving from: $folder" -ForegroundColor Gray
Write-Host "   Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
    ".svg"  = "image/svg+xml"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}

# Auto-open browser
Start-Process "http://localhost:$port/HPD_Tracker.html"

while ($listener.IsListening) {
    try {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        $rawPath = $req.Url.LocalPath
        if ($rawPath -eq "/") { $rawPath = "/HPD_Tracker.html" }

        $filePath = Join-Path $folder ($rawPath.TrimStart("/").Replace("/", "\"))

        if (Test-Path $filePath -PathType Leaf) {
            $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $resp.ContentType   = $mime
            $resp.ContentLength64 = $bytes.Length
            $resp.StatusCode    = 200
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
            Write-Host "  200 GET $rawPath" -ForegroundColor Green
        } else {
            $msg   = [System.Text.Encoding]::UTF8.GetBytes("404 - Not Found: $rawPath")
            $resp.StatusCode      = 404
            $resp.ContentType     = "text/plain"
            $resp.ContentLength64 = $msg.Length
            $resp.OutputStream.Write($msg, 0, $msg.Length)
            Write-Host "  404 GET $rawPath" -ForegroundColor Red
        }
        $resp.OutputStream.Close()
    } catch {
        # Graceful exit on Ctrl+C
        break
    }
}
$listener.Stop()
Write-Host "Server stopped." -ForegroundColor Yellow
