$csvLogging = "C:\Users\xx\xx\LogFile.txt"

function WriteLog{    
    Param ([string]$logString)
    $dateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    if (-not (Test-Path -Path $csvLogging)) {Add-Content -Path $csvLogging -Value "Start CAL Contacts FuncNum Logging"}
    Add-content $csvLogging -value "$datetime $logString"
}

$benchmark = [System.Diagnostics.Stopwatch]::StartNew()
WriteLog('-------------------------------------------')
WriteLog("[INIT] Script start run")
WriteLog('-------------------------------------------')


# Your script here


$benchmark.Stop()
$t = $benchmark.Elapsed.ToString("dd\.hh\:mm\:ss\.ff")
WriteLog("[Benchmark] $($t) (DD/HH/MM/SS/MS)")
WriteLog('-------------------------------------------')
