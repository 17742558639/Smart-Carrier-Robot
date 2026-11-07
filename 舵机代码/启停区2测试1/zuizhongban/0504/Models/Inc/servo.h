#ifndef _SERVO_H
#define _SERVO_H

#include "main.h"
#include "headfile.h"

void Servo_SetAngle(uint32_t which,float angle);
void Servo_Init(void); 
void Catch_Init(uint32_t which); // 兼容旧任务入口，初始化实测观察姿态
void Servo_SetAngle_Slow(uint32_t which, float angle, float step, int step_delay);
void Servo_Close_To_Plate(void);
void Servo_Watch_To_Move(void);
void Servo_Move_To_Watch(void);
void Servo_Watch_To_Catch(void);

/* 仅舵机姿态动作：暂不接入车辆/摄像头流程。 */
void Servo_To_Qr_Scan(void);      // 二维码扫描姿态
void Servo_To_Scan_A(void);       // 兼容旧名称，执行二维码扫描姿态
void Servo_Scan_A_To_Place_B(void); // A姿态到B低位放置姿态
void Servo_Release_At_Place(void); // B姿态打开夹爪释放物料

void Catch(uint32_t which);
void Place(uint32_t which);

void Servo_Move_To_Plate(uint16_t which_plate); 
void Servo_Plate_To_Move(uint16_t which_plate);

extern uint8_t plate_state[3];


/* ============================================================
 * 舵机姿态表 —— 2026-10-19 机械臂拆装后重新实测
 * 拆装导致 J2 / J4 零点整体偏移约 180 度，旧值全部作废。
 * 旧值只保留在行尾注释里供对照，不要再使用。
 * ============================================================ */

#define     JOINT1_FRONT            90  // 实测：正对站点/正前方；舵机1顺时针读数减小
#define     JOINT1_PLATE1           292 // 实测：第一盘子抓取位置
#define     JOINT1_PLATE2           325 // 实测：第二盘子抓取位置
#define     JOINT1_PLATE3           360 // 实测：第三盘子抓取位置

#define     JOINT2_WATCH            35  // 实测：观察/正前方（旧 69；拆装前 220）
#define     JOINT2_CATCH            209 // 实测：正前方站点实际抓取，已到舵机2机械极限
#define     JOINT2_MOVE             70  // 实测：抓取后收回姿态（旧 109；拆装前 260）
#define     JOINT2_PLATE_GRAB       96  // 三个盘子共用：抓取姿态（旧 129；拆装前 280）
#define     JOINT2_PLATE_EDGE       77  // 三个盘子共用：盘子边缘姿态（新增）

#define     JOINT3_WATCH            40  // 实测：观察姿态；正前方实测 38，统一取 40
#define     JOINT3_CATCH            169 // 实测：正前方站点实际抓取姿态（旧 150）
#define     JOINT3_MOVE             60  // 实测：抓取后收回姿态（旧 110）
#define     JOINT3_PLATE_GRAB       85  // 三个盘子共用：抓取姿态（旧 100）
#define     JOINT3_PLATE_EDGE       77  // 三个盘子共用：盘子边缘姿态（新增）

#define     JOINT4_CATCH            180 // 统一闭合值（旧实测173）
#define     JOINT4_PLATE            240 // 实测：观察/正前方姿态的打开值
#define     JOINT4_OPEN             250 // 实测：爪子最大张开（约值）
#define     JOINT4_PLATE_GRAB       180 // 三个盘子共用：统一闭合（旧实测178）
#define     JOINT4_PLATE_EDGE       180 // 三个盘子边缘：统一闭合（旧实测173）
#define     JOINT4_WATCH            240 // 观察姿态：常用张开（用户最终确认）

/* === 二维码扫描姿态（本次实测，J2=0 已确认不撞限位）=== */
#define     JOINT2_SCAN             0
#define     JOINT3_SCAN             40
#define     JOINT4_SCAN             240
/* 兼容旧命名，指向同一姿态 */
#define     JOINT2_SCAN_A           JOINT2_SCAN
#define     JOINT3_SCAN_A           JOINT3_SCAN

/* === 以下QR旧方案未重测，只保留供历史对照，不用于当前流程 === */
#define     JOINT2_QR1              220 // 警告：未重测
#define     JOINT3_QR1              100 // 警告：未重测
#define     JOINT2_QR2              90  // 警告：未重测
#define     JOINT3_QR2              0   // 警告：未重测

/* 正前方低位抓取/放置：本次实测更新，旧值360/150/173停用。 */
#define     JOINT2_PLACE_B          209
#define     JOINT3_PLACE_B          169
#define     JOINT4_PLACE_B          180

#define     PLATE_NUM               3

#endif
