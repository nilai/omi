
当用户首次进入 MemoPin 时，可能出现以下情况：
- 没有 Memory
- 没有 Todo
- 没有 Insight


此时首页会出现 整体空状态（Composite Empty State）。
如果处理不好，用户会看到一个“空页面”，无法理解下一步该做什么。

因此，Home 页不能只做一个静态空状态，而需要设计成：

引导式 + 渐进式（Progressive）Empty State

也就是说：
- 新用户时，引导他完成第一条 Memory
- 有了一条 Memory 后，引导他继续记录
- 有了更多 Memory 后，引导他开始使用 Todo 和 Insight


---

2. 设计目标


Home Empty State 的核心目标：

1️⃣ 不让页面看起来像坏掉
2️⃣ 引导用户完成第一个关键行为（创建第一条 Memory）
3️⃣ 让用户不止创建第一条，而是持续创建第二条、第三条
4️⃣ 自然推进产品飞轮：
Record
↓
Record more
↓
Take action
↓
Discover insights


---

3. 设计原则


3.1 首页空状态不是“没有数据”


而是：

“告诉用户下一步应该做什么”


---

3.2 对 ADHD 用户友好


MemoPin 的目标用户很可能：
- 想记录
- 但不知道从哪里开始
- 看到太多入口会犹豫


因此首页必须：
- 结构清晰
- 行动明确
- 默认突出 一个最核心动作

Start Recording


---

3.3 空状态是动态的，不是一次性的


Home Empty State 不是只在第一次显示一次。
它应该根据用户当前数据状态动态变化。

---

4. 阶段式设计（Progressive Empty State）


Stage 1：完全新用户（0 Memory / 0 Todo / 0 Insight）


条件

memory_count == 0
todo_count == 0
insight_count == 0

页面结构

Hero Empty
↓
Today's Focus Empty
↓
Recent Memory Empty
↓
Insights Empty


---

4.1 Hero Empty（核心引导）


位置：
Today's Focus 模块上方
设计：
🧠 Capture your first memory

Record conversations, meetings, or ideas.
MemoPin will turn them into insights and actions.

[Start Recording]
[Quick Capture]
按钮行为：
Start Recording → 打开录音
Quick Capture → 打开快速输入
作用：

引导用户完成 第一次 Memory 创建。


---

4.2 Today’s Focus Empty

⭐ Today's Focus

No tasks yet

Tasks created from your memories will appear here.

[Add Task]
说明：

Todo 不需要复杂引导，只需说明来源。

---

4.3 Recent Memory Empty

📝 Recent Memory

No memories yet

Start recording to capture your first conversation or idea.

[Start Recording]
作用：

强化 Memory 是核心入口。

---

4.4 Insights Empty

✨ Insights

No insights yet

Record more memories and MemoPin will discover patterns for you.
说明：

Insights 是 AI 自动生成，因此不需要按钮。

---

Stage 2：已有 1 条 Memory


条件

memory_count == 1

页面逻辑


此时 Hero Empty 消失。
因为用户已经完成了第一条 Memory，不需要再用“第一次引导”。

但仍然需要鼓励他继续记录。

页面结构

Today's Focus Empty / Encouragement
↓
Recent Memory（显示第一条 Memory）
↓
Insights Empty

Today’s Focus 建议文案

⭐ Today's Focus

Try capturing another memory today.

The more you record, the better MemoPin understands your work.
作用：

推动用户创建 第二条 Memory。


---

Stage 3：已有 2–5 条 Memory


条件

memory_count >= 2 && memory_count < 6

页面逻辑


此时用户已经开始使用产品，Home 页面进入“正常使用阶段”。

页面结构：
Today's Focus
↓
Recent Memory
↓
Insights（可能为空）

设计重点

- Today’s Focus 开始展示 AI 生成的任务或推荐操作
- Recent Memory 正常展示
- Insights 仍然可以为空


作用：

推动用户从 记录 进入 执行


---

Stage 4：形成早期习惯（6+ Memory）


条件

memory_count >= 6

页面逻辑


此时可以开始在首页强化 AI 的价值。

例如在 Insights 模块中展示：
✨ Pattern detected

API migration blockers appeared in 4 discussions this week.
作用：

推动用户从：
Record
进入：
Understand
↓
Act


---

5. 生命周期规则


Hero Empty Card 的显示规则


Hero Empty 不是“只出现一次”，而是基于状态显示。

显示条件

memory_count == 0

隐藏条件

memory_count >= 1

重新出现条件


当用户删除所有 Memory 后：
memory_count == 0
Hero Empty 应重新出现。

---

6. 页面最终效果


Stage 1（完全空）

🧠 Capture your first memory
[Start Recording]

⭐ Today's Focus
No tasks yet

📝 Recent Memory
No memories yet

✨ Insights
No insights yet


---

Stage 2（已有 1 条 Memory）

⭐ Today's Focus
Try capturing another memory today

📝 Recent Memory
[显示第一条 Memory]

✨ Insights
No insights yet


---

Stage 3（已有多条 Memory）

⭐ Today's Focus
[AI 生成任务]

📝 Recent Memory
[显示最近记录]

✨ Insights
[空或开始出现]


---

Stage 4（形成习惯）

⭐ Today's Focus
[真实任务]

📝 Recent Memory
[最近记录]

✨ Insights
[Pattern / Daily / Weekly insight]


---

7. UX 设计原则


7.1 避免“死页面”


AI 产品最怕的是：
空页面
因为用户会产生疑问：
是不是我还没设置什么？
通过 Empty State 明确给出：
Start Recording
可以立即触发行为。

---

7.2 不同时给太多选择


Home 页空状态的主行为始终应该是：
Start Recording
Quick Capture 作为次要补充即可。

---

7.3 让引导自然消失


用户完成关键动作后，首页应该恢复正常模块，不要一直保留 onboarding 感。

---

8. 视觉设计建议


Hero Empty Card

背景：浅蓝 / 浅紫
Icon：96px
圆角：20px
Padding：24px
风格保持与现有卡片一致。

---

模块 Empty State


保持当前 Home 页面卡片结构，只替换内部内容，不大改布局。

---

9. 引导增强（可选）


当 Home 完全空时，可对 + 按钮增加轻微提示：

方式：
pulse animation
或：
tooltip
示例：
Tap + to record your first memory
作用：

提高首次记录转化率。

---

10. 文案汇总


Hero

Capture your first memory

Record conversations, meetings, or ideas.
MemoPin will turn them into insights and actions.

Start Recording
Quick Capture


---

Today’s Focus（空）

No tasks yet
Tasks from your memories will appear here.


---

Today’s Focus（1 条 Memory 后）

Try capturing another memory today.
The more you record, the better MemoPin understands your work.


---

Recent Memory

No memories yet
Start recording to capture your first idea.


---

Insights

No insights yet
Record memories and AI will discover patterns.