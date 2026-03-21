# Flutter Design Resources Export Guide
# MemoPin APP 设计资源导出指南

## 📱 Overview / 概述
This guide helps your Flutter development team extract and implement all design resources from the MemoPin web prototype.

本指南帮助你的 Flutter 开发团队从 MemoPin 网页原型中提取和实现所有设计资源。

---

## 🎨 Part 1: Colors / 颜色资源

### Method 1: Copy Dart Color Code / 直接复制 Dart 代码

创建文件：`lib/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors / 主色
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryBlueHover = Color(0xFF0051D5);
  static const Color lightBlue = Color(0xFF5AC8FA);
  
  // System Colors / 系统颜色
  static const Color successGreen = Color(0xFF34C759);
  static const Color successGreenDark = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color warningOrangeDark = Color(0xFFFF8000);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color errorRedDark = Color(0xFFD32F2F);
  static const Color purple = Color(0xFFAF52DE);
  static const Color purpleDark = Color(0xFF9B3FCE);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFB700);
  static const Color cyan = Color(0xFF32ADE6);
  static const Color cyanDark = Color(0xFF1E96D4);
  
  // Accent Colors / 强调色
  static const Color orangeAccent = Color(0xFFFF6B35);
  static const Color orangeAccentMid = Color(0xFFFF8C42);
  static const Color orangeAccentLight = Color(0xFFFFA94D);
  
  // Neutral Colors / 中性色
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textQuaternary = Color(0xFFC7C7CC);
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF2F2F7);
  static const Color backgroundTertiary = Color(0xFFE5E5EA);
  static const Color divider = Color(0x0F000000); // rgba(0, 0, 0, 0.06)
  
  // Overlay Colors / 遮罩颜色
  static const Color modalBackdrop = Color(0x66000000); // rgba(0, 0, 0, 0.4)
  static const Color hoverOverlay = Color(0x05000000); // rgba(0, 0, 0, 0.02)
  static const Color activeOverlay = Color(0x0A000000); // rgba(0, 0, 0, 0.04)
}
```

### Method 2: Create Color Palette JSON / 创建色彩 JSON

如果你需要导入 Figma/Sketch，创建 `colors.json`：

```json
{
  "primary": {
    "blue": "#007AFF",
    "blueHover": "#0051D5",
    "lightBlue": "#5AC8FA"
  },
  "system": {
    "successGreen": "#34C759",
    "warningOrange": "#FF9500",
    "errorRed": "#FF3B30",
    "purple": "#AF52DE",
    "gold": "#FFD700",
    "cyan": "#32ADE6"
  },
  "text": {
    "primary": "#1C1C1E",
    "secondary": "#3C3C43",
    "tertiary": "#8E8E93",
    "quaternary": "#C7C7CC"
  },
  "background": {
    "primary": "#FFFFFF",
    "secondary": "#F2F2F7",
    "tertiary": "#E5E5EA"
  }
}
```

---

## 🎯 Part 2: Icons / 图标资源

### Option 1: Use Flutter Icon Package / 使用 Flutter 图标包（推荐）

#### Step 1: Install Package / 安装包

在 `pubspec.yaml` 添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  lucide_icons: ^0.400.0  # Lucide Icons for Flutter
```

然后运行：
```bash
flutter pub get
```

#### Step 2: Import and Use / 导入和使用

```dart
import 'package:lucide_icons/lucide_icons.dart';

// 使用示例
Icon(
  LucideIcons.user,
  size: 20,
  color: AppColors.primaryBlue,
)
```

#### Step 3: All Icons Used in MemoPin / MemoPin 使用的所有图标

```dart
// 创建文件：lib/theme/app_icons.dart

import 'package:lucide_icons/lucide_icons.dart';

class AppIcons {
  // Navigation / 导航
  static const chevronLeft = LucideIcons.chevronLeft;
  static const chevronRight = LucideIcons.chevronRight;
  
  // User & Account / 用户和账户
  static const user = LucideIcons.user;
  static const logOut = LucideIcons.logOut;
  
  // Subscription / 订阅
  static const crown = LucideIcons.crown;
  
  // Data Management / 数据管理
  static const database = LucideIcons.database;
  static const trash2 = LucideIcons.trash2;
  static const download = LucideIcons.download;
  
