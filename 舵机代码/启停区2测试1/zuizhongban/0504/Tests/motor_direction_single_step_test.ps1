$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$hmiHeader = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Inc\hmi.h') -Raw
$hmiSource = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Src\hmi.c') -Raw
$taskSource = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Src\task.c') -Raw
$moveHeader = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Inc\move.h') -Raw
$moveSource = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Src\move.c') -Raw

function Assert-Match([string]$Text, [string]$Pattern, [string]$Message) {
    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

Assert-Match $hmiHeader '#define\s+MOTOR_DIRECTION_TEST_ENABLE\s+[01]' '缺少可回滚的电机方向测试编译开关。'
Assert-Match $hmiHeader '#define\s+MOTOR_DIRECTION_TEST_DISTANCE_CM\s+41' '单次测试距离不是41cm。'
Assert-Match $hmiSource 'g_motor_test_pending\s*=\s*1' '##test没有登记单次测试请求。'
Assert-Match $hmiSource 'uint8_t\s+Hmi_MotorDirectionTestProcess\s*\(void\)' '缺少主循环电机测试处理函数。'
Assert-Match $moveHeader 'void\s+RunMoveDistanceTest\s*\(uint8_t\s+dir,\s*uint16_t\s+distance\)' '缺少纯距离测试接口声明。'
Assert-Match $moveSource 'void\s+RunMoveDistanceTest\s*\(uint8_t\s+dir,\s*uint16_t\s+distance\)' '缺少纯距离测试接口实现。'
Assert-Match $hmiSource 'RunMoveDistanceTest\s*\(dir,\s*MOTOR_DIRECTION_TEST_DISTANCE_CM\)' '主循环没有调用纯距离测试接口执行41cm。'
Assert-Match $hmiSource 'case\s+0:\s*dir\s*=\s*FRONT' '测试循环缺少前进方向。'
Assert-Match $hmiSource 'case\s+1:\s*dir\s*=\s*BACK' '测试循环缺少后退方向。'
Assert-Match $hmiSource 'case\s+2:\s*dir\s*=\s*LEFT' '测试循环缺少左移方向。'
Assert-Match $hmiSource 'default:\s*dir\s*=\s*RIGHT' '测试循环缺少右移方向。'
Assert-Match $hmiSource '#if\s+MOTOR_DIRECTION_TEST_ENABLE[\s\S]*?#else[\s\S]*?StartCoarseTestMode\s*\(\s*\)' '关闭开关后没有恢复原粗定位按钮流程。'
Assert-Match $taskSource '#if\s+MOTOR_DIRECTION_TEST_ENABLE[\s\S]*?Hmi_MotorDirectionTestProcess\s*\(\s*\)' '主循环没有处理电机测试请求。'

$distanceFunction = [regex]::Match(
    $moveSource,
    'void\s+RunMoveDistanceTest\s*\(uint8_t\s+dir,\s*uint16_t\s+distance\)\s*\{(?<body>[\s\S]*?)\n\}\s*\n\s*void\s+PidMove',
    [Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $distanceFunction.Success) {
    throw '无法提取纯距离测试函数。'
}
$distanceBody = $distanceFunction.Groups['body'].Value
Assert-Match $distanceBody 'CM_TO_PULSES\s*\(distance\)' '纯距离测试没有用统一公式换算目标脉冲。'
Assert-Match $distanceBody 'Emm_V5_Synchronous_motion\s*\(0\)' '纯距离测试没有同步启动四个电机。'
if ($distanceBody -match '(?m)^\s*Rotation\s*\(') {
    throw '纯距离测试仍会调用IMU旋转修正，测距会被额外动作干扰。'
}

Write-Host 'PASS: 单次41cm电机方向测试结构与回滚开关检查通过。'
