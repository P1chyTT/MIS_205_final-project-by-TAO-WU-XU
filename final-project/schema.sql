-- 校园搭子拼单系统 — 数据库建表脚本
-- 在 Supabase SQL Editor 中运行此脚本

-- 0. 用户公开信息表（解决 anon key 无法直接查 auth.users 的问题）
CREATE TABLE IF NOT EXISTS profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username    VARCHAR(50) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 新用户注册时自动创建 profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 1. 帖子表
CREATE TABLE IF NOT EXISTS posts (
    id              SERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    author_name     VARCHAR(50) NOT NULL,
    type            VARCHAR(10) NOT NULL CHECK (type IN ('buddy', 'groupbuy')),
    title           VARCHAR(100) NOT NULL,
    description     TEXT,
    -- 找搭子专用字段
    location        VARCHAR(100),
    meet_time       TIMESTAMPTZ,
    -- 拼单专用字段
    total_amount    DECIMAL(10, 2),
    -- 通用字段
    max_people      INT NOT NULL DEFAULT 2,
    current_people  INT NOT NULL DEFAULT 1,
    deadline        TIMESTAMPTZ,                          -- 截止时间（超过后自动取消）
    status          VARCHAR(10) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'completed', 'finished', 'cancelled')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 图片支持
    image_url       TEXT,                           -- 帖子主图URL
    image_urls      TEXT[] DEFAULT '{}'            -- 多图URL数组
);

-- 2. 参与记录表
CREATE TABLE IF NOT EXISTS participations (
    id              SERIAL PRIMARY KEY,
    post_id         INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_confirmed    BOOLEAN NOT NULL DEFAULT false,  -- 参与者是否确认完成
    UNIQUE(post_id, user_id)  -- 同一用户不能重复参与同一帖子
);

-- 3. 索引
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_deadline ON posts(deadline);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_participations_post_id ON participations(post_id);
CREATE INDEX IF NOT EXISTS idx_participations_user_id ON participations(user_id);

-- 4. 启用 RLS (Row Level Security)
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE participations ENABLE ROW LEVEL SECURITY;

-- 5. RLS 策略 — profiles 表
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "任何人都可查看用户信息" ON profiles
    FOR SELECT USING (true);

-- profiles 由 trigger 自动创建，不需要 INSERT 策略（使用 SECURITY DEFINER 函数）

-- 用户可更新自己的 profile
CREATE POLICY "用户可更新自己的资料" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- 6. RLS 策略 — posts 表
-- 任何人都可以查看帖子
CREATE POLICY "任何人都可查看帖子" ON posts
    FOR SELECT USING (true);

-- 只有登录用户可以创建帖子
CREATE POLICY "登录用户可创建帖子" ON posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 帖子发布者可更新自己的帖子
CREATE POLICY "发布者可更新帖子" ON posts
    FOR UPDATE USING (auth.uid() = user_id);

-- 帖子发布者可删除自己的帖子
CREATE POLICY "发布者可删除帖子" ON posts
    FOR DELETE USING (auth.uid() = user_id);

-- 7. RLS 策略 — participations 表
-- 任何人都可以查看参与记录
CREATE POLICY "任何人都可查看参与记录" ON participations
    FOR SELECT USING (true);

-- 登录用户可以创建参与记录（代表自己）
CREATE POLICY "登录用户可参与帖子" ON participations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 参与者可以删除自己的参与记录（退出）
CREATE POLICY "参与者可退出" ON participations
    FOR DELETE USING (auth.uid() = user_id);

