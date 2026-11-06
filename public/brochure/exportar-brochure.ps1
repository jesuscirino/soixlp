# ==============================================================================
# exportar-brochure.ps1 - SOIX Solutions - Exportar Brochure a PDF
# Levanta su propio servidor Node.js y genera el PDF con Chrome headless.
# No requiere Live Server ni ningun otro programa adicional.
# ==============================================================================
# USO: Doble clic en este archivo -O- en PowerShell: .\exportar-brochure.ps1
# ==============================================================================

$chrome     = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$puerto     = 5599
$url        = "http://localhost:$puerto/index.html"
$outputDir  = $PSScriptRoot
$fileName   = "SOIX-Brochure-Corporativo-2026.pdf"
$outputPath = Join-Path $outputDir $fileName

# --- Verificar Chrome ---
if (-not (Test-Path $chrome)) {
    Write-Host "ERROR: No se encontro Chrome en: $chrome" -ForegroundColor Red
    pause; exit 1
}

# --- Verificar Node.js ---
$nodeVersion = node --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Node.js no esta instalado. Descargalo en https://nodejs.org" -ForegroundColor Red
    pause; exit 1
}
Write-Host "OK Node.js $nodeVersion detectado." -ForegroundColor Green

# --- Escribir el servidor Node.js en archivo temporal ---
$tempScript = Join-Path $env:TEMP "soix_server.js"
$tempOut    = Join-Path $env:TEMP "soix_srv_out.txt"

$nodeCode = @'
const http = require('http');
const fs   = require('fs');
const path = require('path');
const root = process.argv[2];
const port = parseInt(process.argv[3], 10);
const mime = {
  '.html' : 'text/html',
  '.css'  : 'text/css',
  '.js'   : 'application/javascript',
  '.png'  : 'image/png',
  '.jpg'  : 'image/jpeg',
  '.jpeg' : 'image/jpeg',
  '.JPG'  : 'image/jpeg',
  '.jfif' : 'image/jpeg',
  '.webp' : 'image/webp',
  '.svg'  : 'image/svg+xml',
  '.gif'  : 'image/gif',
  '.woff2': 'font/woff2',
  '.woff' : 'font/woff'
};
http.createServer(function(req, res) {
  var filePath = path.join(root, decodeURIComponent(req.url.split('?')[0]));
  if (filePath.endsWith('/') || filePath === root) filePath = path.join(root, 'index.html');
  fs.readFile(filePath, function(err, data) {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    var ext  = path.extname(filePath);
    var type = mime[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': type, 'Access-Control-Allow-Origin': '*' });
    res.end(data);
  });
}).listen(port, '127.0.0.1', function() {
  process.stdout.write('READY\n');
});
'@

[System.IO.File]::WriteAllText($tempScript, $nodeCode, [System.Text.Encoding]::UTF8)

# --- Levantar servidor ---
Write-Host "Levantando servidor local en puerto $puerto ..." -ForegroundColor Cyan

$serverProc = Start-Process -FilePath "node" `
    -ArgumentList "`"$tempScript`"", "`"$outputDir`"", "$puerto" `
    -PassThru -NoNewWindow

# Esperar hasta 8 s verificando por TCP (mas rapido que HTTP para archivos grandes)
$ready = $false
for ($i = 0; $i -lt 16; $i++) {
    Start-Sleep -Milliseconds 500
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", $puerto)
        $tcp.Close()
        $ready = $true; break
    } catch { }
}

if (-not $ready) {
    Write-Host "ERROR: El servidor no arranco. Revisa que Node.js funcione." -ForegroundColor Red
    $serverProc | Stop-Process -Force -ErrorAction SilentlyContinue
    pause; exit 1
}
Write-Host "OK Servidor activo en $url" -ForegroundColor Green

# --- Eliminar PDF anterior ---
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Force
    Write-Host "PDF anterior eliminado." -ForegroundColor DarkGray
}

# --- Generar PDF con Chrome headless ---
Write-Host ""
Write-Host "Generando PDF con Chrome headless..." -ForegroundColor Cyan
Write-Host "    Destino: $outputPath"
Write-Host ""

$chromeArgs = @(
    "--headless=new",
    "--disable-gpu",
    "--no-sandbox",
    "--print-to-pdf=`"$outputPath`"",
    "--print-to-pdf-no-header",
    "--no-margins",
    "--run-all-compositor-stages-before-draw",
    "--virtual-time-budget=6000",
    $url
)

Start-Process -FilePath $chrome -ArgumentList $chromeArgs -Wait -NoNewWindow

# --- Apagar servidor y limpiar ---
$serverProc | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

# --- Resultado ---
Write-Host ""
if ((Test-Path $outputPath) -and ((Get-Item $outputPath).Length -gt 10240)) {
    $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
    Write-Host "PDF generado exitosamente:" -ForegroundColor Green
    Write-Host "    $outputPath" -ForegroundColor White
    Write-Host "    Tamano: $size MB" -ForegroundColor DarkGray
    Write-Host ""
    $abrir = Read-Host "Abrir el PDF ahora? (S/N)"
    if ($abrir -match "^[Ss]") { Start-Process $outputPath }
} else {
    Write-Host "ERROR: El PDF no se genero o esta vacio." -ForegroundColor Red
    Write-Host "Asegurate de que index.html abre bien en el navegador." -ForegroundColor Yellow
}

Write-Host ""
pause
