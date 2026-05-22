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
    status          VARCHAR(10) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. 参与记录表
CREATE TABLE IF NOT EXISTS participations (
    id          SERIAL PRIMARY KEY,
    post_id     INT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id)  -- 同一用户不能重复参与同一帖子
);

-- 3. 索引
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
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
    type        VARCHAR(20) NOT NULL CHECK (type IN ('join', 'leave', 'full', 'bill', 'system')),
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

-- 10. 存储函数：参与人数增减（增强版，满员时发送通知）
CREATE OR REPLACE FUNCTION increment_participants(post_id_param INT)
RETURNS VOID AS $$
DECLARE
    updated_post RECORD;
    post_author UUID;
    post_title VARCHAR(100);
    per_person DECIMAL(10,2);
BEGIN
    UPDATE posts
    SET current_people = current_people + 1,
        status = CASE WHEN current_people + 1 >= max_people THEN 'closed' ELSE 'open' END
    WHERE id = post_id_param
    RETURNING * INTO updated_post;

    -- 如果帖子刚满员，发送组队成功通知给作者
    IF updated_post.status = 'closed' AND updated_post.current_people >= updated_post.max_people THEN
        -- 给作者发送满员通知
        INSERT INTO notifications (user_id, type, title, content, post_id)
        VALUES (
            updated_post.user_id,
            'full',
            '组队成功！你的帖子已满员',
            '你的帖子「' || updated_post.title || '」已达到人数上限（' || updated_post.max_people || '人），可以开始活动了！',
            post_id_param
        );

        -- 如果是拼单类型，给所有参与者发送账单通知
        IF updated_post.type = 'groupbuy' AND updated_post.total_amount IS NOT NULL THEN
            per_person := ROUND(updated_post.total_amount / updated_post.max_people, 2);

            -- 给所有参与者（包括作者）发送账单通知
            INSERT INTO notifications (user_id, type, title, content, post_id)
            SELECT
                p.user_id,
                'bill',
                '拼单账单：请付款 ¥' || per_person,
                '你参与的拼单「' || updated_post.title || '」总金额为 ¥' || updated_post.total_amount || '，人均 ¥' || per_person || '，请及时付款给发起人 ' || updated_post.author_name || '。',
                post_id_param
            FROM participations p
            WHERE p.post_id = post_id_param;

            -- 如果作者没有参与记录（可能不在 participations 表中），也给他发通知
            IF NOT EXISTS (SELECT 1 FROM participations WHERE post_id = post_id_param AND user_id = updated_post.user_id) THEN
                INSERT INTO notifications (user_id, type, title, content, post_id)
                VALUES (
                    updated_post.user_id,
                    'bill',
                    '拼单账单：请收款 ¥' || per_person,
                    '你发起的拼单「' || updated_post.title || '」总金额为 ¥' || updated_post.total_amount || '，人均 ¥' || per_person || '，请向参与者收款。',
                    post_id_param
                );
            END IF;
        END IF;
    END IF;
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