-- 8. 收藏表
CREATE TABLE IF NOT EXISTS favorites (
    id          SERIAL PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id     INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_post_id ON favorites(post_id);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "任何人都可查看收藏" ON favorites
    FOR SELECT USING (true);

CREATE POLICY "登录用户可添加收藏" ON favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户可删除自己的收藏" ON favorites
    FOR DELETE USING (auth.uid() = user_id);

-- 9. 消息通知表
CREATE TABLE IF NOT EXISTS notifications (
    id          SERIAL PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type        VARCHAR(20) NOT NULL CHECK (type IN ('join', 'leave', 'full', 'bill', 'confirm', 'system', 'expired')),
    title       VARCHAR(100) NOT NULL,
    content     TEXT,
    post_id     INT REFERENCES posts(id) ON DELETE CASCADE,
    is_read     BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户可查看自己的消息" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "系统可创建消息" ON notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "用户可更新自己的消息" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- 10. 存储函数：参与人数增减
CREATE OR REPLACE FUNCTION increment_participants(post_id_param INT)
RETURNS VOID AS $$
BEGIN
    UPDATE posts
    SET current_people = current_people + 1,
        status = CASE WHEN current_people + 1 >= max_people THEN 'closed' ELSE 'open' END
    WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_participants(post_id_param INT)
RETURNS VOID AS $$
BEGIN
    UPDATE posts
    SET current_people = GREATEST(current_people - 1, 1),
        status = 'open'
    WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. 触发器函数：创建通知（有人参与帖子时通知帖子作者）
CREATE OR REPLACE FUNCTION notify_on_join()
RETURNS TRIGGER AS $$
DECLARE
    post_author UUID;
    post_title VARCHAR(100);
    joiner_name VARCHAR(50);
BEGIN
    -- 获取帖子作者和标题
    SELECT user_id, title INTO post_author, post_title
    FROM posts WHERE id = NEW.post_id;

    -- 获取参与者用户名
    SELECT username INTO joiner_name
    FROM profiles WHERE id = NEW.user_id;

    -- 给帖子作者发送通知（排除自己参与自己的帖子）
    IF post_author IS NOT NULL AND post_author != NEW.user_id THEN
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            post_author,
            'join',
            '有人参与了你的帖子',
            COALESCE(joiner_name, '有用户') || ' 参与了你的帖子「' || post_title || '」',
            NEW.post_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_participation_insert ON participations;
CREATE TRIGGER on_participation_insert
    AFTER INSERT ON participations
    FOR EACH ROW EXECUTE FUNCTION notify_on_join();

-- 12. 触发器函数：创建通知（有人退出帖子时通知帖子作者）
CREATE OR REPLACE FUNCTION notify_on_leave()
RETURNS TRIGGER AS $$
DECLARE
    post_author UUID;
    post_title VARCHAR(100);
    leaver_name VARCHAR(50);
BEGIN
    SELECT user_id, title INTO post_author, post_title
    FROM posts WHERE id = OLD.post_id;

    SELECT username INTO leaver_name
    FROM profiles WHERE id = OLD.user_id;

    IF post_author IS NOT NULL AND post_author != OLD.user_id THEN
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            post_author,
            'leave',
            '有人退出了你的帖子',
            COALESCE(leaver_name, '有用户') || ' 退出了你的帖子「' || post_title || '」',
            OLD.post_id
        );
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_participation_delete ON participations;
CREATE TRIGGER on_participation_delete
    AFTER DELETE ON participations
    FOR EACH ROW EXECUTE FUNCTION notify_on_leave();

-- 13. 存储函数：发起人完成订单，发送账单
CREATE OR REPLACE FUNCTION complete_order(post_id_param INT)
RETURNS VOID AS $$
DECLARE
    post_record RECORD;
    per_person DECIMAL(10,2);
BEGIN
    SELECT * INTO post_record
    FROM posts WHERE id = post_id_param;

    IF post_record IS NULL OR post_record.status != 'closed' THEN
        RETURN;
    END IF;

    -- 更新帖子状态为 completed
    UPDATE posts SET status = 'completed' WHERE id = post_id_param;

    -- 如果是拼单类型，发送账单
    IF post_record.type = 'groupbuy' AND post_record.total_amount IS NOT NULL THEN
        per_person := ROUND(post_record.total_amount / post_record.max_people, 2);

        -- 给所有参与者发送账单通知
        INSERT INTO notifications (user_id, type, title, content, post_id)
        SELECT
            p.user_id,
            'bill',
            '拼单账单：请付款 ¥' || per_person,
            '你参与的拼单「' || post_record.title || '」总金额为 ¥' || post_record.total_amount || '，人均 ¥' || per_person || '，请及时付款给发起人 ' || post_record.author_name || '。付款后请点击「确认完成」。',
            post_id_param
        FROM participations p
        WHERE p.post_id = post_id_param;

        -- 给发起人发送收款通知
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            post_record.user_id,
            'bill',
            '拼单账单：请收款 ¥' || per_person,
            '你发起的拼单「' || post_record.title || '」总金额为 ¥' || post_record.total_amount || '，人均 ¥' || per_person || '，请向参与者收款。',
            post_id_param
        );
    ELSE
        -- 非拼单类型，只发送完成通知
        INSERT INTO notifications (user_id, type, title, content, post_id)
        SELECT
            p.user_id,
            'full',
            '活动即将开始',
            '你参与的「' || post_record.title || '」已被发起人确认，请准时参加。',
            post_id_param
        FROM participations p
        WHERE p.post_id = post_id_param;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. 存储函数：检查并处理过期帖子（超过 deadline 且未完成的帖子自动取消）
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

