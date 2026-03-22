

MemoPin · Mobile Project Overview

完整设计示意（Figma Wireframe Spec）

页面结构：

Project Header

AI Summary

Timeline

Recurring Themes

Related Memories

Related Todos

整体页面结构：

┌──────────────────────────────┐
│ Project Header               │
│ 3 Memories · 2 Todos         │
│ Updated today                │
├──────────────────────────────┤
│ AI Summary                   │
├──────────────────────────────┤
│ Timeline                     │
├──────────────────────────────┤
│ Recurring Themes             │
├──────────────────────────────┤
│ Related Memories             │
├──────────────────────────────┤
│ Related Todos                │
└──────────────────────────────┘


⸻

1️⃣ Project Header

高度建议：

120 px

结构：

API Migration

[3 Memories]   [2 Todos]   [Updated today]

组件：

Chip
Icon + text

示例：

📁 3 Memories
☑ 2 Todos
⏱ Updated today

作用：

用户一眼看到：
	•	讨论数量
	•	行动数量
	•	更新时间

⸻

2️⃣ AI Summary

高度：

Auto height
Padding 16
Radius 12
Background: subtle purple

结构：

AI Summary

Across 3 discussions over 3 weeks,
the team shifted from phased API migration
to parallel execution.

交互：

Default: 3 lines
Tap → Expand

原因：

移动端要避免信息墙。

⸻

3️⃣ Timeline

标题：

Timeline

组件：

Vertical timeline

示意：

Jan 21
Hardware finalized
[Completed]

Feb 5
Kickstarter page draft
[Completed]

Mar 15
Campaign video finalized
[In progress]

Mar 25
Kickstarter launch
[Upcoming]

组件：

Date
Title
Status tag

状态颜色：

Completed  灰
In progress 黄
Upcoming   蓝


⸻

4️⃣ Recurring Themes

卡片结构：

Recurring Themes

● Manufacturing risk
Discussed in 8 meetings

● Pricing discussion
Discussed in 6 meetings

● Marketing strategy
Discussed in 5 meetings

UI：

Left dot color
Theme title
Description

颜色建议：

Risk      红
Strategy  蓝
Discussion 黄

交互：

Tap theme → filter memories


⸻

5️⃣ Related Memories

列表结构：

Related Memories

🧠 Investor meeting
Timeline discussion and funding expectations
Mar 9 2026

🧠 Product review
Hardware specification discussion
Mar 7 2026

组件：

Icon
Title
Subtitle
Date

点击：

Open Memory Detail


⸻

6️⃣ Related Todos

任务结构：

Related Todos

☐ Finalize campaign video
Due Mar 15

☐ Confirm pricing
Due Mar 12

☑ Prepare investor update
Completed Mar 9

组件：

Checkbox
Task title
Due date
Status

交互：

Tap checkbox → mark complete
Tap row → open todo


⸻

7️⃣ 页面滚动结构

完整滚动顺序：

Header
Summary
Timeline
Themes
Memories
Todos

原因：

用户阅读逻辑：

Understand project
↓
See key milestones
↓
See recurring issues
↓
Review discussions
↓
Execute actions


⸻

8️⃣ 页面信息层级

视觉权重：

Project name
↓
AI Summary
↓
Timeline
↓
Recurring Themes
↓
Memories
↓
Todos

核心原则：

先理解 → 再细节 → 最后行动

⸻

9️⃣ Figma 组件列表

设计师需要的组件：

Project Header
Insight Card
Timeline Item
Theme Card
Memory List Item
Todo Item
Status Tag

统一间距：

Section gap
24px

Card padding
16px


⸻

🔟 最终移动端页面示意

API Migration
3 Memories · 2 Todos · Updated today

AI Summary
Team shifted migration strategy to parallel execution.

Timeline
Jan 21 Hardware finalized
Feb 5 Kickstarter page draft
Mar 15 Campaign video

Recurring Themes
Manufacturing risk
Pricing discussion
Marketing strategy

Related Memories
Investor meeting
Product review

Related Todos
Finalize campaign video
Confirm pricing

