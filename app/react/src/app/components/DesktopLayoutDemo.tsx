import { Home, Calendar, MessageCircle, Settings, CheckSquare, Brain, Clock, ChevronRight } from 'lucide-react';

/**
 * 这是一个桌面端布局的演示页面
 * 展示响应式设计后，在大屏幕上的样子
 */
export function DesktopLayoutDemo() {
  return (
    <div className="h-screen w-full bg-[#f5f5f7] flex overflow-hidden">
      {/* 左侧边栏导航 - 固定宽度 */}
      <div className="w-[240px] bg-white border-r border-black/[0.06] flex flex-col">
        {/* Logo区域 */}
        <div className="px-6 py-5 border-b border-black/[0.06]">
          <h1 className="text-[20px] font-bold text-[#1c1c1e]">MemoPin</h1>
          <p className="text-[12px] text-[#8e8e93] mt-0.5">Desktop Version</p>
        </div>

        {/* 导航菜单 */}
        <nav className="flex-1 px-3 py-4">
          <div className="space-y-1">
            {/* Home */}
            <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[8px] bg-[#f2f2f7] text-[#007aff] hover:bg-[#e5e5ea] transition-colors">
              <Home className="w-5 h-5" strokeWidth={2} />
              <span className="text-[15px] font-medium">Home</span>
            </button>

            {/* Memory */}
            <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[8px] text-[#3c3c43] hover:bg-[#f2f2f7] transition-colors">
              <Calendar className="w-5 h-5" strokeWidth={2} />
              <span className="text-[15px] font-medium">Memory</span>
            </button>

            {/* Ask AI */}
            <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[8px] text-[#3c3c43] hover:bg-[#f2f2f7] transition-colors">
              <MessageCircle className="w-5 h-5" strokeWidth={2} />
              <span className="text-[15px] font-medium">Ask AI</span>
            </button>

            {/* Todo List */}
            <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[8px] text-[#3c3c43] hover:bg-[#f2f2f7] transition-colors">
              <CheckSquare className="w-5 h-5" strokeWidth={2} />
              <span className="text-[15px] font-medium">Todo List</span>
            </button>
          </div>

          {/* 分隔线 */}
          <div className="h-[1px] bg-black/[0.06] my-4" />

          {/* 设置 */}
          <button className="w-full flex items-center gap-3 px-3 py-2.5 rounded-[8px] text-[#3c3c43] hover:bg-[#f2f2f7] transition-colors">
            <Settings className="w-5 h-5" strokeWidth={2} />
            <span className="text-[15px] font-medium">Preferences</span>
          </button>
        </nav>

        {/* 底部用户信息 */}
        <div className="px-4 py-4 border-t border-black/[0.06]">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center text-white text-[14px] font-semibold">
              U
            </div>
            <div className="flex-1">
              <p className="text-[13px] font-medium text-[#1c1c1e]">User Name</p>
              <p className="text-[11px] text-[#8e8e93]">user@email.com</p>
            </div>
          </div>
        </div>
      </div>

      {/* 主内容区域 - 可滚动 */}
      <div className="flex-1 overflow-y-auto">
        <div className="max-w-[1400px] mx-auto px-8 py-6">
          {/* 页面标题 */}
          <div className="mb-6">
            <h2 className="text-[28px] font-bold text-[#1c1c1e] mb-1">Home</h2>
            <p className="text-[14px] text-[#8e8e93]">Monday, March 9, 2026</p>
          </div>

          {/* 三列布局 - 展示你的四个区块 */}
          <div className="grid grid-cols-3 gap-5">
            {/* Today's Focus */}
            <div className="bg-white rounded-[16px] p-5 border border-black/[0.06] shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Today's Focus</h3>
                <Clock className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
              </div>
              <div className="space-y-3">
                <div className="flex items-start gap-3 p-3 bg-[#f9f9f9] rounded-[10px]">
                  <CheckSquare className="w-4 h-4 text-[#8e8e93] mt-0.5" strokeWidth={2} />
                  <div className="flex-1">
                    <p className="text-[14px] text-[#1c1c1e] font-medium">Review investor deck</p>
                    <p className="text-[12px] text-[#8e8e93] mt-1">10:00 AM</p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 bg-[#f9f9f9] rounded-[10px]">
                  <CheckSquare className="w-4 h-4 text-[#8e8e93] mt-0.5" strokeWidth={2} />
                  <div className="flex-1">
                    <p className="text-[14px] text-[#1c1c1e] font-medium">Team standup meeting</p>
                    <p className="text-[12px] text-[#8e8e93] mt-1">2:00 PM</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Memory */}
            <div className="bg-white rounded-[16px] p-5 border border-black/[0.06] shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Recent Memory</h3>
                <Calendar className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
              </div>
              <div className="space-y-3">
                <div className="p-3 bg-[#f9f9f9] rounded-[10px] hover:bg-[#f2f2f7] transition-colors cursor-pointer group">
                  <div className="flex items-start justify-between mb-2">
                    <p className="text-[14px] text-[#1c1c1e] font-medium">Q1 Strategy Review</p>
                    <ChevronRight className="w-4 h-4 text-[#8e8e93] group-hover:text-[#007aff] transition-colors" strokeWidth={2} />
                  </div>
                  <p className="text-[12px] text-[#8e8e93]">Mar 8 · 45 min</p>
                </div>
                <div className="p-3 bg-[#f9f9f9] rounded-[10px] hover:bg-[#f2f2f7] transition-colors cursor-pointer group">
                  <div className="flex items-start justify-between mb-2">
                    <p className="text-[14px] text-[#1c1c1e] font-medium">Coffee with Sarah</p>
                    <ChevronRight className="w-4 h-4 text-[#8e8e93] group-hover:text-[#007aff] transition-colors" strokeWidth={2} />
                  </div>
                  <p className="text-[12px] text-[#8e8e93]">Mar 7 · 30 min</p>
                </div>
              </div>
            </div>

            {/* AI Insights */}
            <div className="bg-white rounded-[16px] p-5 border border-black/[0.06] shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] font-semibold text-[#1c1c1e]">AI Insights</h3>
                <Brain className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
              </div>
              <div className="p-4 bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] rounded-[12px] border border-[#bae6fd]/50">
                <p className="text-[13px] text-[#0c4a6e] leading-relaxed">
                  Your meetings this week show a pattern of creative discussions in the morning. Consider scheduling brainstorming sessions before noon.
                </p>
              </div>
            </div>

            {/* Memos - 横跨两列 */}
            <div className="col-span-2 bg-white rounded-[16px] p-5 border border-black/[0.06] shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Memos</h3>
                <button className="text-[14px] text-[#007aff] font-medium hover:opacity-70 transition-opacity">
                  View All
                </button>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="p-4 bg-[#fffbeb] rounded-[12px] border border-[#fef3c7]">
                  <p className="text-[13px] text-[#92400e] leading-relaxed">
                    Remember to follow up with the design team about the new mockups
                  </p>
                  <p className="text-[11px] text-[#d97706] mt-2">2 hours ago</p>
                </div>
                <div className="p-4 bg-[#f0fdf4] rounded-[12px] border border-[#dcfce7]">
                  <p className="text-[13px] text-[#14532d] leading-relaxed">
                    Great idea from John: automate the weekly report generation
                  </p>
                  <p className="text-[11px] text-[#16a34a] mt-2">Yesterday</p>
                </div>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="bg-white rounded-[16px] p-5 border border-black/[0.06] shadow-sm">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">Quick Stats</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-[13px] text-[#8e8e93]">Tasks Today</span>
                  <span className="text-[15px] font-semibold text-[#1c1c1e]">8</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[13px] text-[#8e8e93]">Completed</span>
                  <span className="text-[15px] font-semibold text-[#34c759]">5</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[13px] text-[#8e8e93]">Memories</span>
                  <span className="text-[15px] font-semibold text-[#1c1c1e]">23</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
