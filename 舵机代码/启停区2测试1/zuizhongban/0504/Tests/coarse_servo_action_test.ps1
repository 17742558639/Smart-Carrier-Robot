$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$servoHeader = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Inc\servo.h') -Raw
$servoSource = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Src\servo.c') -Raw
$moveSource = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Src\move.c') -Raw
$hmiHeader = Get-Content -LiteralPath (Join-Path $projectRoot 'Models\Inc\hmi.h') -Raw

function Assert-Match([string]$Text, [string]$Pattern, [string]$Message) {
    if ($Text -notmatch $Pattern) { throw $Message }
}

Assert-Match $hmiHeader '#define\s+MOTOR_DIRECTION_TEST_ENABLE\s+0' '粗定位尚未恢复，电机测距开关必须为0。'

Assert-Match $servoHeader '#define\s+JOINT2_WATCH\s+35' '观察姿态J2不是35。'
Assert-Match $servoHeader '#define\s+JOINT3_WATCH\s+40' '观察姿态J3不是40。'
Assert-Match $servoHeader '#define\s+JOINT4_WATCH\s+240' '观察姿态J4不是240。'
Assert-Match $servoHeader '#define\s+JOINT2_SCAN\s+0' '二维码姿态J2不是0。'
Assert-Match $servoHeader '#define\s+JOINT3_SCAN\s+40' '二维码姿态J3不是40。'
Assert-Match $servoHeader '#define\s+JOINT4_SCAN\s+240' '二维码姿态J4不是240。'
Assert-Match $servoHeader '#define\s+JOINT2_CATCH\s+209' '低位姿态J2不是209。'
Assert-Match $servoHeader '#define\s+JOINT3_CATCH\s+169' '低位姿态J3不是169。'

foreach ($macro in @('JOINT4_CATCH', 'JOINT4_PLATE_GRAB', 'JOINT4_PLATE_EDGE', 'JOINT4_PLACE_B')) {
    Assert-Match $servoHeader ("#define\s+{0}\s+180" -f $macro) "$macro 没有统一为180闭合。"
}

Assert-Match $servoHeader 'void\s+Servo_To_Qr_Scan\s*\(void\)' '缺少二维码姿态函数声明。'
$qrFunction = [regex]::Match($servoSource, 'void\s+Servo_To_Qr_Scan\s*\(void\)\s*\{(?<body>[\s\S]*?)\n\}')
if (-not $qrFunction.Success) { throw '无法提取二维码姿态函数。' }
$qrBody = $qrFunction.Groups['body'].Value
foreach ($macro in @('JOINT2_SCAN', 'JOINT3_SCAN', 'JOINT4_SCAN')) {
    Assert-Match $qrBody $macro "二维码姿态函数没有使用$macro。"
}
Assert-Match $servoSource 'void\s+Servo_Move_To_Watch\s*\(void\)[\s\S]*?Servo_Move_Pair_To\s*\(JOINT2_WATCH,\s*JOINT3_WATCH' '回观察函数没有从当前姿态安全返回。'

Assert-Match $moveSource 'static\s+uint8_t\s+CoarseRunStationArmAction\s*\(void\)' '缺少粗定位站点机械臂动作分发。'
Assert-Match $moveSource 'case\s+CoarseTargetQr\s*:[\s\S]*?Servo_To_Qr_Scan\s*\(\s*\)' '二维码区没有调用二维码姿态。'
foreach ($target in @('Material', 'Rough', 'Storage')) {
    Assert-Match $moveSource ("case\s+CoarseTarget{0}\s*:" -f $target) "缺少$target 工位动作分支。"
}
Assert-Match $moveSource 'case\s+CoarseTargetMaterial\s*:[\s\S]*?case\s+CoarseTargetRough\s*:[\s\S]*?case\s+CoarseTargetStorage\s*:[\s\S]*?Servo_Watch_To_Catch\s*\(\s*\)' '三个工位没有执行低位动作。'
Assert-Match $moveSource 'CoarseRunStationArmAction[\s\S]*?HAL_Delay\s*\(\s*COARSE_TEST_DWELL_MS\s*\)[\s\S]*?Servo_Move_To_Watch\s*\(\s*\)' '站点动作没有保持1秒后回观察姿态。'

if ($moveSource -match 'CoarseRunStationArmAction[\s\S]{0,1200}(Camera_Init|SetCameraTask|WaitPlace)\s*\(') {
    throw '粗定位站点动作错误启用了摄像头。'
}

Write-Host 'PASS: 四站点舵机动作、1秒停留、观察姿态返回和摄像头隔离检查通过。'
