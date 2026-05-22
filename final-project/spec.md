# 校园搭子拼单系统 — 项目规格说明书

## 项目简介

一个面向在校大学生的"找搭子+拼单"平台。用户可以发布帖子寻找一起学习/运动/吃饭的搭子，也可以发起拼单（如外卖拼单、团购凑单）并自动计算人均费用。

**目标用户**：在校大学生

---

## 实体与属性

### 1. 用户公开信息（profiles）

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | UUID PK → auth.users.id | 用户唯一标识 |
| `username` | VARCHAR(50) NOT NULL | 用户名 |
| `created_at` | TIMESTAMP DEFAULT NOW() | 创建时间 |

> 此表通过 Trigger 在用户注册时自动创建。解决 Supabase anon key 无法直接查询 `auth.users` 表的问题。

### 2. 帖子（posts）

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | SERIAL PK | 帖子编号 |
| `user_id` | UUID FK → auth.users.id | 发布者 |
| `author_name` | VARCHAR(50) NOT NULL | 发布者用户名（冗余存储，便于展示） |
| `type` | VARCHAR(10) NOT NULL | 帖子类型：`buddy`（找搭子）或 `groupbuy`（拼单） |
| `title` | VARCHAR(100) NOT NULL | 帖子标题 |
| `description` | TEXT | 帖子详细描述 |
| `location` | VARCHAR(100) | 地点（找搭子用） |
| `meet_time` | TIMESTAMP | 见面时间（找搭子用） |
| `total_amount` | DECIMAL(10,2) | 总消费金额（拼单用） |
| `max_people` | INT NOT NULL DEFAULT 2 | 最大参与人数 |
| `current_people` | INT NOT NULL DEFAULT 1 | 已参与人数（含发布者） |
| `status` | VARCHAR(10) DEFAULT 'open' | 状态：`open`（招募中）/ `closed`（已满/已结束） |
| `created_at` | TIMESTAMP DEFAULT NOW() | 创建时间 |

### 3. 参与记录（participations）

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | SERIAL PK | 记录编号 |
| `post_id` | INT FK → posts.id ON DELETE CASCADE | 所属帖子 |
| `user_id` | UUID FK → auth.users.id | 参与者 |
| `joined_at` | TIMESTAMP DEFAULT NOW() | 参与时间 |

---

## 实体关系

```
auth.users ──1─── profiles（1:1，Trigger 自动创建）
auth.users ──1───< posts >───1───< participations >───1─── auth.users
```

- 一个用户可发布多条帖子（1:N）
- 一个帖子可有多个参与记录（1:N）
- 一个用户可参与多条帖子（1:N）
- 参与记录是 users 和 posts 之间的多对多关系桥接表

---

## ER 图（文字版）

```
┌────────────────┐                                                         
│  auth.users    │──1:1──┌─────────────────┐                               
│  id (PK, UUID) │       │    profiles      │                               
│  email         │       │  id (PK FK)      │                               
│  ...           │       │  username        │                               
└────────────────┘       └─────────────────┘                               
        │                                                                  
        │ 1:N                                                              
        ▼                                                                  
┌──────────────────────┐         ┌──────────────────────┐                  
│        posts         │──1:N───││   participations     │                  
├──────────────────────┤         ├──────────────────────┤                  
│ id (PK, SERIAL)      │         │ id (PK, SERIAL)      │                  
│ user_id (FK)          │         │ post_id (FK)          │                  
│ author_name           │         │ user_id (FK)          │                  
│ type                  │         │ joined_at             │                  
│ title                 │         └──────────────────────┘                  
│ description           │                                                  
│ location              │                                                  
│ meet_time             │                                                  
│ total_amount          │                                                  
│ max_people            │                                                  
│ current_people        │                                                  
│ status                │                                                  
│ created_at            │                                                  
└──────────────────────┘
```

---

## 用户流程

### 流程 1：注册与登录
1. 用户访问首页 → 切换到注册标签
2. 填写用户名、邮箱、密码 → 提交
3. Supabase Auth 创建账户并发送确认邮件（可选）
4. 用户使用邮箱+密码登录 → 跳转到 Dashboard

### 流程 2：发布找搭子帖子
1. 已登录用户在 Dashboard 点击"发布帖子"
2. 选择类型「找搭子」，填写标题、描述、地点、见面时间、需要人数
3. 点击提交 → 帖子保存到 `posts` 表
4. 帖子出现在广场列表中，其他人可见

### 流程 3：发布拼单帖子
1. 已登录用户点击"发布帖子" → 选择类型「拼单」
2. 填写标题、描述、总消费金额、分摊人数
3. 系统自动计算人均费用（总金额 ÷ 人数）
4. 提交后帖子出现在广场
5. 其他人看到帖子后可点击"参与拼单"

### 流程 4：浏览广场与参与
1. 任何已登录用户可在 Dashboard 看到所有帖子列表
2. 帖子按创建时间倒序排列
3. 根据帖子类型显示不同信息（搭子=地点+时间 / 拼单=金额+人均）
4. 用户可以点击"参与"加入拼单或搭子（状态为 open 且未满员）
5. 满员后帖子状态变为 `closed`

---

## 技术选型

- **前端**：HTML + CSS + JavaScript（纯原生）
- **后端**：Supabase（BaaS）
  - Supabase Auth：用户认证
  - Supabase Database：PostgreSQL 数据存储
  - Supabase JS Client v2：前端 API 调用
- **部署**：静态页面托管（GitHub Pages 或本地运行）
