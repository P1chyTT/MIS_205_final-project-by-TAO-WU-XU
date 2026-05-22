# 工作日志 Day 1

**日期**：2026-05-19  
**项目名称**：校园搭子拼单系统  
**工作阶段**：项目初始化 - 登录注册功能

---

## 一、项目要求回顾

### 整体项目（MIS 205 期末项目 Part 2）
- **项目名称**：校园搭子拼单系统
- **技术栈**：Supabase（后端） + HTML/CSS/JS（前端）
- **目标用户**：在校大学生
- **核心功能**：
  1. 用户注册/登录系统
  2. 发布寻找搭子和拼单的帖子
  3. 查看帖子并参与拼单
  4. 消费金额编辑与平均分摊

### 技术要求
- 使用 Supabase Auth 进行用户认证（不存储明文密码）
- 至少 2 个数据表，包含外键关系
- 完整的 CRUD 操作
- GitHub 协作工作流（可选加分项）

---

## 二、今日工作成果

### 1. 项目结构搭建
```
final-project/
├── index.html          # 登录注册页面
├── dashboard.html      # 登录成功后主页
└── 工作日志/
    └── 工作日志day1.md  # 本文档
```

### 2. 登录注册页面（index.html）
- ✅ 美观的渐变色 UI 设计
- ✅ 登录/注册标签切换功能
- ✅ 表单验证（密码确认等）
- ✅ Supabase 认证集成
- ✅ Supabase 配置区域（支持在页面上直接配置）
- ✅ 配置信息本地存储（localStorage）
- ✅ 成功/错误消息提示

### 3. Dashboard 页面（dashboard.html）
- ✅ 登录状态检查（未登录自动跳转）
- ✅ 用户信息显示
- ✅ 退出登录功能
- ✅ 简洁的欢迎界面

### 4. 代码提交与版本控制
- ✅ 创建 `auth` 分支
- ✅ 提交登录注册功能代码
- ✅ 推送到 GitHub 远程仓库

---

## 三、技术实现细节

### Supabase 集成
- 使用 Supabase JavaScript Client v2
- `signUp()` - 用户注册
- `signInWithPassword()` - 用户登录
- `signOut()` - 用户退出
- `getUser()` - 获取当前用户信息

### 配置管理
- 移除外部 config.js 文件，避免跨域问题
- 使用 localStorage 存储 Supabase URL 和 Anon Key
- 页面加载时自动读取保存的配置

### 问题解决
1. **按钮无响应** - 改用 HTML 元素的 onclick 属性直接绑定
2. **Supabase 重复声明** - 使用单个全局变量
3. **跨域问题** - 移除外部配置文件，使用 localStorage

---

## 四、下一步计划

### Day 2 预计工作
1. 设计数据库表结构
   - users 表（用户信息）
   - posts 表（帖子信息）
   - participations 表（参与记录）
   
2. 创建 Supabase 数据表
3. 实现帖子发布功能（Create）
4. 实现帖子列表展示（Read）

---

## 五、备注

- 当前代码位于 GitHub 的 `auth` 分支
- 每个使用者需要在页面底部配置自己的 Supabase 项目信息
- Supabase 项目需要启用 Email 认证功能
