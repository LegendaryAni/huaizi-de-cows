# 只使用事前核准的 T16 三種子、配裝與策略；不修改任何遊戲或驗收門檻。
[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [switch]$Headless,
    [int]$TimeoutSeconds = 14400,
    [switch]$VerifyOnly
)
$ErrorActionPreference = 'Stop'
$seeds = [int[]]@(17, 41, 73)
if (($seeds -join ',') -ne '17,41,73') {
    throw 'SF-16 locked seed set mismatch; refusing to run.'
}
Write-Host ('SF16_LOCKED_SEEDS=' + ($seeds -join ','))
if ($VerifyOnly) {
    Write-Host 'SF16_VERIFY_ONLY: no game process started.'
    return
}
$runner = Join-Path $PSScriptRoot 'run_scifi_tests.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw 'Missing official SF-16 acceptance runner.'
}
# PowerShell -File 不能保證從字串 17,41,73 綁定成三個 int；
# 由本檔原生陣列傳入，避免被誤讀成一個 174173 種子。
$arguments = @{
    Scenario = 'growth'
    Seeds = $seeds
    ParallelGrowth = $true
    TimeoutSeconds = $TimeoutSeconds
}
if ($GodotPath) { $arguments.GodotPath = $GodotPath }
if ($Headless) { $arguments.Headless = $true }
& $runner @arguments
if ($LASTEXITCODE -ne 0) {
    throw ('SF-16 run failed with exit code ' + $LASTEXITCODE)
}
