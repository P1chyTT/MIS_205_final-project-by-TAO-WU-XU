# 校园搭子拼单系统

> **课程**：MIS 205 — Data Management and Database (Spring 2026)  
> **项目类型**：期末项目 Part 2

---

## 项目简介

一个面向在校大学生的"找搭子+拼单"平台。用户可以发布帖子寻找一起学习/运动/吃饭的搭子，也可以发起拼单（如外卖拼单、团购凑单）并自动计算人均费用。

---

## 技术栈

- **前端**：HTML + CSS + JavaScript
- **后端**：Supabase（BaaS）
- **认证**：Supabase Auth
- **数据库**：PostgreSQL on Supabase
- **存储**：Supabase Storage
- **版本控制**：Git + GitHub

---

## 项目文件结构

```
.
├── README.md                           # 项目说明（本文件）
├── final-project/                      # 项目主文件夹
│   ├── index.html                      # 登录注册页面
│   ├── dashboard.html                  # 主页（帖子广场、发布/编辑/删除）
│   ├── profile.html                    # 用户中心
│   ├── spec.md                         # 项目规格说明书
│   ├── schema.sql                      # 数据库 schema
│   ├── migration_add_deadline.sql      # 截止时间功能迁移
│   ├── migration_add_images.sql        # 图片功能迁移
│   ├── migration_add_expenses_contact.sql # 费用和联系方式迁移
│   ├── 提交材料清单.md                 # 提交材料清单
│   ├── report.md                       # 报告框架
│   ├── 演示幻灯片大纲.md               # 演示大纲
│   ├── PR_DESCRIPTION_image_upload.md  # PR 描述
│   ├── test_image_upload.html          # 测试页面
│   └── 工作日志/                       # 开发日志
│       ├── 工作日志day1.md
│       ├── 工作日志day2.md
│       ├── 工作日志day3.md
│       └── 工作日志day4.md
├── course-materials/                   # 课程原始材料
│   ├── lab-data/
│   ├── scripts/
│   ├── skills/
│   ├── 期末项目说明/
│   └── dmdb-codespace-scaffold.sh
└── ...
```

---

## 核心功能

### 用户系统
- ✅ 用户注册/登录（Supabase Auth）
- ✅ 用户个人中心
- ✅ 个人资料修改

### 帖子管理
- ✅ 发布帖子（找搭子/拼单）
- ✅ 查看帖子列表（帖子广场）
- ✅ 编辑帖子
- ✅ 删除帖子
- ✅ 帖子筛选功能
- ✅ 图片上传功能

### 参与系统
- ✅ 参与帖子
- ✅ 退出参与
- ✅ 行程费用管理
- ✅ 联系方式功能

### 订单流程
- ✅ 订单完成流程
- ✅ 参与者确认完成
- ✅ 截止时间与自动取消

### 通知系统
- ✅ 有人参与通知
- ✅ 有人退出通知
- ✅ 组队成功通知
- ✅ 拼单账单通知
- ✅ 订单完成通知
- ✅ 帖子过期通知

### 用户中心
- ✅ 我的发帖
- ✅ 我的参与
- ✅ 我的收藏
- ✅ 消息中心
- ✅ 数据统计

---

## 数据库表结构

| 表名 | 说明 |
|------|------|
| profiles | 用户公开信息 |
| posts | 帖子信息 |
| participations | 参与记录 |
| favorites | 收藏记录 |
| notifications | 消息通知 |
| trip_expenses | 行程费用 |

---

## GitHub 工作流

### 分支
- `main` — 主分支
- `auth` — 认证功能分支
- `feat/auth` — 认证功能分支
- `feat/image-upload` — 图片上传功能分支
- `feat/join-manage` — 参与管理功能分支
- `feat/order-crud` — 订单 CRUD 功能分支

### Pull Requests
- PR：添加帖子图片上传功能（从 feat/image-upload 到 main）

---

## 如何运行

1. 在 Supabase 上创建项目
2. 运行 `final-project/schema.sql` 初始化数据库
3. 运行迁移脚本（如果需要）
4. 在 `index.html` 中配置 Supabase URL 和 Anon Key
5. 用浏览器打开 `index.html`

---

## 提交材料

- [x] 项目代码
- [x] spec.md
- [x] schema.sql
- [x] 工作日志
- [ ] PDF 报告
- [ ] 演示幻灯片

---

## 小组成员

- [填写姓名] - [填写学号]
- [填写姓名] - [填写学号]（如果有）

---

## 课程材料

原始课程材料请查看 `course-materials/` 文件夹。
