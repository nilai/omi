🧩MemoPin 空/错误状态页面设计规范
所有依赖服务端数据的页面必须支持 三种状态：
暂时无法在飞书文档外展示此内容


---

一、Empty State（无数据）


统一结构

[Illustration Icon]

Title

Description

Primary Action
UI结构：
     icon

   Title

Description

[Primary Button]
设计原则：
- 居中布局
- 图标使用浅色插画
- 按钮突出主行动


---

二、Error State（错误）


统一结构

[Warning Icon]

Title

Description

Retry Button
UI结构：
⚠️ icon

Title

Description

[Retry]


---

三、Memory 页面


Empty

🧠 icon

No memories yet

Start recording to capture your first ideas and conversations.

[Start Recording]
按钮行为：
打开 Recording


---

Error

⚠️

Unable to load memories

Please check your connection and try again.

[Retry]


---

四、Todo 页面


Empty

✅ icon

No tasks yet

Tasks created from your memories will appear here.

[Create Task]
按钮行为：
打开 Add Todo


---

Error

⚠️

Unable to load tasks

Please check your connection.

[Retry]


---

五、Insight 页面


Empty

📊 icon

No insights yet

Record more memories and AI will generate insights for you.

[Start Recording]


---

Error

⚠️

Unable to load insights

Please try again later.

[Retry]


---

六、Ask AI 页面


Empty


Ask AI 一般不会是空数据，但可以设计初始状态：
🤖 icon

Ask anything about your memories

AI can help summarize, analyze and generate actions.

[Start Conversation]


---

Error

⚠️

AI service unavailable

Please try again later.

[Retry]