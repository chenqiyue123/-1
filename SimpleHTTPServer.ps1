# Simple HTTP Server in PowerShell
# Usage: powershell -File SimpleHTTPServer.ps1

param(
    [int]$Port = 8000,
    [string]$Path = "."
)

$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
$Listener.Start()

Write-Host "Simple HTTP Server running at http://localhost:$Port/" -ForegroundColor Green
Write-Host "Serving files from: $Path" -ForegroundColor Yellow
Write-Host "Press [CTRL+C] to stop the server" -ForegroundColor Red

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        # Get the requested file path
        $RelativePath = [System.Web.HttpUtility]::UrlDecode($Request.Url.AbsolutePath.TrimStart('/'))
        $FilePath = Join-Path $Path $RelativePath

        # Handle directory requests
        if ($FilePath.EndsWith('\') -or !(Test-Path $FilePath)) {
            $IndexFiles = @('index.html', 'index.htm', 'default.html', 'default.htm')
            foreach ($IndexFile in $IndexFiles) {
                $IndexPath = Join-Path $FilePath $IndexFile
                if (Test-Path $IndexPath -PathType Leaf) {
                    $FilePath = $IndexPath
                    break
                }
            }
        }

        # Check if file exists
        if (Test-Path $FilePath -PathType Leaf) {
            # Read file content
            $Content = [System.IO.File]::ReadAllBytes($FilePath)
            
            # Set response content and status
            $Response.ContentLength64 = $Content.Length
            $Response.OutputStream.Write($Content, 0, $Content.Length)
        } else {
            # File not found
            $Response.StatusCode = 404
            $Response.StatusDescription = "File Not Found"
            $NotFoundContent = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found")
            $Response.ContentLength64 = $NotFoundContent.Length
            $Response.OutputStream.Write($NotFoundContent, 0, $NotFoundContent.Length)
        }

        $Response.Close()
    }
} finally {
    $Listener.Stop()
    $Listener.Close()
}