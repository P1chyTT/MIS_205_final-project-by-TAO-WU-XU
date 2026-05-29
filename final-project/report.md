# MIS205 期末项目 Part 2 报告

## 组员信息
- **姓名**：[填写姓名]
- **学号**：[填写学号]
- **班级**：[填写班级]

---

## GitHub 仓库链接
[填写 GitHub 公开仓库链接]

---

## 项目简介
校园搭子拼单系统 — 一个面向在校大学生的"找搭子+拼单"平台。

---

## 技术栈
- **前端**：HTML + CSS + JavaScript
- **后端**：Supabase（BaaS）
- **认证**：Supabase Auth
- **数据库**：PostgreSQL on Supabase
- **存储**：Supabase Storage
- **版本控制**：Git + GitHub

---

## 截图

### 1. 注册页面
[插入注册页面截图]

### 2. 登录页面
[插入登录页面截图]

### 3. 创建帖子（Create）
[插入创建帖子截图]

### 4. 查看帖子列表（Read）
[插入帖子列表截图]

### 5. 编辑帖子（Update）
[插入编辑帖子截图]

### 6. 删除帖子（Delete）
[插入删除帖子截图]

---

## 最终 ER 图
[插入 ER 图]

---

## 数据库表结构

### profiles（用户公开信息）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID PK | 用户唯一标识 |
| username | VARCHAR(50) | 用户名 |
| created_at | TIMESTAMP | 创建时间 |

### posts（帖子）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 帖子编号 |
| user_id | UUID FK | 发布者 |
| author_name | VARCHAR(50) | 发布者用户名 |
| type | VARCHAR(10) | 帖子类型 |
| title | VARCHAR(100) | 帖子标题 |
| description | TEXT | 帖子描述 |
| location | VARCHAR(100) | 地点 |
| meet_time | TIMESTAMP | 见面时间 |
| total_amount | DECIMAL(10,2) | 总金额 |
| max_people | INT | 最大人数 |
| current_people | INT | 当前人数 |
| status | VARCHAR(10) | 状态 |
| deadline | TIMESTAMPTZ | 截止时间 |
| image_url | TEXT | 主图URL |
| image_urls | TEXT[] | 图片URL数组 |
| contact_type | VARCHAR(10) | 联系方式类型 |
| contact_info | VARCHAR(100) | 联系方式 |
| created_at | TIMESTAMP | 创建时间 |

### participations（参与记录）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 记录编号 |
| post_id | INT FK | 帖子ID |
| user_id | UUID FK | 用户ID |
| is_confirmed | BOOLEAN | 是否已确认 |
| joined_at | TIMESTAMP | 加入时间 |

### favorites（收藏记录）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 记录编号 |
| user_id | UUID FK | 用户ID |
| post_id | INT FK | 帖子ID |
| created_at | TIMESTAMP | 创建时间 |

### notifications（消息通知）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 通知编号 |
| user_id | UUID FK | 用户ID |
| type | VARCHAR(20) | 通知类型 |
| title | VARCHAR(100) | 通知标题 |
| content | TEXT | 通知内容 |
| post_id | INT FK | 帖子ID |
| is_read | BOOLEAN | 是否已读 |
| created_at | TIMESTAMP | 创建时间 |

### trip_expenses（行程费用）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PK | 费用编号 |
| post_id | INT FK | 帖子ID |
| name | VARCHAR(100) | 费用名称 |
| amount | DECIMAL(10,2) | 金额 |
| note | TEXT | 备注 |
| created_at | TIMESTAMP | 创建时间 |

---

## 项目功能列表

### 核心功能
- ✅ 用户注册/登录
- ✅ 发布帖子（找搭子/拼单）
- ✅ 查看帖子列表
- ✅ 编辑帖子
- ✅ 删除帖子
- ✅ 参与帖子
- ✅ 退出参与
- ✅ 订单完成流程
- ✅ 参与者确认完成
- ✅ 帖子筛选
- ✅ 截止时间与自动取消
- ✅ 图片上传
- ✅ 行程费用管理
- ✅ 联系方式功能

### 用户中心
- ✅ 我的发帖
- ✅ 我的参与
- ✅ 我的收藏
- ✅ 消息中心
- ✅ 个人资料
- ✅ 数据统计

### 通知系统
- ✅ 有人参与通知
- ✅ 有人退出通知
- ✅ 组队成功通知
- ✅ 拼单账单通知
- ✅ 订单完成通知
- ✅ 帖子过期通知

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

## 演示准备

### 演示结构
1. 1 分钟：问题与目标用户
2. 2 分钟：现场演示（CRUD + 认证）
3. 1 分钟：工作顺利的地方，遇到的困难
4. 1 分钟：AI 工具使用反思

### 演示内容
- 注册/登录
- 发布帖子
- 查看帖子列表
- 编辑帖子
- 删除帖子
- 用户中心
- 消息中心

---

## 反思

### 工作顺利的地方
[填写内容]

### 遇到的困难
[填写内容]

### AI 工具使用反思
[填写内容]
