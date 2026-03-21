什么时候让用户注册账号

---
MemoPin 用户身份与登录策略 PRD
MemoPin 的核心价值在于记录和整理用户的记忆（Memory）。
如果在用户首次打开 App 时强制注册或登录，会显著增加用户使用门槛，降低体验转化率。

但如果完全不建立用户身份，则会带来以下风险：
- 用户数据无法保存或绑定
- 用户设备更换或卸载 App 后数据丢失
- Memory 无法跨设备同步
- 用户行为数据无法追踪

因此需要设计一种 低摩擦的用户身份体系：
- 用户可以 无需注册即可开始使用
- 系统能够 安全保存用户数据
- 在合适时机 引导用户注册账号


---
1.1 用户身份体系设计
MemoPin 采用 三层用户身份模型：
Device User
↓
Guest User
↓
Account User

---
1 Device User（设备用户）
定义
当用户首次打开 App 时，系统自动创建一个 device_id。
该 device_id 作为当前设备的唯一身份标识。
用户无需注册即可使用产品。

---
创建流程
首次启动 App：
App Launch
↓
Generate device_id
↓
Create local user space
↓
Initialize local database

---
Device User 数据绑定
所有数据默认绑定到：
device_id
包括：
memory_id
audio
transcript
summary
memo
todo
insight

---

---
2 Guest User（匿名用户）
当 Device User 开始使用 MemoPin 时，系统自动视为 Guest User。
Guest User 特征：
无需注册
无需登录
数据仅存在本设备
用户可使用以下功能：
Quick Capture
录音
语音转写
Summary
Add Memo
Add Todo
Ask AI（限次数）

---
3 Account User（注册用户）
当用户完成注册或登录后：
device_id
↓
绑定
↓
account_id
之后：
所有 memory 数据同步至云端
支持：
多设备同步
数据备份
恢复历史

---
1.2 数据存储策略


MemoPin 采用 Local-first 架构。

Memory 创建流程：
录音
↓
本地保存 audio
↓
调用 ASR / AI
↓
生成 transcript
↓
生成 summary
↓
写入本地数据库
即使用户未登录：
memory 仍然可访问


---

1.3 登录触发策略
MemoPin 不在 App 启动时强制登录。
系统将在以下场景提示用户创建账号。

---
1 Memory 数量触发
当用户创建：
≥ 2 条 Memory
系统提示：
Create an account to keep your memories safe.
Access them across devices and never lose them.
按钮：
Continue with Apple
Continue with Google
Create Account
Not Now

---
2 Ask AI 功能触发
当用户使用 Ask AI 时：
如果用户未登录
提示：
Sign in to search across your memories.

---
3 数据安全提示
当用户在 Settings 页面查看 Account 状态时：
若未登录：
提示登录
Your memories are currently stored only on this device.
Sign in to back them up.


---
1.4 免费体验额度
为控制 AI 调用资源，Guest User 使用以下限制：
Quick Capture：10 次
Memory 创建：2 条
Ask AI：10 次
超过额度后：
提示：
Create an account to continue using MemoPin.

---
1.5 登录后的数据处理
当用户完成登录：
系统执行：
device_id
↓
绑定
↓
account_id
然后执行：
Upload local memories
同步流程：
local memories
↓
upload
↓
cloud storage
↓
sync complete

---
数据丢失风险提示
为了降低用户数据丢失风险，在以下场景提醒用户：
条件
用户未登录且：
memory_count ≥ 2
提示：
Your memories are stored only on this device.
Sign in to back them up.

---

---
1.6 用户体验原则
MemoPin 登录设计遵循以下原则：
价值优先
用户必须 先体验产品价值。再引导注册。

---
登录是保护而非门槛
文案重点：
保护记忆
备份数据
跨设备访问
而不是：
注册账号

---
登录节点自然
触发点：
Memory 创建
Ask AI
数据备份
同步
而不是：
App 启动

---
推荐登录文案


登录提示：
Save your memories
Sign in to keep your memories safe and access them across devices.

---
系统架构总结
用户身份模型：
Device User
↓
Guest User
↓
Account User
数据策略：
Local-first
Cloud sync after login
登录触发：
Memory ≥2
Ask AI
Backup reminder