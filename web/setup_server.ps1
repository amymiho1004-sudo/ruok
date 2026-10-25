Set-Location $PSScriptRoot

if (!(Test-Path ".\.venv")) {
  python -m venv .venv
}

.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python setup_db.py

Write-Host ""
Write-Host "Setup complete."
Write-Host "Run server with:"
Write-Host "  .\run_server.ps1"
