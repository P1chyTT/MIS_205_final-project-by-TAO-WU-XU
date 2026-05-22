# 工作日志 Day 3

**日期**：2026-05-22
**项目名称**：校园搭子拼单系统
**工作阶段**：帖子编辑与删除功能完善

---

## 一、今日工作成果

### 1. 帖子编辑功能 ✅
- 在自己发布的帖子卡片上新增「编辑」按钮
- 点击编辑后自动填充表单，支持修改所有字段
- 编辑模式下标题显示为「编辑帖子」，提交按钮显示为「保存修改」
- 更新时验证用户权限，确保只能修改自己的帖子
- 保存成功后返回帖子广场

### 2. 帖子删除功能 ✅
- 在自己发布的帖子卡片上新增「删除」按钮
- 删除前有确认弹窗，防止误操作
- 删除时验证用户权限，确保只能删除自己的帖子
- 删除成功后自动刷新帖子列表

### 3. UI 优化 ✅
- 新增编辑按钮样式（`.edit-btn`）- 蓝色边框按钮
- 新增删除按钮样式（`.delete-btn`）- 红色边框按钮
- 新增帖子操作容器（`.post-actions`）- 横向排列按钮
- 编辑/发布模式下标题和按钮文字自动切换
- 优化了按钮间距和悬停效果

### 4. 代码逻辑完善 ✅
- 新增 `resetForm()` 函数 - 重置表单到初始状态
- 新增 `submitPost()` 函数 - 根据模式选择新增或更新
- 新增 `updatePost()` 函数 - 更新帖子内容
- 新增 `editPost()` 函数 - 加载帖子并进入编辑模式
- 新增 `deletePost()` 函数 - 删除帖子
- 保留了所有原有的功能和安全性验证

---

## 二、技术实现细节

### 编辑功能流程
1. 用户点击「编辑」按钮
2. 前端从 Supabase 加载帖子详情
3. 填充表单字段（标题、描述、地点、时间、金额等）
4. 用户修改后点击「保存修改」
5. 前端发送 UPDATE 请求到 Supabase
6. 更新成功后返回帖子广场

### 删除功能流程
1. 用户点击「删除」按钮
2. 显示确认弹窗：「确定要删除这个帖子吗？此操作无法撤销。」
3. 用户确认后发送 DELETE 请求
4. 删除成功后刷新帖子列表

### 安全性
- 所有操作都验证 `user_id`，确保只能修改/删除自己的帖子
- Supabase RLS 策略在后端提供额外保障

---

## 三、代码提交记录

```bash
git add final-project/dashboard.html
git add final-project/工作日志/工作日志day3.md
git commit -m "feat: 添加帖子编辑和删除功能"
```

---

## 四、后续追加内容（同属 Day 3 工作）

### 用户中心功能开发
- 新建 `profile.html` — 用户中心页面
- 左侧边栏展示用户头像、用户名、邮箱、注册时间
- 右侧内容区采用标签页切换不同功能模块
- 总览模块展示四项核心数据统计卡片（我的发帖数、我的参与数、拼单次数、找搭子次数）
- 展示最近发布的 3 条帖子，支持快速编辑/删除
- 我的发帖模块展示当前用户发布的所有帖子，支持直接编辑和删除操作
- 我的参与模块展示当前用户参与的所有帖子，支持点击标题跳转到帖子广场
- 个人资料模块支持修改用户名，保存时同步更新 `profiles` 表和 `user_metadata`
- Dashboard 点击顶部用户名可跳转到用户中心，用户中心点击标题可返回 Dashboard
- 从用户中心点击「编辑」跳转到 Dashboard，通过 URL 参数 `?edit=postId` 传递帖子 ID

**数据库更新：**
```sql
CREATE POLICY "用户可更新自己的资料" ON profiles
    FOR UPDATE USING (auth.uid() = id);
```

**提交记录：**
```bash
git add final-project/profile.html final-project/dashboard.html final-project/schema.sql
git commit -m "feat: 添加用户中心（我的发帖、我的参与、个人资料、数据统计）"
git push origin main
```

### 消息中心与收藏功能
- 新增 `favorites`（收藏）表，字段：`id`, `user_id`, `post_id`, `created_at`，同一用户不能重复收藏同一帖子
- 新增 `notifications`（消息通知）表，字段：`id`, `user_id`, `type`, `title`, `content`, `post_id`, `is_read`, `created_at`
- 新增触发器 `on_participation_insert` — 有人参与帖子时自动通知帖子作者
- 新增触发器 `on_participation_delete` — 有人退出帖子时自动通知帖子作者
- Dashboard 帖子卡片新增 ⭐ 收藏按钮（空心/实心状态切换），仅对非自己的帖子显示
- 顶部导航栏新增 🔔 消息图标，显示未读消息数量小红点
- 用户中心总览统计新增我的收藏数、未读消息数
- 我的收藏页面展示所有收藏的帖子，支持取消收藏
- 消息中心页面展示所有消息通知（按时间倒序），未读消息高亮显示（蓝色左边框），点击消息标记为已读并跳转到对应帖子
- 消息类型图标：👋 参与 / 👋 退出 / ✅ 满员 / 📢 系统

