-- ============================================
-- 增量迁移脚本：添加 deadline 字段 + 自动取消功能
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 给 posts 表添加 deadline 字段
ALTER TABLE posts ADD COLUMN IF NOT EXISTS deadline TIMESTAMPTZ;

-- 2. 扩展 posts.status 约束（添加 cancelled）
-- 先删除旧约束，再添加新约束
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_status_check;
ALTER TABLE posts ADD CONSTRAINT posts_status_check
    CHECK (status IN ('open', 'closed', 'completed', 'finished', 'cancelled'));

-- 3. 扩展 notifications.type 约束（添加 expired）
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
    CHECK (type IN ('join', 'leave', 'full', 'bill', 'confirm', 'system', 'expired'));

-- 4. 添加 deadline 索引
CREATE INDEX IF NOT EXISTS idx_posts_deadline ON posts(deadline);

-- 5. 创建/更新存储函数：检查并处理过期帖子
CREATE OR REPLACE FUNCTION check_expired_posts()
RETURNS VOID AS $$
DECLARE
    expired_post RECORD;
    author_name_val VARCHAR(50);
BEGIN
    FOR expired_post IN
        SELECT p.id, p.user_id, p.title, p.type, p.deadline
        FROM posts p
        WHERE p.deadline IS NOT NULL
          AND p.deadline <= NOW()
          AND p.status IN ('open', 'closed')
    LOOP
        -- 获取作者名
        SELECT username INTO author_name_val
        FROM profiles WHERE id = expired_post.user_id;

        -- 更新帖子状态为已取消
        UPDATE posts SET status = 'cancelled' WHERE id = expired_post.id;

        -- 通知帖子作者
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            expired_post.user_id,
            'expired',
            '帖子已过期取消',
            '你的「' || expired_post.title || '」因超过截止时间（' ||
            TO_CHAR(expired_post.deadline, 'YYYY-MM-DD HH24:MI') ||
            '）且人数未满，已自动取消。',
            expired_post.id
        );

        -- 通知所有参与者
        INSERT INTO notifications (user_id, type, title, content, post_id)
        SELECT
            pt.user_id,
            'expired',
            '参与的帖子已过期取消',
            '你参与的「' || expired_post.title || '」因超过截止时间且人数未满，已自动取消。',
            expired_post.id
        FROM participations pt
        WHERE pt.post_id = expired_post.id
          AND pt.user_id != expired_post.user_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 更新 increment_participants 函数（确保满员时状态变为 closed 而不是 cancelled）
CREATE OR REPLACE FUNCTION increment_participants(post_id_param INT)
RETURNS VOID AS $$
BEGIN
    UPDATE posts
    SET current_people = current_people + 1,
        status = CASE WHEN current_people + 1 >= max_people THEN 'closed' ELSE 'open' END
    WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
