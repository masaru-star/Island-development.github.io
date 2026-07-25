-- 1. 拡張機能の有効化（UUID生成用）
create extension if not exists "uuid-ossp";

-- 2. 端末ブロックリストテーブル
create table public.banned_devices (
    device_id uuid primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. ユーザーテーブル
create table public.users (
    id uuid primary key default uuid_generate_v4(),
    name text not null unique,
    password text not null, -- SHA-256ハッシュが格納される
    device_id uuid not null,
    role text default 'User' not null,
    is_banned boolean default false not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. 投稿テーブル
create table public.posts (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.users(id) on delete cascade not null,
    device_id uuid,
    message text not null check (char_length(message) <= 150), -- 150文字制限
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. システム/管理者用初期ユーザーの追加
-- (JSコード内の registerUser で利用されている固定UUID: 07003402-51ea-4a7c-8279-0ef4258250af に対応)
insert into public.users (id, name, password, device_id, role)
values (
    '07003402-51ea-4a7c-8279-0ef4258250af',
    'システム管理者',
    'd7a8fbb307d7809469ca9abcb0082e4f8d5651e4a213b437c29bcf8a8d1a1b1a', -- ダミーハッシュ
    uuid_generate_v4(),
    'Admin'
) on conflict (id) do nothing;

-- 6. クライアント(anon)からの直接の読み書きを許可するため、RLS（行レベルセキュリティ）を無効化
alter table public.banned_devices disable row level security;
alter table public.users disable row level security;
alter table public.posts disable row level security;