-- 15. 存储函数：参与者确认完成
CREATE OR REPLACE FUNCTION confirm_participation(post_id_param INT, user_id_param UUID)
RETURNS VOID AS $$
DECLARE
    post_record RECORD;
    all_confirmed BOOLEAN;
    confirmer_name VARCHAR(50);
BEGIN
    -- 更新参与记录为已确认
    UPDATE participations
    SET is_confirmed = true
    WHERE post_id = post_id_param AND user_id = user_id_param;

    SELECT * INTO post_record
    FROM posts WHERE id = post_id_param;

    SELECT username INTO confirmer_name
    FROM profiles WHERE id = user_id_param;

    -- 给发起人发送确认通知
    INSERT INTO notifications (user_id, type, title, content, post_id)
    VALUES (
        post_record.user_id,
        'confirm',
        '有人确认了订单',
        COALESCE(confirmer_name, '有用户') || ' 已确认完成拼单「' || post_record.title || '」。',
        post_id_param
    );

    -- 检查是否所有人都已确认
    SELECT NOT EXISTS (
        SELECT 1 FROM participations
        WHERE post_id = post_id_param AND is_confirmed = false
    ) INTO all_confirmed;

    -- 如果所有人都确认了，更新帖子状态为 finished
    IF all_confirmed THEN
        UPDATE posts SET status = 'finished' WHERE id = post_id_param;

        -- 给所有人发送订单完成通知
        INSERT INTO notifications (user_id, type, title, content, post_id)
        SELECT
            p.user_id,
            'system',
            '订单已全部完成',
            '拼单「' || post_record.title || '」所有参与者已确认完成，订单正式结束。',
            post_id_param
        FROM participations p
        WHERE p.post_id = post_id_param;

        -- 也给发起人发送
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            post_record.user_id,
            'system',
            '订单已全部完成',
            '你发起的拼单「' || post_record.title || '」所有参与者已确认完成，订单正式结束。',
            post_id_param
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. 行程费用表
CREATE TABLE IF NOT EXISTS trip_expenses (
    id          SERIAL PRIMARY KEY,
    post_id     INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    name        VARCHAR(100) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    note        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trip_expenses_post_id ON trip_expenses(post_id);

ALTER TABLE trip_expenses ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人都可以查看费用
CREATE POLICY "任何人都可查看费用" ON trip_expenses
    FOR SELECT USING (true);

-- RLS 策略：只有帖子发起人可以管理费用
CREATE POLICY "发起人可管理费用" ON trip_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = trip_expenses.post_id 
            AND posts.user_id = auth.uid()
        )
    );

-- 17. 联系方式字段
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS contact_type VARCHAR(10),
ADD COLUMN IF NOT EXISTS contact_info VARCHAR(100);

-- 添加注释
COMMENT ON COLUMN posts.contact_type IS '联系方式类型：qq/wechat/phone';
COMMENT ON COLUMN posts.contact_info IS '联系方式内容';
COMMENT ON COLUMN trip_expenses.name IS '费用项目名称';
COMMENT ON COLUMN trip_expenses.amount IS '费用金额';
COMMENT ON COLUMN trip_expenses.note IS '费用备注说明';
