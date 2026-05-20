# 工作日志 Day 2

**日期**：2026-05-20  
**项目名称**：校园搭子拼单系统  
**工作阶段**：数据库设计 + 帖子广场与发布功能

---

## 一、今日工作成果

### 1. 项目规格说明书（spec.md）
- ✅ 完成项目简介与目标用户描述
- ✅ 定义 3 个实体：profiles、posts、participations
- ✅ 明确实体关系与外键（1:N）
- ✅ 编写 4 个用户流程
- ✅ 绘制文字版 ER 图

### 2. 数据库 Schema 设计（schema.sql）
- ✅ **profiles 表** — 用户公开信息，注册时通过 Trigger 自动创建
- ✅ **posts 表** — 帖子信息，支持两种类型（buddy / groupbuy）
- ✅ **participations 表** — 参与记录，UNIQUE 约束防止重复参与
- ✅ **RLS 策略** — 所有表启用行级安全
- ✅ **存储函数** — increment_participants / decrement_participants
- ✅ 索引优化（user_id, status, created_at, post_id）

### 3. Dashboard 重写（dashboard.html）
- ✅ **帖子广场** — 卡片式列表，按时间倒序
  - 显示类型标签（找搭子/拼单/已结束）
  - 找搭子显示地点 + 见面时间
  - 拼单显示总金额 + 人均（自动计算）
  - 参与人数进度（已参与 / 总人数）
- ✅ **发布帖子** — 支持两种模式切换
  - 找搭子：标题、描述、地点、见面时间
  - 拼单：标题、描述、总金额、实时计算人均
- ✅ **参与/退出** — 一人一票，满员自动关闭
- ✅ 权限控制：自己的帖子不可参与，满员不可参与

---

## 二、技术实现细节

### 数据库要点
- `profiles` 表解决 Supabase anon key 无法查询 `auth.users` 的限制
- `handle_new_user()` trigger 在用户注册时自动创建 profile 记录
- 参与人数通过 PostgreSQL 存储函数原子更新，自动判断满员状态
- RLS 策略确保用户只能修改自己的数据

### 前端要点
- 纯 HTML + CSS + JS，无框架依赖
- Supabase JS Client v2 进行所有数据库操作
- 参与记录本地缓存（Set），避免重复请求

---

## 三、下一步计划

### Day 3 预计工作
1. 完善 CRUD — 帖子编辑和删除功能
2. 增加帖子详情页/弹窗
3. 帖子筛选（按类型、状态）
4. 用户个人页面（我发布的 / 我参与的）

---

## 四、代码提交

- ✅ 提交至 `auth` 分支
- ✅ 推送到 GitHub 远程仓库
- Commit: `feat: 添加帖子发布与广场功能，包含spec和数据库schema`
