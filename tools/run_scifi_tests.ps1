[CmdletBinding()]
param(
    [ValidateSet('smoke','all','loadout','movement','weapons','evolutions','cards','skills','stages-boss','economy','save-faults','pool-stress','growth','visual-capture','assets-directions','feedback-audio','flow-compat','replay','collisions','menu-preview','menu-v3','menu-v3-motion','menu-v3-perf','ui-bounds')]
    [string]$Scenario = 'all',
    [int[]]$Seeds = @(17,41,73),
    [string]$GodotPath = '',
    [string]$OutputDirectory = '',
    [switch]$Headless,
    [switch]$ParallelGrowth,
    [ValidatePattern('^\d+x\d+$')]
    [string]$Resolution = '1920x1080',
    [int]$TimeoutSeconds = 14400
)
$ErrorActionPreference = 'Stop'
$repoPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $GodotPath) {
    $engineCommand = Get-Command 'Godot*_console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $engineCommand) { $engineCommand = Get-Command 'godot_console' -ErrorAction SilentlyContinue }
    if (-not $engineCommand) { throw 'Godot console executable unavailable; specify -GodotPath.' }
    $GodotPath = $engineCommand.Source
}
$GodotPath = [System.IO.Path]::GetFullPath($GodotPath)
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw "Engine missing: $GodotPath" }
if (-not $OutputDirectory) {
    $sessionName = '{0}-{1}-{2}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'),$Scenario,([guid]::NewGuid().ToString('N').Substring(0,8))
    $OutputDirectory = Join-Path $repoPath "reports/scifi-tests/$sessionName"
}
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
if ($Scenario -ne 'growth') { $Seeds = @($Seeds[0]) }
if ($ParallelGrowth -and ([System.IO.Path]::GetExtension($GodotPath) -ne '.exe')) {
    throw '-ParallelGrowth requires the actual Godot console .exe, not a cmd wrapper.'
}

