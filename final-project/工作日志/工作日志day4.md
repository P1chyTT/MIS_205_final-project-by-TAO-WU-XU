# 工作日志 Day 4

**日期**：2026-05-22  
**项目名称**：校园搭子拼单系统  
**工作阶段**：用户中心功能开发

---

## 一、今日工作成果

### 1. 用户中心页面 ✅
- 新建 `profile.html` — 用户中心页面
- 左侧边栏展示用户头像、用户名、邮箱、注册时间
- 右侧内容区采用标签页切换不同功能模块

### 2. 总览模块 ✅
- 展示四项核心数据统计卡片：
  - 我的发帖数
  - 我的参与数
  - 拼单次数
  - 找搭子次数
- 展示最近发布的 3 条帖子，支持快速编辑/删除

### 3. 我的发帖模块 ✅
- 展示当前用户发布的所有帖子
- 每条帖子显示完整信息（标题、类型、状态、人数等）
- 支持直接编辑和删除操作
- 空状态提示「还没有发布过帖子」

### 4. 我的参与模块 ✅
- 展示当前用户参与的所有帖子
- 显示参与时间和帖子详情
- 支持点击标题跳转到帖子广场
- 空状态提示「还没有参与过任何帖子」

### 5. 个人资料模块 ✅
- 支持修改用户名
- 展示邮箱（只读）
- 展示注册时间（只读）
- 保存时同步更新 `profiles` 表和 `user_metadata`

### 6. Dashboard 导航优化 ✅
- 点击顶部用户名可跳转到用户中心
- 用户名添加下划线样式，提示可点击
- 用户中心点击标题可返回 Dashboard

### 7. 编辑帖子流程优化 ✅
- 从用户中心点击「编辑」跳转到 Dashboard
- 通过 URL 参数 `?edit=postId` 传递帖子 ID
- Dashboard 自动加载帖子数据并进入编辑模式
- 编辑完成后清除 URL 参数

---

## 二、技术实现细节

### 页面结构
```
profile.html
├── Sidebar（左侧边栏）
│   ├── 用户信息卡片（头像、用户名、邮箱、注册时间）
│   └── 菜单列表（总览、我的发帖、我的参与、个人资料）
└── Main Content（右侧内容）
    ├── 总览（统计卡片 + 最近发帖）
    ├── 我的发帖（完整帖子列表）
    ├── 我的参与（参与记录列表）
    └── 个人资料（编辑表单）
```

### 核心函数
- `loadProfile()` — 加载用户资料
- `saveProfile()` — 保存用户名修改
- `loadStats()` — 加载统计数据
- `loadMyPosts()` — 加载我的发帖
- `loadMyParticipations()` — 加载我的参与
- `renderPostCard()` — 渲染帖子卡片（复用 dashboard 样式）
- `switchTab()` — 切换标签页
- `loadPostForEdit()` — 从 URL 参数加载帖子编辑（dashboard）

### 数据库更新
- 新增 `profiles` 表 UPDATE 策略：
  ```sql
  CREATE POLICY "用户可更新自己的资料" ON profiles
      FOR UPDATE USING (auth.uid() = id);
  ```

---

## 三、代码提交记录

```bash
git add final-project/profile.html
git add final-project/dashboard.html
git add final-project/schema.sql
git add final-project/工作日志/工作日志day4.md
git commit -m "feat: 添加用户中心（我的发帖、我的参与、个人资料、数据统计）"
git push origin main
```

---

## 四、下一步计划

### Day 5 预计工作
1. **消息中心** — 新增 `notifications` 表，实现系统通知（有人参与/退出我的帖子）
2. **帖子收藏** — 新增 `favorites` 表，支持收藏感兴趣的帖子
3. **用户互评** — 参与完成后可评价搭子/拼单伙伴

---

## 五、备注

- 用户中心页面完全复用了 dashboard 的帖子卡片样式，保持视觉一致性
- 所有操作均通过 Supabase RLS 验证权限
- 编辑帖子时处理了 `datetime-local` 输入框的格式转换（`slice(0, 16)`）
- 代码已推送到 `main` 分支