  // Help & Support / 帮助和支持
  static const helpCircle = LucideIcons.helpCircle;
  static const book = LucideIcons.book;
  static const messageCircle = LucideIcons.messageCircle;
  static const mail = LucideIcons.mail;
  
  // Security / 安全
  static const shield = LucideIcons.shield;
  static const lock = LucideIcons.lock_;
  
  // Documents / 文档
  static const fileText = LucideIcons.fileText;
  
  // Actions / 操作
  static const upload = LucideIcons.upload;
  static const check = LucideIcons.check;
  static const x = LucideIcons.x;
  
  // Recording / 录音
  static const mic = LucideIcons.mic;
  static const pause = LucideIcons.pause;
  static const play = LucideIcons.play;
  static const stopCircle = LucideIcons.stopCircle;
}
```

---

### Option 2: Download SVG Icons Manually / 手动下载 SVG 图标

如果你想要 SVG 文件（用于自定义或离线使用）：

#### Step 1: Visit Lucide Website / 访问 Lucide 官网
🔗 https://lucide.dev/icons/

#### Step 2: Download Icons / 下载图标清单

| Icon Name | 中文名称 | Download Link | 使用位置 |
|-----------|---------|---------------|---------|
| chevron-left | 左箭头 | https://lucide.dev/icons/chevron-left | 返回按钮 |
| chevron-right | 右箭头 | https://lucide.dev/icons/chevron-right | 列表项右侧 |
| user | 用户 | https://lucide.dev/icons/user | 账户页面 |
| crown | 皇冠 | https://lucide.dev/icons/crown | 订阅计划 |
| database | 数据库 | https://lucide.dev/icons/database | 存储管理 |
| help-circle | 帮助圆圈 | https://lucide.dev/icons/help-circle | FAQ |
| log-out | 登出 | https://lucide.dev/icons/log-out | 退出登录 |
| trash-2 | 垃圾桶 | https://lucide.dev/icons/trash-2 | 删除/清理 |
| upload | 上传 | https://lucide.dev/icons/upload | 提交诊断日志 |
| mail | 邮件 | https://lucide.dev/icons/mail | 联系支持 |
| shield | 盾牌 | https://lucide.dev/icons/shield | 安全设置 |
| file-text | 文件文本 | https://lucide.dev/icons/file-text | 条款和隐私 |
| message-circle | 消息圆圈 | https://lucide.dev/icons/message-circle | 联系支持 |
| book | 书籍 | https://lucide.dev/icons/book | 用户指南 |
| download | 下载 | https://lucide.dev/icons/download | 导出数据 |
| lock | 锁 | https://lucide.dev/icons/lock | 隐私安全 |
| check | 对勾 | https://lucide.dev/icons/check | 成功状态 |
| x | 关闭 | https://lucide.dev/icons/x | 关闭按钮 |
| mic | 麦克风 | https://lucide.dev/icons/mic | 录音功能 |
| pause | 暂停 | https://lucide.dev/icons/pause | 暂停录音 |
| play | 播放 | https://lucide.dev/icons/play | 播放录音 |
| stop-circle | 停止圆圈 | https://lucide.dev/icons/stop-circle | 停止录音 |

#### Step 3: How to Use SVG in Flutter / 在 Flutter 中使用 SVG

安装 SVG 包：
```yaml
dependencies:
  flutter_svg: ^2.0.9
```

使用方法：
```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/user.svg',
  width: 20,
  height: 20,
  colorFilter: ColorFilter.mode(
    AppColors.primaryBlue,
    BlendMode.srcIn,
  ),
)
```

---

## ✍️ Part 3: Typography / 字体资源

### Create Typography File / 创建字体文件

创建文件：`lib/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font Family / 字体家族
  static const String fontFamily = 'SF Pro Text'; // iOS 使用系统字体
  
  // Headings / 标题
  static const TextStyle h1 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Body Text / 正文
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textTertiary,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textTertiary,
    height: 1.5,
  );
  
  static const TextStyle captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textTertiary,
    height: 1.5,
  );
  
  // Section Headers (Uppercase) / 章节标题（大写）
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  // Button Text / 按钮文字
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600, // Semibold
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
  );
  
  // Link Text / 链接文字
  static const TextStyle link = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.primaryBlue,
    decoration: TextDecoration.none,
  );
  
  // Badge Text / 徽章文字
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700, // Bold
    color: Colors.white,
    letterSpacing: 0.5,
    height: 1.2,
  );
}

