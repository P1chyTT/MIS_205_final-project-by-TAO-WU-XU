# 工作日志 Day 4

**日期**：2026-05-25
**项目名称**：校园搭子拼单系统
**工作阶段**：帖子功能增强 - 图片、费用、联系方式

---

## 一、今日工作成果

### 1. 帖子图片上传功能 ✅
- 发布/编辑帖子时新增图片上传区域
- 支持拖拽和点击上传图片
- 实时预览上传的图片
- 可以删除单张或清空所有图片
- 帖子卡片显示首张图片，多图显示数量徽章
- 点击图片可查看全屏画廊，支持左右切换

### 2. 行程费用管理功能 ✅
- 帖子详情页新增「行程费用」板块
- **所有参与者都可以添加行程中的各项费用**（修正：不只是发起人）
- 费用项目包括：名称、金额、备注
- 自动计算费用总和和人均分摊
- 参与者可以看到费用明细和应付款项
- 支持费用项目的添加和删除
- 使用场景：同学拼车到机场，一人先付钱后添加费用，其他人AA

### 3. 联系方式功能 ✅
- 发布帖子时新增「联系方式」可选字段
- 支持填写QQ、微信、电话
- 用户可以选择是否公开联系方式
- 帖子详情页对参与者显示联系方式
- 非参与者看不到联系方式，保护隐私

---

## 二、技术实现细节

### 图片上传功能
- 数据库新增 `image_url` 和 `image_urls` 字段
- 使用 Supabase Storage 存储图片文件
- 前端验证图片格式和大小（5MB限制）
- 图片上传后生成公开访问链接
- 编辑帖子时可以管理已有图片

### 行程费用管理
- 新增 `trip_expenses` 表存储费用项目
- 每个费用项目关联到帖子，包含名称、金额、备注
- 自动计算总费用和人均分摊金额
- **所有参与者都可以管理费用**（修正后的RLS策略）
- 参与者可以查看费用明细
- 前端界面显示清晰的费用列表和汇总信息
- 支持实时添加和删除费用项目
- 费用项目包括：交通费、餐饮费、门票费等常见类型
- 人均费用自动计算，方便参与者了解应付款项

### 联系方式功能
- `posts` 表新增 `contact_type` 和 `contact_info` 字段
- 联系方式只在帖子详情页对参与者显示
- 用户可以选择不填写联系方式
- 前端验证联系方式格式（可选）

---

## 三、代码提交

```bash
git add final-project/schema.sql final-project/dashboard.html final-project/migration_add_images.sql final-project/migration_add_expenses_contact.sql
git commit -m "feat: 添加帖子图片上传、行程费用管理、联系方式功能"
git push origin feat/image-upload
```

---

## 四、数据库更新

### 图片相关字段
```sql
ALTER TABLE posts 
ADD COLUMN image_url TEXT,
ADD COLUMN image_urls TEXT[] DEFAULT '{}';
```

### 行程费用表
```sql
CREATE TABLE trip_expenses (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 联系方式字段
```sql
ALTER TABLE posts 
ADD COLUMN contact_type VARCHAR(10),
ADD COLUMN contact_info VARCHAR(100);
```

### RLS策略更新（费用管理）
```sql
-- 修正：所有参与者都可以管理费用
CREATE POLICY "参与者可管理费用" ON trip_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM participations p
            WHERE p.post_id = trip_expenses.post_id 
            AND p.user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = trip_expenses.post_id 
            AND posts.user_id = auth.uid()
        )
    );
```

---

## 五、问题解决

1. **图片上传权限问题**
   - 问题：匿名用户无法直接创建 Storage 桶
   - 解决：在 Supabase 控制台手动创建 post-images 桶

2. **费用计算精度**
   - 问题：金额计算可能出现小数精度问题
   - 解决：使用 DECIMAL(10,2) 类型存储金额

3. **联系方式隐私**
   - 问题：如何保护用户联系方式不被滥用
   - 解决：只对帖子参与者显示联系方式

4. **费用管理权限**
   - 问题：最初设计只有发起人可以管理费用，不符合实际场景
   - 解决：修改RLS策略，让所有参与者都可以管理费用

---

## 六、使用场景示例

### 行程费用管理
1. **场景**：同学A组织从学校到机场的拼车
2. **过程**：同学B先支付了车费200元（不一定是发起人）
3. **操作**：同学B在帖子详情页添加费用项目「车费」200元
4. **效果**：系统自动计算人均费用（如4人拼车，每人50元）
5. **参与者**：所有参与者看到费用明细和应付款项
6. **结算**：参与者通过联系方式联系同学B进行AA付款

### 联系方式功能
1. **场景**：用户发布找学习搭子的帖子
2. **选择**：用户可以选择填写QQ号作为联系方式
3. **隐私**：联系方式仅对参与者可见
4. **沟通**：感兴趣的同学参与后可以看到联系方式并联系

---

## 七、备注

- 当前代码在 `feat/image-upload` 分支，已合并到 `main` 分支
- 需要在实际 Supabase 项目中测试完整功能
- 图片上传需要网络连接，大图片上传可能较慢
- 联系方式为可选字段，用户可以不填写
- 费用管理功能所有参与者都可以操作，符合实际AA场景