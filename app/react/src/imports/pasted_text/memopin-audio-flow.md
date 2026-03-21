3.1 音频进入系统的三种来源
MemoPin 当前支持三种音频进入系统方式：

---
2.1 MemoPin 设备录音
流程：
MemoPin 开始录音
↓
手机与设备连接
↓
设备持续录音
↓
蓝牙同步传输到手机
↓
录音完成
↓
上传云端
↓
创建 Audio Memory
说明：
录音过程中：
- 手机可以知道设备正在录音
- 但无法获得录音百分比
- 因此不能显示真实进度条

---
2.2 设备重新连接 → 自动同步
当 MemoPin 与手机重新连接时：系统会检查设备中是否存在未同步录音。
流程：
设备重新连接
↓
查询 MemoPin 内存
↓
发现未同步音频
↓
开始蓝牙同步
↓
上传云端
↓
创建 Audio Memory
用户无需操作。

---
2.3 Import Audio
用户可以导入手机本地音频。
流程：
用户点击 +
↓
Import Audio
↓
选择手机音频文件
↓
导入系统
↓
上传云端
↓
创建 Audio Memory

---
3. 统一处理流程
无论音频来源如何，系统统一流程为：
Audio entering system
↓
Transfer / Upload
↓
Create Audio Memory
↓
User decides to run AI Summary
↓
Processing
↓
Memory updated
UI 不区分来源，仅在提示文案中体现。

---
3.2 Global Status Bar（全局状态条）
所有音频处理状态统一使用 Status Bar 组件。
位置
Header
────────────────
Status Bar
────────────────
Page Content
特点：
- 不遮挡内容
- 不打断操作
- 提供持续系统反馈
- ADHD 用户易于理解

---
5. Status Bar 状态类型
Status Bar 共支持四种状态：
1️⃣ Recording
2️⃣ Syncing
3️⃣ Importing
4️⃣ Processing

---
5.1 Recording（设备正在录音）
当 MemoPin 正在录音时：由于录音长度未知，因此 不显示百分比进度条。
UI 使用 Activity Bar（活动条）。
示例：
🎤 MemoPin is recording
──────────────●──────────
特点：
- 无百分比
- 无剩余时间
- 使用轻微动画
- 表示设备正在录音
用户理解：
设备正在录音
系统已连接
无需操作

---
5.2 Syncing（设备同步）
当设备连接并发现未同步录音：
Syncing recordings from MemoPin
████████░░░░░░░░ 40%
如果存在多个文件：
Syncing recordings (1 of 3)
██████░░░░░░░░░░ 25%
说明：此状态显示 真实进度条。

---
5.3 Import Audio
当用户导入手机音频时：
Importing audio file
██████████░░░░░░ 60%
说明：显示真实导入进度。

---
5.4 Audio Uploaded / Memory Created
当音频传输或导入完成后：系统 不会自动开始 AI Summary。
系统首先创建一条：
memory_type = audio
该 Memory 卡片包含：
- 标题（默认使用日期 / 时间）
- 音频波形
- 播放按钮
- 录音时长
- AI Summarize 按钮
此时：
- Summary 尚未生成
- Transcript 尚未生成
- 仅表示音频已进入系统

---
3.3 Memory List 更新
当 Audio Memory 创建后：系统会在 Memory 列表页插入一张新的 Memory 卡片。
示例：
Team standup discussion on API migration
Today, 10:30 AM · New updates
Audio
卡片显示：
New updates
以及未读提醒角标。
目的：
- 告知用户系统已接收新内容
- 引导用户查看 Memory
- 决定是否进行 AI Summary

---
5.6 AI Summary 触发机制
AI Summary 不是自动触发。用户进入 Audio Memory Detail 页面后，会看到：
Want a quick overview?
Generate an AI summary of this conversation

[ AI Summarize ]
只有当用户点击：
AI Summarize
系统才进入 AI 处理阶段。

---
5.7 AI Processing
这部分产品原型已经实现了，直接看产品原型就行了

---
8. Import Audio UX
用户操作：
+ → Import Audio
流程：
选择音频
↓
Preparing audio…
↓
Importing audio
↓
Create Audio Memory
↓
Memory list 更新

---
10. UI 风格
MemoPin UI 设计风格：
背景：浅灰蓝
进度条颜色：MemoPin 主蓝色
图标：
暂时无法在飞书文档外展示此内容
视觉原则：
- 简洁
- 彩色图标
- 柔和动画


---
11. ADHD 友好设计原则
Status Bar 设计必须满足：
- 简单
- 明确
- 不闪烁
- 不频繁弹窗
- 不阻断操作
避免：
Modal progress
Blocking UI

---