// 字体大小快速参考表
class FontSizes {
  static const double xs = 11;
  static const double sm = 12;
  static const double base = 13;
  static const double md = 14;
  static const double lg = 15;
  static const double xl = 17;
  static const double xl2 = 20;
  static const double xl3 = 22;
  static const double xl4 = 26;
  static const double xl5 = 30;
}

// 字重快速参考
class FontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
```

### Using System Fonts / 使用系统字体

**iOS**：自动使用 SF Pro Text  
**Android**：自动使用 Roboto

不需要额外下载字体文件！

如果需要在 Android 上也使用 SF Pro：
1. 下载 SF Pro Text: https://developer.apple.com/fonts/
2. 放到 `assets/fonts/` 目录
3. 在 `pubspec.yaml` 配置：

```yaml
flutter:
  fonts:
    - family: SF Pro Text
      fonts:
        - asset: assets/fonts/SF-Pro-Text-Regular.otf
          weight: 400
        - asset: assets/fonts/SF-Pro-Text-Medium.otf
          weight: 500
        - asset: assets/fonts/SF-Pro-Text-Semibold.otf
          weight: 600
        - asset: assets/fonts/SF-Pro-Text-Bold.otf
          weight: 700
```

---

## 📐 Part 4: Spacing & Dimensions / 间距和尺寸

### Create Spacing File / 创建间距文件

创建文件：`lib/theme/app_spacing.dart`

```dart
class AppSpacing {
  // Base unit: 4px
  static const double unit = 4.0;
  
  // Common spacing values
  static const double xs = 2.0;   // 0.5 * unit
  static const double sm = 4.0;   // 1 * unit
  static const double md = 8.0;   // 2 * unit
  static const double lg = 12.0;  // 3 * unit
  static const double xl = 16.0;  // 4 * unit
  static const double xl2 = 20.0; // 5 * unit
  static const double xl3 = 24.0; // 6 * unit
  static const double xl4 = 32.0; // 8 * unit
  
  // Component specific spacing
  static const double buttonPaddingVertical = 12.0;
  static const double buttonPaddingHorizontal = 16.0;
  static const double cardPadding = 20.0;
  static const double modalPadding = 32.0;
  static const double pageHorizontal = 20.0;
  static const double pageBottom = 96.0;
  
  // Gaps
  static const double gapXS = 8.0;
  static const double gapSM = 12.0;
  static const double gapMD = 16.0;
  static const double gapLG = 24.0;
}

class AppBorderRadius {
  static const double small = 12.0;
  static const double medium = 13.0;
  static const double standard = 16.0;
  static const double large = 20.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
  
  // Component specific
  static const double button = 12.0;
  static const double buttonLarge = 13.0;
  static const double card = 16.0;
  static const double cardLarge = 20.0;
  static const double modal = 24.0;
  static const double avatar = 9999.0; // circular
  static const double toast = 16.0;
}

class AppIconSizes {
  static const double small = 16.0;   // w-4, h-4
  static const double medium = 20.0;  // w-5, h-5
  static const double large = 24.0;   // w-6, h-6
  static const double xl = 32.0;      // w-8, h-8
  
