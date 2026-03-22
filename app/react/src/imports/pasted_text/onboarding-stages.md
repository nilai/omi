
Stage 1：完全新用户（0 Memory）


条件

memory_count == 0

Hero 模块显示

🧠 Capture your first memory

Record conversations, meetings, or ideas.
MemoPin will turn them into insights and actions.

[Start Recording]
[Quick Capture]

作用


推动用户完成：
第一条 Memory
这是 MemoPin 最关键的 onboarding 行为。


---

Stage 2：已有 1 条 Memory


条件

memory_count == 1

页面逻辑


Hero 模块仍然保留，但文案改变。

因为用户已经理解：
MemoPin 可以记录
但还没有形成使用习惯，需要鼓励继续记录。

Hero 模块文案

🧠 Capture another memory

Try recording another conversation or idea.

The more you record, the better MemoPin understands your work.

[Start Recording]
Quick Capture 在此阶段可以弱化或隐藏。

页面结构

Hero Encouragement
↓
Today's Focus
↓
Recent Memory（显示第一条 Memory）
↓
Insights Empty

作用


推动用户创建：
第二条 Memory


---

Stage 3：已有 2 条 Memory


条件

memory_count >= 2 && memory_count < 3

页面逻辑


Hero 仍然存在，但提示进一步弱化。

目标是让用户形成 连续记录行为。

Hero 文案

🧠 Build your memory timeline

Record a few more memories to help MemoPin
understand patterns in your work.

[Start Recording]

页面结构

Hero encouragement
↓
Today's Focus
↓
Recent Memory
↓
Insights（可能为空）

作用


推动用户达到：
3 条 Memory
这是一个关键阈值。

---

Stage 4：形成初步习惯（≥3 Memory）


条件

memory_count >= 3

页面逻辑


Hero 引导 完全消失。

首页恢复正常结构：
Today's Focus
↓
Recent Memory
↓
Insights
因为用户已经完成：
理解产品核心行为
继续提示反而会造成 UI 噪音。