**提交记录：**
```bash
git add final-project/profile.html final-project/dashboard.html final-project/schema.sql
git commit -m "feat: 添加消息中心和收藏功能"
git push origin main
```

### 消息中心功能增强
- 新增 `full` 消息类型 — 组队成功（帖子满员）
- 新增 `bill` 消息类型 — 拼单账单通知
- 当帖子人数达到上限时，自动通知帖子作者「组队成功！你的帖子已满员」
- 拼单类型帖子满员时，自动计算人均金额 `ROUND(total_amount / max_people, 2)`
- 给所有参与者发送付款通知（包含总金额、人均金额、发起人姓名）
- 给发起人发送收款通知
- 消息图标映射新增 `bill: '💰'`，消息类型标签映射新增 `bill: '账单'`

**消息触发场景总结：**

| 场景 | 消息类型 | 接收人 | 内容 |
|------|---------|--------|------|
| 有人参与你的帖子 | `join` | 帖子作者 | xxx 参与了你的帖子「标题」 |
| 有人退出你的帖子 | `leave` | 帖子作者 | xxx 退出了你的帖子「标题」 |
| 帖子人数满员 | `full` | 帖子作者 | 组队成功！你的帖子已满员 |
| 拼单满员 | `bill` | 所有参与者 | 拼单账单：请付款 ¥xx |
| 拼单满员 | `bill` | 发起人 | 拼单账单：请收款 ¥xx |

**提交记录：**
```bash
git add final-project/profile.html final-project/schema.sql
git commit -m "feat: 增强消息中心，添加组队成功和拼单账单通知"
git push origin main
```

### 订单完成流程重构 + 筛选功能
- 订单状态流程重构为五步：`open（招募中）→ closed（已满员）→ completed（待确认）→ finished（已结束）`
- `posts.status` 扩展为四种状态：`open`, `closed`, `completed`, `finished`
- `participations` 表新增 `is_confirmed` 字段（默认 false）
- `notifications` 表新增 `confirm` 类型
- 新增存储函数 `complete_order(post_id)` — 发起人完成订单，发送账单通知给所有参与者，发送收款通知给发起人
- 新增存储函数 `confirm_participation(post_id, user_id)` — 参与者确认完成，全部确认后更新帖子状态为 `finished`
- Dashboard 按钮更新：发起人视角（招募中→编辑/删除，已满员→✓订单完成），参与者视角（待确认→确认完成，已确认→已确认标签）
- 新增样式 `.complete-btn`（绿色）、`.confirm-btn`（蓝色）、`.status-completed`（绿色标签）、`.status-finished`（灰色标签）
- 帖子广场新增筛选栏：关键词搜索、类型、状态、金额、时间、人数、排序
- 筛选条件支持多选组合，选择「找搭子」时自动隐藏金额筛选，实时显示筛选结果数量

**提交记录：**
```bash
git add final-project/dashboard.html final-project/profile.html final-project/schema.sql
git commit -m "feat: 重构订单完成流程，添加订单完成和确认完成功能"
git push origin main

git add final-project/dashboard.html
git commit -m "feat: 添加帖子筛选功能（类型、状态、金额、时间、人数、排序）"
git push origin main
```

### 帖子截止时间（Deadline）与自动取消
- 为所有帖子新增「截止时间」字段 `deadline TIMESTAMPTZ`
- 超过截止时间后，如果帖子人数未满（`status` 为 `open` 或 `closed`），帖子自动取消
- `posts.status` 扩展为五种状态：`open`, `closed`, `completed`, `finished`, `cancelled`
- `notifications.type` 新增 `expired` 类型
- 新增存储函数 `check_expired_posts()` — 扫描过期帖子，自动取消并通知帖主和参与者
- 发布/编辑表单新增「截止时间」输入框（`datetime-local`），为必填项，找搭子和拼单都支持
- 帖子卡片显示截止时间：⏰ 截止 YYYY-MM-DD HH:mm（过期红色，未过期蓝色）
- 状态筛选新增「已取消」选项，「即将截止」排序改为按 `deadline` 升序
- 用户中心消息中心新增 `expired` 类型图标 ⏰ 和标签「过期」

**调用方式（建议通过 Supabase Cron 或外部定时任务每分钟调用）：**
```sql
SELECT check_expired_posts();
```

**提交记录：**
```bash
git add final-project/dashboard.html final-project/profile.html final-project/schema.sql final-project/migration_add_deadline.sql
git commit -m "feat: 添加帖子截止时间与自动取消功能"
git push origin main
```

---

## 五、备注

- 当前代码位于 `main` 分支
- 功能已完整测试，编辑和删除操作正常
- 保持了与现有功能的兼容性
- 以后的新改动继续追加到本文件中