  // Icon container sizes
  static const double containerSmall = 32.0;   // w-8, h-8
  static const double containerMedium = 40.0;  // w-10, h-10
  static const double containerLarge = 48.0;   // w-12, h-12
  static const double containerXL = 64.0;      // w-16, h-16
}
```

---

## 🎨 Part 5: Gradients / 渐变色

### Create Gradient File / 创建渐变文件

创建文件：`lib/theme/app_gradients.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  // Icon Container Gradients (Diagonal)
  static const LinearGradient blue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
  );
  
  static const LinearGradient green = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
  );
  
  static const LinearGradient orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9500), Color(0xFFFF8000)],
  );
  
  static const LinearGradient red = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFD32F2F)],
  );
  
  static const LinearGradient purple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAF52DE), Color(0xFF9B3FCE)],
  );
  
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFB700)],
  );
  
  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF32ADE6), Color(0xFF1E96D4)],
  );
  
  static const LinearGradient gray = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E8E93), Color(0xFF636366)],
  );
  
  // Button Gradients (Horizontal)
  static const LinearGradient premiumPurple = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFAF52DE),
      Color(0xFFC86DD7),
      Color(0xFFAF52DE),
    ],
  );
  
  static const LinearGradient ultraOrange = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF9500),
      Color(0xFFFF8C42),
      Color(0xFFFF9500),
    ],
  );
  
  // Badge Gradient (Most Popular)
  static const LinearGradient mostPopular = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFFF8C42),
      Color(0xFFFFA94D),
    ],
  );
}
```

---

## 🛠️ Part 6: Complete Theme File / 完整主题文件

### Create Main Theme / 创建主题

创建文件：`lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 基础配置
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 颜色方案
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.lightBlue,
        error: AppColors.errorRed,
        surface: AppColors.backgroundPrimary,
        background: AppColors.backgroundSecondary,
      ),
      
      // 脚手架背景色
      scaffoldBackgroundColor: AppColors.backgroundSecondary,
      
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      // 文字主题
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h2,
        displayMedium: AppTextStyles.h3,
        displaySmall: AppTextStyles.h4,
        headlineLarge: AppTextStyles.h1,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonLarge,
        labelMedium: AppTextStyles.caption,
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        color: AppColors.backgroundPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      
      // 分隔线主题
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

---

## 📦 Part 7: Quick Start Guide / 快速开始指南

### Step 1: Create Theme Directory / 创建主题目录

```
lib/
  theme/
    app_colors.dart
    app_text_styles.dart
    app_spacing.dart
    app_gradients.dart
    app_icons.dart
    app_theme.dart
```

### Step 2: Install Dependencies / 安装依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  lucide_icons: ^0.400.0
  flutter_svg: ^2.0.9  # 如果使用 SVG 文件
```

运行：
```bash
flutter pub get
```

### Step 3: Apply Theme in main.dart / 在 main.dart 应用主题

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoPin',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
```

### Step 4: Use in Components / 在组件中使用

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: AppIconSizes.containerMedium,
            height: AppIconSizes.containerMedium,
            decoration: BoxDecoration(
              gradient: AppGradients.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.user,
              size: AppIconSizes.medium,
              color: Colors.white,
            ),
          ),
          
          SizedBox(width: AppSpacing.md),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: AppTextStyles.h4,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Subtitle',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          
          // Chevron
          Icon(
            AppIcons.chevronRight,
            size: AppIconSizes.medium,
            color: AppColors.textQuaternary,
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Part 8: Component Examples / 组件示例

### Primary Button / 主按钮

```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      vertical: AppSpacing.buttonPaddingVertical,
      horizontal: AppSpacing.buttonPaddingHorizontal,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppBorderRadius.button),
    ),
  ),
  child: Text(
    'Sign In',
    style: AppTextStyles.buttonLarge,
  ),
)
```

### Icon Container with Gradient / 渐变图标容器

```dart
Container(
  width: AppIconSizes.containerMedium,
  height: AppIconSizes.containerMedium,
  decoration: BoxDecoration(
    gradient: AppGradients.blue,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Icon(
    LucideIcons.user,
    size: AppIconSizes.medium,
    color: Colors.white,
  ),
)
```

### Card with Border / 带边框的卡片

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.cardPadding),
  decoration: BoxDecoration(
    color: AppColors.backgroundPrimary,
    borderRadius: BorderRadius.circular(AppBorderRadius.card),
    border: Border.all(
      color: AppColors.divider,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: YourContent(),
)
```

### Modal Dialog / 模态对话框

```dart
showDialog(
  context: context,
  barrierColor: AppColors.modalBackdrop,
  builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppBorderRadius.modal),
    ),
    child: Container(
      padding: EdgeInsets.all(AppSpacing.modalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(LucideIcons.x),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Icon
          Container(
            width: AppIconSizes.containerXL,
            height: AppIconSizes.containerXL,
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.upload,
              size: AppIconSizes.xl,
              color: AppColors.lightBlue,
            ),
          ),
          
          SizedBox(height: AppSpacing.xl),
          
          // Title
          Text(
            'Submit diagnostic logs?',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Description
          Text(
            'This will send technical logs from your device to help us investigate issues.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppSpacing.xl),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
```

---

## 📸 Part 9: How to Extract Images from Web / 如何从网页提取图片

### Method 1: Browser Developer Tools / 浏览器开发者工具

1. 在网页上**右键点击图片** → **检查（Inspect）**
2. 在 Elements 面板找到 `<img>` 标签
3. 右键点击 src 属性的 URL → **Open in new tab**
4. 右键保存图片

### Method 2: Screenshot / 截图方法

1. 在浏览器打开 MemoPin 应用
2. 使用截图工具截取需要的界面
3. 裁剪保存为 PNG 文件

### Method 3: Export from Code / 从代码导出

如果使用了 `figma:asset`，图片在网页的 Network 面板：
1. 打开浏览器 → F12 开发者工具
2. 切换到 **Network** 标签
3. 刷新页面
4. 找到图片文件 → 右键 → **Open in new tab** → 保存

---

## 🎨 Part 10: Shadow & Elevation / 阴影和层级

### Create Shadow File / 创建阴影文件

```dart
import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get xxl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 50,
      offset: const Offset(0, 20),
    ),
  ];
}

