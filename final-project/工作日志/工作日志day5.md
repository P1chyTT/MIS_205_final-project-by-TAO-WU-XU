# 工作日志 Day 5

**日期**：2026-05-22  
**项目名称**：校园搭子拼单系统  
**工作阶段**：消息中心与收藏功能开发

---

## 一、今日工作成果

### 1. 数据库更新 ✅
- 新增 `favorites`（收藏）表：
  - 字段：`id`, `user_id`, `post_id`, `created_at`
  - 唯一约束：同一用户不能重复收藏同一帖子
  - RLS 策略：任何人可查看，登录用户可添加/删除自己的收藏
- 新增 `notifications`（消息通知）表：
  - 字段：`id`, `user_id`, `type`, `title`, `content`, `post_id`, `is_read`, `created_at`
  - 类型约束：`join`, `leave`, `full`, `system`
  - RLS 策略：用户可查看/更新自己的消息
- 新增触发器：
  - `on_participation_insert` — 有人参与帖子时，自动通知帖子作者
  - `on_participation_delete` — 有人退出帖子时，自动通知帖子作者

### 2. Dashboard 收藏功能 ✅
- 帖子卡片新增 ⭐ 收藏按钮（空心/实心状态切换）
- 点击收藏/取消收藏，实时更新按钮样式
- 登录时自动加载用户的收藏列表
- 仅对非自己的帖子显示收藏按钮

### 3. Dashboard 消息入口 ✅
- 顶部导航栏新增 🔔 消息图标
- 显示未读消息数量小红点
- 点击跳转到用户中心消息中心页面

### 4. 用户中心增强 ✅
- **总览统计**新增：
  - 我的收藏数
  - 未读消息数
- **我的收藏**页面：
  - 展示所有收藏的帖子
  - 支持取消收藏
  - 点击标题跳转到 Dashboard
- **消息中心**页面：
  - 展示所有消息通知（按时间倒序）
  - 未读消息高亮显示（蓝色左边框）
  - 点击消息标记为已读并跳转到对应帖子
  - 消息类型图标：👋 参与 / 👋 退出 / ✅ 满员 / 📢 系统
- 侧边栏消息入口显示未读数量徽章

### 5. 代码优化 ✅
- `profile.html` 支持 URL 参数 `?tab=` 直接切换标签页
- 消息卡片点击后自动更新未读数
- 收藏和参与按钮使用 `stopPropagation` 防止触发卡片点击

---

## 二、技术实现细节

### 触发器逻辑
```sql
-- 有人参与时通知帖子作者
INSERT INTO notifications (user_id, type, title, content, post_id)
VALUES (post_author, 'join', '有人参与了你的帖子', 'xxx 参与了你的帖子「标题」', post_id);

-- 有人退出时通知帖子作者
INSERT INTO notifications (user_id, type, title, content, post_id)
VALUES (post_author, 'leave', '有人退出了你的帖子', 'xxx 退出了你的帖子「标题」', post_id);
```

### 前端状态管理
- `myFavorites` — Set 结构，快速判断帖子是否已收藏
- `notificationsData` — 数组，存储消息列表
- 未读数实时计算：`notificationsData.filter(n => !n.is_read).length`

---

## 三、代码提交记录

```bash
git add final-project/profile.html
git add final-project/dashboard.html
git add final-project/schema.sql
git add final-project/工作日志/工作日志day5.md
git commit -m "feat: 添加消息中心和收藏功能"
git push origin main
```

---

## 四、下一步计划

### Day 6 预计工作（可选）
1. **帖子搜索** — 按标题/内容/地点搜索帖子
2. **帖子筛选** — 按类型、状态、时间筛选
3. **用户互评** — 参与完成后可评价搭子/拼单伙伴
4. **帖子详情页** — 独立的帖子详情页面，展示所有参与者

---

## 五、备注

- 消息通知通过 PostgreSQL 触发器自动创建，无需前端额外操作
- 收藏功能使用 `UNIQUE(user_id, post_id)` 防止重复收藏
- 所有数据库操作均通过 RLS 策略验证权限
- 代码已推送到 `main` 分支
