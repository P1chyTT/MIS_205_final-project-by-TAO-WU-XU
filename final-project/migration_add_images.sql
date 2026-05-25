-- 添加图片支持 - 数据库迁移脚本
-- 在 Supabase SQL Editor 中运行此脚本

-- 1. 为 posts 表添加图片字段
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- 2. 为 image_urls 字段创建索引（用于数组查询）
CREATE INDEX IF NOT EXISTS idx_posts_image_urls ON posts USING GIN (image_urls);

-- 3. 创建 post-images Storage 桶（需要在 Supabase Storage 界面手动创建）
-- 注意：以下代码在 Supabase SQL Editor 中可能无法执行，需要在 Storage 界面创建
-- 或者使用 Supabase 管理 API 创建
/*
-- 创建 Storage 桶（如果不存在）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post-images',
    'post-images',
    true,
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- 设置 Storage 策略
CREATE POLICY "任何人都可以查看图片" ON storage.objects
    FOR SELECT USING (bucket_id = 'post-images');

CREATE POLICY "登录用户可以上传图片" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'post-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "用户可以删除自己的图片" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'post-images' 
        AND auth.uid() = owner
    );
*/

-- 4. 更新现有帖子，确保 image_urls 数组不为 null
UPDATE posts SET image_urls = '{}' WHERE image_urls IS NULL;

-- 5. 添加注释说明
COMMENT ON COLUMN posts.image_url IS '帖子主图URL（第一张图片）';
COMMENT ON COLUMN posts.image_urls IS '帖子所有图片URL数组';

-- 6. 验证更改
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'posts' 
AND column_name IN ('image_url', 'image_urls')
ORDER BY ordinal_position;

-- 7. 显示示例数据
SELECT 
    id,
    title,
    type,
    image_url,
    array_length(image_urls, 1) as image_count
FROM posts 
WHERE image_urls IS NOT NULL 
AND array_length(image_urls, 1) > 0
LIMIT 5;