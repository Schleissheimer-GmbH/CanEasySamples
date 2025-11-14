
$pythonurl = "https://www.python.org/ftp/python/3.13.9/python-3.13.9-embed-amd64.zip"
$pythonzip = "python_embedded.zip"
$pipurl = "https://bootstrap.pypa.io/get-pip.py"
$getpippy = "get-pip.py"
$rename = "python313._pth"
$installdir = ".\python"
$venvdir = ".\.venv"

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

Write-Host ":"
Write-Host ": *** Embedded Python installer ***"
Write-Host ":"
if (Test-Path -LiteralPath $installdir) {
    $Confirm = Read-Host ": $installdir already exists. Overwrite? [y/n]"
    if ($Confirm -ne "y") {
        Write-Host ": ERROR Failed deleting $installdir" -ForegroundColor red -BackgroundColor white
        exit 1
    }

    Write-Host ": Deleting $installdir"
    Remove-Item -LiteralPath $installdir -Force -Recurse
    if (-not $?)
    {
        Write-Host ": ERROR Failed deleting $installdir" -ForegroundColor red -BackgroundColor white
        exit 1
    }
    
    Write-Host ": Deleting $venvdir"
    Remove-Item -LiteralPath $venvdir -Force -Recurse
    if (-not $?)
    {
        Write-Host ": ERROR Failed deleting $venvdir" -ForegroundColor red -BackgroundColor white
        exit 1
    }
}

Write-Host ": Downloading $pythonurl"
$response = Invoke-WebRequest -UserAgent "Wget" -Uri $pythonurl -OutFile $pythonzip -PassThru
if ( $response.StatusCode -ne 200 )
{
    Write-Host ": ERROR Failed downloading $pythonurl" -ForegroundColor red -BackgroundColor white
    exit 1
}

Write-Host ": Extracting $pythonzip"
Expand-Archive -Path "$pythonzip" -DestinationPath ".\python"
if (-not $?) {
    Write-Host ": ERROR Extracting $pythonzip" -ForegroundColor red -BackgroundColor white
    exit 1
}

Set-Location -Path $installdir -PassThru

Write-Host ": Downloading $getpippy"
Invoke-WebRequest -UserAgent "Wget" -Uri $pipurl -OutFile $getpippy

$newname =  $rename + '_renamed'

Write-Host ": Renameing $rename to $newname"
Rename-Item -Path $rename -NewName $newname

Write-Host ": Installing $getpippy"
& ".\python.exe" $getpippy --no-warn-script-location --no-cache-dir
if (-not $?) {
    Write-Host ": ERROR Failed installing $getpippy" -ForegroundColor red -BackgroundColor white
    exit 1
}

Write-Host ": Installing module virtualenv"
& ".\scripts\pip.exe" install virtualenv --no-warn-script-location --no-cache-dir
if (-not $?) {
    Write-Host ": ERROR Installing module virtualenv" -ForegroundColor red -BackgroundColor white
    exit 1
}

Write-Host ": Creating venv"
Set-Location -Path ".."
$temppath = $installdir + "\python.exe"
& $temppath -m virtualenv $venvdir

Write-Host ": Activating venv"
$temppath = $venvdir + "\Scripts\activate.ps1"
& $temppath

Write-Host ": Installing modules from requirements.txt"
& "pip.exe" install --requirement .\requirements.txt --no-warn-script-location --no-cache-dir
if (-not $?) {
    Write-Host ": ERROR Installing modules from requirements.txt" -ForegroundColor red -BackgroundColor white
    exit 1
}

Write-Host ": Removing $pythonzip"
Remove-Item -LiteralPath $pythonzip -Force -Recurse
if (-not $?)
{
    Write-Host ": ERROR Failed deleting $pythonzip" -ForegroundColor red -BackgroundColor white
    exit 1
}

Write-Host ': Finished'
exit 0