// 使用示例
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.medium,
  ),
)
```

---

## ✅ Part 11: Checklist for Developers / 开发者检查清单

开发每个页面时，请确认：

- [ ] 使用 `AppColors` 中的颜色
- [ ] 使用 `AppTextStyles` 中的文字样式
- [ ] 使用 `AppSpacing` 中的间距值
- [ ] 使用 `AppBorderRadius` 中的圆角值
- [ ] 使用 `lucide_icons` 包的图标
- [ ] 使用 `AppGradients` 中的渐变
- [ ] 添加 `AppShadows` 阴影效果
- [ ] 实现 hover/pressed 状态
- [ ] 添加过渡动画
- [ ] 确保键盘可访问性
- [ ] 测试响应式布局

---

## 🔗 Part 12: Useful Links / 有用的链接

### Icon Resources / 图标资源
- Lucide Icons: https://lucide.dev/icons/
- Lucide Flutter Package: https://pub.dev/packages/lucide_icons

### Flutter Resources / Flutter 资源
- Flutter Docs: https://docs.flutter.dev/
- Material Design 3: https://m3.material.io/
- Flutter SVG: https://pub.dev/packages/flutter_svg

### Design Tools / 设计工具
- Figma: https://www.figma.com/
- Color Picker: https://htmlcolorcodes.com/
- Gradient Generator: https://cssgradient.io/

### Font Resources / 字体资源
- SF Pro (Apple): https://developer.apple.com/fonts/
- Google Fonts: https://fonts.google.com/

---

## 📞 Part 13: Support / 技术支持

如果开发团队有任何问题：

1. **查看设计规范**：`DESIGN_SPECIFICATION.md`
2. **查看本指南**：`FLUTTER_DESIGN_RESOURCES.md`
3. **使用浏览器检查器**：在网页原型上右键 → 检查，查看实际实现
4. **查看代码**：Web 原型的源代码可以作为参考

---

## 🎯 Summary / 总结

### 开发团队现在拥有：

✅ **完整的颜色系统** - Dart 代码直接复制  
✅ **所有图标资源** - 图标包 + 下载链接  
✅ **字体样式定义** - 完整的 TextStyle 配置  
✅ **间距和尺寸** - 标准化的 spacing 值  
✅ **渐变定义** - 所有渐变色的 Dart 代码  
✅ **完整的主题文件** - 开箱即用的 ThemeData  
✅ **组件示例** - 常用组件的实现代码  
✅ **阴影系统** - BoxShadow 配置  
✅ **开发检查清单** - 确保设计一致性  

### 下一步：

1. ✅ 复制所有主题文件到 Flutter 项目
2. ✅ 安装 `lucide_icons` 包
3. ✅ 在 `main.dart` 应用主题
4. ✅ 开始开发页面，参考组件示例
5. ✅ 对照网页原型验证设计还原度

---

**文档版本**: 1.0  
**最后更新**: 2026-03-19  
**设计系统**: MemoPin ADHD-Friendly Mobile UI  
**目标平台**: Flutter (iOS & Android)

祝开发顺利！🚀