$jobs = [System.Collections.Generic.List[object]]::new()
$sourceFiles = @('project.godot','scenes/Main.tscn','tools/run_scifi_tests.ps1','spec/20261017_LegendarySurvivor_Scifi_v0.2.md','docs/20261017_LegendarySurvivor_ScifiTestCases_v0.2.md')
$sourceFiles += @(Get-ChildItem -LiteralPath (Join-Path $repoPath 'scripts/scifi') -Filter '*.gd' -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($repoPath,$_.FullName).Replace('\','/') })
$sourceHashes = [ordered]@{}
foreach ($relativePath in $sourceFiles) { $sourceHashes[$relativePath] = (Get-FileHash -LiteralPath (Join-Path $repoPath $relativePath) -Algorithm SHA256).Hash.ToLowerInvariant() }
foreach ($seedValue in $Seeds) {
    $stem = '{0}-seed-{1}' -f $Scenario,$seedValue
    $savePath = Join-Path $OutputDirectory "$stem-save"
    $reportPath = Join-Path $OutputDirectory "$stem.json"
    $stdoutPath = Join-Path $OutputDirectory "$stem.stdout.log"
    $stderrPath = Join-Path $OutputDirectory "$stem.stderr.log"
    if (Test-Path -LiteralPath $savePath) { throw "Refusing to reuse isolated save directory: $savePath" }
    [System.IO.Directory]::CreateDirectory($savePath) | Out-Null
    $engineArgs = @('--path',$repoPath,'--log-file',(Join-Path $OutputDirectory "$stem.engine.log"))
    if ($Headless) { $engineArgs += '--headless' }
    else { $engineArgs += @('--resolution',$Resolution) }
    $engineArgs += @('--',"--scifi-test=$Scenario","--scifi-report=$reportPath","--scifi-save=$savePath","--seed=$seedValue")
    $invocation = [ordered]@{ engine=$GodotPath; engine_sha256=(Get-FileHash -LiteralPath $GodotPath -Algorithm SHA256).Hash.ToLowerInvariant(); arguments=$engineArgs; scenario=$Scenario; seed=$seedValue; isolated_save=$savePath; isolated_save_initial_files=@(Get-ChildItem -LiteralPath $savePath -File); source_hashes=$sourceHashes; report=$reportPath; started_utc=[DateTime]::UtcNow.ToString('o'); headless=[bool]$Headless; resolution= $(if ($Headless) { $null } else { $Resolution }); policy='T16 frozen 20261017; complete matrix required; existing saves are refused; GPU evidence is natural only in growth' }
    $invocation | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory "$stem.invocation.json") -Encoding utf8
    Write-Host "Starting $stem; report=$reportPath"
    if ([System.IO.Path]::GetExtension($GodotPath) -eq '.exe') {
        # ProcessStartInfo.ArgumentList preserves spaces without shell-built commands.
        $processInfo = [Diagnostics.ProcessStartInfo]::new()
        $processInfo.FileName = $GodotPath
        $processInfo.WorkingDirectory = $repoPath
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        foreach ($argument in $engineArgs) { $processInfo.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $processInfo
        [void]$process.Start()
        $jobEntry = [pscustomobject]@{ Process=$process; Stdout=$process.StandardOutput.ReadToEndAsync(); Stderr=$process.StandardError.ReadToEndAsync(); StdoutPath=$stdoutPath; StderrPath=$stderrPath; Report=$reportPath; Seed=$seedValue; Started=[DateTime]::UtcNow; EngineLog=(Join-Path $OutputDirectory "$stem.engine.log") }
        $jobs.Add($jobEntry)
        if (-not $ParallelGrowth) {
            while (-not $process.WaitForExit(1000)) {
                $scriptFailed = (Test-Path -LiteralPath $jobEntry.EngineLog) -and ((Get-Content -LiteralPath $jobEntry.EngineLog -Raw) -match 'SCRIPT ERROR:')
                if ($scriptFailed -or ([DateTime]::UtcNow-$jobEntry.Started).TotalSeconds -gt $TimeoutSeconds) {
                    $process.Kill($true)
                    $process.WaitForExit()
                    [System.IO.File]::WriteAllText($stdoutPath,$jobEntry.Stdout.GetAwaiter().GetResult())
                    [System.IO.File]::WriteAllText($stderrPath,$jobEntry.Stderr.GetAwaiter().GetResult())
                    throw "Run interrupted by script error or watchdog; evidence retained at $OutputDirectory"
                }
            }
        }
    } else {
        & $GodotPath @engineArgs 1> $stdoutPath 2> $stderrPath
        $jobs.Add([pscustomobject]@{ ExitCode=$LASTEXITCODE; Report=$reportPath; Seed=$seedValue })
    }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($job in $jobs) {
    if ($job.PSObject.Properties.Name -contains 'Process') {
        while (-not $job.Process.WaitForExit(1000)) {
            if (([DateTime]::UtcNow-$job.Started).TotalSeconds -gt $TimeoutSeconds) {
                $job.Process.Kill($true)
                throw "Acceptance run timed out without synthetic result; seed=$($job.Seed), evidence retained at $OutputDirectory"
            }
        }
        [System.IO.File]::WriteAllText($job.StdoutPath,$job.Stdout.GetAwaiter().GetResult())
        [System.IO.File]::WriteAllText($job.StderrPath,$job.Stderr.GetAwaiter().GetResult())
        $exitCode = $job.Process.ExitCode
        $job.Process.Dispose()
    } else { $exitCode = $job.ExitCode }
    if (-not (Test-Path -LiteralPath $job.Report -PathType Leaf)) {
        $results.Add([pscustomobject]@{ seed=$job.Seed; passed=$false; exit_code=$exitCode; error='No report produced'; report=$job.Report })
        continue
    }
    $report = Get-Content -LiteralPath $job.Report -Raw | ConvertFrom-Json
    $firstWin = 0
    foreach ($note in $report.notes) { if ($note -match '^first_win_run=(\d+)$') { $firstWin=[int]$Matches[1] } }
    $results.Add([pscustomobject]@{ seed=$job.Seed; passed=($exitCode -eq 0 -and [int]$report.failed -eq 0); exit_code=$exitCode; failed_assertions=[int]$report.failed; first_win_run=$firstWin; report=$job.Report; acceptance_status=$report.acceptance_status })
}
$matrixPassed = @($results | Where-Object { -not $_.passed }).Count -eq 0
$median = $null
$fullGrowthMatrix = $Scenario -eq 'growth' -and (@($Seeds | Sort-Object -Unique) -join ',') -eq '17,41,73'
if ($Scenario -eq 'growth') {
    $wins = @($results | ForEach-Object { [int]$_.first_win_run } | Sort-Object)
    if ($fullGrowthMatrix -and $wins.Count -eq 3) {
        $median=$wins[1]
        $matrixPassed=$matrixPassed -and $wins[0] -ge 1 -and $wins[2] -le 5 -and $median -ge 3 -and $median -le 5
    } else { $matrixPassed=$false }
}
$aggregate = [ordered]@{ scenario=$Scenario; engine=$GodotPath; results=@($results); logic_matrix_passed=$matrixPassed; full_growth_matrix=$fullGrowthMatrix; first_win_median=$median; acceptance_status='partially_verified'; limitation='Runtime visuals, sound, old-save compatibility, filesystem faults and independent reviewers require their separately recorded evidence. Automated movement reads internal positions and does not establish human difficulty or fun.'; completed_utc=[DateTime]::UtcNow.ToString('o') }
$aggregatePath = Join-Path $OutputDirectory 'matrix.json'
$aggregate | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $aggregatePath -Encoding utf8
Write-Host "Matrix: $aggregatePath; logic_matrix_passed=$matrixPassed"
if (-not $matrixPassed) { exit 1 }
exit 0
