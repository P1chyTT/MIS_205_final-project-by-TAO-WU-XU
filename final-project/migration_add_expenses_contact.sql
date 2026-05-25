-- 添加行程费用和联系方式 - 数据库迁移脚本
-- 在 Supabase SQL Editor 中运行此脚本

-- 1. 添加联系方式字段到 posts 表
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS contact_type VARCHAR(10),
ADD COLUMN IF NOT EXISTS contact_info VARCHAR(100);

-- 2. 创建行程费用表
CREATE TABLE IF NOT EXISTS trip_expenses (
    id          SERIAL PRIMARY KEY,
    post_id     INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    name        VARCHAR(100) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    note        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_trip_expenses_post_id ON trip_expenses(post_id);

-- 4. 启用 RLS
ALTER TABLE trip_expenses ENABLE ROW LEVEL SECURITY;

-- 5. RLS 策略：所有人都可以查看费用
CREATE POLICY "任何人都可查看费用" ON trip_expenses
    FOR SELECT USING (true);

-- 6. RLS 策略：只有帖子发起人可以管理费用
CREATE POLICY "发起人可管理费用" ON trip_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = trip_expenses.post_id 
            AND posts.user_id = auth.uid()
        )
    );

-- 7. 添加注释
COMMENT ON COLUMN posts.contact_type IS '联系方式类型：qq/wechat/phone';
COMMENT ON COLUMN posts.contact_info IS '联系方式内容';
COMMENT ON COLUMN trip_expenses.name IS '费用项目名称';
COMMENT ON COLUMN trip_expenses.amount IS '费用金额';
COMMENT ON COLUMN trip_expenses.note IS '费用备注说明';

-- 8. 验证更改
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('posts', 'trip_expenses')
AND column_name IN ('contact_type', 'contact_info', 'name', 'amount', 'note')
ORDER BY table_name, ordinal_position;

-- 9. 显示示例数据（如果有）
SELECT 
    p.id,
    p.title,
    p.contact_type,
    p.contact_info,
    COUNT(te.id) as expense_count,
    COALESCE(SUM(te.amount), 0) as total_expenses
FROM posts p
LEFT JOIN trip_expenses te ON p.id = te.post_id
GROUP BY p.id, p.title, p.contact_type, p.contact_info
HAVING p.contact_type IS NOT NULL OR COUNT(te.id) > 0
LIMIT 10;