import 'package:omi/business/shared/models/mp_business_models.dart';

class MPBusinessRepository {
  const MPBusinessRepository();

  MPUser getCurrentUser() {
    return const MPUser(
      id: 'u_001',
      name: 'Omi User',
      userType: 'guest',
      deviceId: 'device_u_001',
    );
  }

  List<MPTodo> getTodos() {
    return const [
      MPTodo(
        id: 't_001',
        title: '回顾昨天的会议纪要',
        completed: false,
        dueLabel: '今天',
        category: 'Up Next',
      ),
      MPTodo(
        id: 't_002',
        title: '整理本周重点事项',
        completed: true,
        dueLabel: '已完成',
        category: 'Completed',
      ),
      MPTodo(
        id: 't_003',
        title: '补充个人学习计划',
        completed: false,
        category: 'Today',
      ),
    ];
  }

  List<MPMemory> getMemories() {
    return const [
      MPMemory(
        id: 'm_001',
        title: '产品周会',
        summary: '讨论了新版本需求优先级与上线窗口。',
        dateLabel: '今天 10:30',
        hasAudio: true,
      ),
      MPMemory(
        id: 'm_002',
        title: '用户访谈',
        summary: '用户更关注检索速度和摘要准确性。',
        dateLabel: '昨天 16:20',
        hasAudio: false,
      ),
    ];
  }

  List<MPConversation> getConversations() {
    return const [
      MPConversation(
        id: 'c_001',
        title: '复盘助手',
        preview: '你可以从本周完成度、风险和下周计划三个角度复盘。',
        updatedAtLabel: '刚刚',
      ),
      MPConversation(
        id: 'c_002',
        title: '会议总结',
        preview: '已帮你整理会议决策和待办项。',
        updatedAtLabel: '2小时前',
      ),
    ];
  }

  List<MPMemo> getMemos() {
    return const [
      MPMemo(
        id: 'memo_001',
        title: '需求澄清记录',
        content: '前端同学希望补充离线能力和搜索高亮。',
        timeLabel: '今天 14:05',
      ),
      MPMemo(
        id: 'memo_002',
        title: '技术方案要点',
        content: '优先完成业务层模型，再逐步对接真实接口。',
        timeLabel: '昨天 20:11',
      ),
    ];
  }

  List<MPInsight> getInsights() {
    return const [
      MPInsight(
        id: 'ins_001',
        title: 'Daily Insight',
        type: 'daily',
        summary: '今日会议时间占比上升，建议压缩同步时长。',
      ),
      MPInsight(
        id: 'ins_002',
        title: 'Weekly Insight',
        type: 'weekly',
        summary: '本周任务完成率 78%，主要卡点在跨端联调。',
      ),
      MPInsight(
        id: 'ins_003',
        title: 'Pattern Insight',
        type: 'pattern',
        summary: '下午 3 点后更容易产生高质量输出。',
      ),
    ];
  }

  List<MPProject> getProjects() {
    return const [
      MPProject(
        id: 'p_001',
        name: 'Omi App 2.0',
        overview: '统一 React 与 Flutter 端的信息架构和交互路径。',
      ),
      MPProject(
        id: 'p_002',
        name: 'AI Note Assistant',
        overview: '优化语音转写到摘要输出的全链路体验。',
      ),
    ];
  }
}
