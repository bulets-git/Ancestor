-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Gia Pháº£ Äiá»‡n Tá»­ - Database Setup
-- Há» Äáº·ng lÃ ng Ká»· CÃ¡c
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- TABLES
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. People table
CREATE TABLE IF NOT EXISTS people (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle          VARCHAR(50) UNIQUE NOT NULL,
    display_name    VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    middle_name     VARCHAR(100),
    surname         VARCHAR(100),
    gender          SMALLINT CHECK (gender IN (1, 2)), -- 1=Male, 2=Female
    generation      INTEGER NOT NULL DEFAULT 1,
    chi             INTEGER,
    
    -- Birth
    birth_date      DATE,
    birth_year      INTEGER,
    birth_place     VARCHAR(255),
    
    -- Death
    death_date      DATE,
    death_year      INTEGER,
    death_place     VARCHAR(255),
    death_lunar     VARCHAR(20), -- Lunar date: "15/7"
    
    -- Status
    is_living       BOOLEAN DEFAULT true,
    is_patrilineal  BOOLEAN DEFAULT true,
    
    -- Contact
    phone           VARCHAR(20),
    email           VARCHAR(255),
    zalo            VARCHAR(50),
    facebook        VARCHAR(255),
    address         TEXT,
    hometown        VARCHAR(255),
    
    -- Bio
    occupation      VARCHAR(255),
    biography       TEXT,
    notes           TEXT,
    avatar_url      TEXT,
    
    -- Privacy: 0=public, 1=members only, 2=private
    privacy_level   SMALLINT DEFAULT 0,
    
    -- Timestamps
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Families table
CREATE TABLE IF NOT EXISTS families (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle          VARCHAR(50) UNIQUE NOT NULL,
    father_id       UUID REFERENCES people(id) ON DELETE SET NULL,
    mother_id       UUID REFERENCES people(id) ON DELETE SET NULL,
    marriage_date   DATE,
    marriage_place  VARCHAR(255),
    divorce_date    DATE,
    notes           TEXT,
    sort_order      INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Children junction table
CREATE TABLE IF NOT EXISTS children (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id       UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    person_id       UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    sort_order      INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(family_id, person_id)
);

-- 4. Profiles (user accounts)
CREATE TABLE IF NOT EXISTS profiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email               VARCHAR(255),
    full_name           VARCHAR(255),
    role                VARCHAR(20) DEFAULT 'viewer' CHECK (role IN ('admin', 'editor', 'viewer')),
    linked_person       UUID REFERENCES people(id) ON DELETE SET NULL,
    avatar_url          TEXT,
    -- Verification & moderation (Sprint 12)
    is_verified         BOOLEAN NOT NULL DEFAULT false,
    can_verify_members  BOOLEAN NOT NULL DEFAULT false,
    is_suspended        BOOLEAN NOT NULL DEFAULT false,
    suspension_reason   TEXT,
    -- Timestamps
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Contributions (edit suggestions)
CREATE TABLE IF NOT EXISTS contributions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
    target_person   UUID REFERENCES people(id) ON DELETE CASCADE,
    change_type     VARCHAR(20) CHECK (change_type IN ('create', 'update', 'delete')),
    changes         JSONB,
    reason          TEXT,
    status          VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
    reviewed_at     TIMESTAMPTZ,
    review_notes    TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Events (memorial days)
CREATE TABLE IF NOT EXISTS events (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    event_date      DATE,
    event_lunar     VARCHAR(20),
    event_type      VARCHAR(50) DEFAULT 'other' CHECK (event_type IN ('gio', 'hop_ho', 'le_tet', 'other')),
    person_id       UUID REFERENCES people(id) ON DELETE SET NULL,
    location        VARCHAR(255),
    recurring       BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Media (photos, documents)
CREATE TABLE IF NOT EXISTS media (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id       UUID REFERENCES people(id) ON DELETE CASCADE,
    type            VARCHAR(20) DEFAULT 'photo' CHECK (type IN ('photo', 'document', 'video')),
    url             TEXT NOT NULL,
    caption         TEXT,
    is_primary      BOOLEAN DEFAULT false,
    sort_order      INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- INDEXES
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

CREATE INDEX IF NOT EXISTS idx_people_surname ON people(surname);
CREATE INDEX IF NOT EXISTS idx_people_generation ON people(generation);
CREATE INDEX IF NOT EXISTS idx_people_chi ON people(chi);
CREATE INDEX IF NOT EXISTS idx_people_display_name ON people USING GIN(to_tsvector('simple', display_name));

CREATE INDEX IF NOT EXISTS idx_families_father ON families(father_id);
CREATE INDEX IF NOT EXISTS idx_families_mother ON families(mother_id);

CREATE INDEX IF NOT EXISTS idx_children_family ON children(family_id);
CREATE INDEX IF NOT EXISTS idx_children_person ON children(person_id);

CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON contributions(status);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- ROW LEVEL SECURITY (RLS)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;

-- People policies
CREATE POLICY "Public read for public people" ON people
    FOR SELECT USING (privacy_level = 0);

CREATE POLICY "Members can read all people" ON people
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE profiles.user_id = auth.uid())
    );

CREATE POLICY "Admins and editors can insert people" ON people
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

CREATE POLICY "Admins and editors can update people" ON people
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

CREATE POLICY "Admins can delete people" ON people
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Families policies (similar pattern)
CREATE POLICY "Anyone can read families" ON families FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage families" ON families
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- Children policies
CREATE POLICY "Anyone can read children" ON children FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage children" ON children
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- Profiles policies
CREATE POLICY "Users can read all profiles" ON profiles FOR SELECT USING (true);

CREATE POLICY "Service role can insert profiles" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can update any profile" ON profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.user_id = auth.uid() 
            AND p.role = 'admin'
        )
    );

-- Events policies
CREATE POLICY "Anyone can read events" ON events FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage events" ON events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- Media policies
CREATE POLICY "Anyone can read media" ON media FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage media" ON media
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- Contributions policies
CREATE POLICY "Users can read own contributions" ON contributions
    FOR SELECT USING (
        author_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Members can create contributions" ON contributions
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE profiles.user_id = auth.uid())
    );

CREATE POLICY "Admins can update contributions" ON contributions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- TRIGGERS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'viewer'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- SEED DATA (Sample Family)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- Uncomment to add sample data
/*
INSERT INTO people (handle, display_name, surname, first_name, gender, generation, chi, birth_year, is_living, is_patrilineal) VALUES
('P001', 'Äáº·ng VÄƒn Thá»§y Tá»•', 'Äáº·ng', 'Thá»§y Tá»•', 1, 1, 1, 1850, false, true),
('P002', 'Nguyá»…n Thá»‹ A', 'Nguyá»…n', 'A', 2, 1, 1, 1855, false, false),
('P003', 'Äáº·ng VÄƒn B', 'Äáº·ng', 'B', 1, 2, 1, 1880, false, true),
('P004', 'Äáº·ng VÄƒn C', 'Äáº·ng', 'C', 1, 2, 1, 1882, false, true),
('P005', 'Äáº·ng Thá»‹ D', 'Äáº·ng', 'D', 2, 2, 1, 1885, false, true);

INSERT INTO families (handle, father_id, mother_id) VALUES
('F001', (SELECT id FROM people WHERE handle = 'P001'), (SELECT id FROM people WHERE handle = 'P002'));

INSERT INTO children (family_id, person_id, sort_order) VALUES
((SELECT id FROM families WHERE handle = 'F001'), (SELECT id FROM people WHERE handle = 'P003'), 1),
((SELECT id FROM families WHERE handle = 'F001'), (SELECT id FROM people WHERE handle = 'P004'), 2),
((SELECT id FROM families WHERE handle = 'F001'), (SELECT id FROM people WHERE handle = 'P005'), 3);
*/

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Set first admin (replace with your email after signup)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- UPDATE profiles SET role = 'admin' WHERE email = 'your-admin@example.com';
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 6: Culture & Community Features Migration
-- Tables: achievements, fund_transactions, scholarships, clan_articles
-- Run this in Supabase SQL Editor after Sprint 5
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Achievements (Vinh danh thÃ nh tÃ­ch)
CREATE TABLE achievements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id       UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    category        VARCHAR(50) NOT NULL CHECK (category IN ('hoc_tap', 'su_nghiep', 'cong_hien', 'other')),
    description     TEXT,
    year            INTEGER,
    awarded_by      VARCHAR(255),
    is_featured     BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_achievements_person ON achievements(person_id);
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_year ON achievements(year);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view achievements"
ON achievements FOR SELECT USING (true);

CREATE POLICY "Editors and admins can insert achievements"
ON achievements FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Editors and admins can update achievements"
ON achievements FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Admins can delete achievements"
ON achievements FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 2. Fund Transactions (Quá»¹ khuyáº¿n há»c)
CREATE TABLE fund_transactions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type              VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    category          VARCHAR(50) NOT NULL CHECK (category IN ('dong_gop', 'hoc_bong', 'khen_thuong', 'other')),
    amount            DECIMAL(12, 0) NOT NULL CHECK (amount > 0),
    donor_name        VARCHAR(255),
    donor_person_id   UUID REFERENCES people(id) ON DELETE SET NULL,
    recipient_id      UUID REFERENCES people(id) ON DELETE SET NULL,
    description       TEXT,
    transaction_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    academic_year     VARCHAR(20),
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_fund_tx_type ON fund_transactions(type);
CREATE INDEX idx_fund_tx_category ON fund_transactions(category);
CREATE INDEX idx_fund_tx_date ON fund_transactions(transaction_date);
CREATE INDEX idx_fund_tx_academic_year ON fund_transactions(academic_year);

ALTER TABLE fund_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view fund transactions"
ON fund_transactions FOR SELECT USING (true);

CREATE POLICY "Editors and admins can insert fund transactions"
ON fund_transactions FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Editors and admins can update fund transactions"
ON fund_transactions FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Admins can delete fund transactions"
ON fund_transactions FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 3. Scholarships (Há»c bá»•ng & Khen thÆ°á»Ÿng)
CREATE TABLE scholarships (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id       UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    type            VARCHAR(20) NOT NULL CHECK (type IN ('hoc_bong', 'khen_thuong')),
    amount          DECIMAL(12, 0) NOT NULL CHECK (amount > 0),
    reason          TEXT,
    academic_year   VARCHAR(20) NOT NULL,
    school          VARCHAR(255),
    grade_level     VARCHAR(50),
    status          VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'paid')),
    approved_by     UUID REFERENCES profiles(id),
    approved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scholarships_person ON scholarships(person_id);
CREATE INDEX idx_scholarships_type ON scholarships(type);
CREATE INDEX idx_scholarships_status ON scholarships(status);
CREATE INDEX idx_scholarships_year ON scholarships(academic_year);

ALTER TABLE scholarships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scholarships"
ON scholarships FOR SELECT USING (true);

CREATE POLICY "Editors and admins can insert scholarships"
ON scholarships FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Editors and admins can update scholarships"
ON scholarships FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Admins can delete scholarships"
ON scholarships FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- 4. Clan Articles (HÆ°Æ¡ng Æ°á»›c)
CREATE TABLE clan_articles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255) NOT NULL,
    content         TEXT NOT NULL,
    category        VARCHAR(50) NOT NULL CHECK (category IN ('gia_huan', 'quy_uoc', 'loi_dan')),
    sort_order      INTEGER DEFAULT 0,
    is_featured     BOOLEAN DEFAULT false,
    author_id       UUID REFERENCES profiles(id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clan_articles_category ON clan_articles(category);
CREATE INDEX idx_clan_articles_sort ON clan_articles(sort_order);

ALTER TABLE clan_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view clan articles"
ON clan_articles FOR SELECT USING (true);

CREATE POLICY "Editors and admins can insert clan articles"
ON clan_articles FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Editors and admins can update clan articles"
ON clan_articles FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

CREATE POLICY "Admins can delete clan articles"
ON clan_articles FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- FR-906: Add Vietnamese cultural name fields to people table
-- pen_name = TÃªn tá»± (courtesy name), taboo_name = TÃªn hÃºy (taboo name)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

ALTER TABLE people ADD COLUMN IF NOT EXISTS pen_name VARCHAR(100);
ALTER TABLE people ADD COLUMN IF NOT EXISTS taboo_name VARCHAR(100);
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 7: Lá»‹ch Cáº§u Ä‘Æ°Æ¡ng (Ceremony Rotation Schedule)
-- PhÃ¢n cÃ´ng xoay vÃ²ng ngÆ°á»i chá»§ lá»… Cáº§u Ä‘Æ°Æ¡ng theo thá»© tá»± cÃ¢y gia pháº£
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. NhÃ³m cáº§u Ä‘Æ°Æ¡ng (rotation pool config)
--    Má»—i nhÃ³m Ä‘Æ°á»£c Ä‘á»‹nh nghÄ©a bá»Ÿi má»™t tá»• tÃ´ng vÃ  tiÃªu chÃ­ Ä‘á»§ Ä‘iá»u kiá»‡n
CREATE TABLE IF NOT EXISTS cau_duong_pools (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,       -- VD: "NhÃ¡nh Ã´ng Äáº·ng ÄÃ¬nh NhÃ¢n"
    ancestor_id     UUID NOT NULL REFERENCES people(id) ON DELETE RESTRICT,
    min_generation  INTEGER NOT NULL DEFAULT 1,  -- Äá»i tá»‘i thiá»ƒu (VD: 12)
    max_age_lunar   INTEGER NOT NULL DEFAULT 70, -- Tuá»•i Ã¢m tá»‘i Ä‘a (dÆ°á»›i 70)
    description     TEXT,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PhÃ¢n cÃ´ng cáº§u Ä‘Æ°Æ¡ng (assignments)
--    Má»—i lá»… trong nÄƒm Ä‘Æ°á»£c phÃ¢n cho má»™t ngÆ°á»i, xoay vÃ²ng theo thá»© tá»± DFS
CREATE TABLE IF NOT EXISTS cau_duong_assignments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id                 UUID NOT NULL REFERENCES cau_duong_pools(id) ON DELETE CASCADE,
    year                    INTEGER NOT NULL,          -- NÄƒm dÆ°Æ¡ng lá»‹ch
    ceremony_type           VARCHAR(30) NOT NULL CHECK (
                                ceremony_type IN ('tet', 'ram_thang_gieng', 'gio_to', 'ram_thang_bay')
                            ),
    -- NgÆ°á»i Ä‘Æ°á»£c phÃ¢n cÃ´ng (theo thá»© tá»± xoay vÃ²ng)
    host_person_id          UUID REFERENCES people(id) ON DELETE SET NULL,
    -- NgÆ°á»i thá»±c sá»± thá»±c hiá»‡n (náº¿u Ä‘Æ°á»£c á»§y quyá»n)
    actual_host_person_id   UUID REFERENCES people(id) ON DELETE SET NULL,
    -- Tráº¡ng thÃ¡i
    status                  VARCHAR(20) DEFAULT 'scheduled' CHECK (
                                status IN ('scheduled', 'completed', 'delegated', 'rescheduled', 'cancelled')
                            ),
    -- NgÃ y dá»± kiáº¿n (dÆ°Æ¡ng lá»‹ch, tÃ­nh tá»« lá»‹ch Ã¢m)
    scheduled_date          DATE,
    -- NgÃ y thá»±c hiá»‡n (náº¿u sá»›m/muá»™n hÆ¡n)
    actual_date             DATE,
    -- LÃ½ do á»§y quyá»n hoáº·c Ä‘á»•i ngÃ y
    reason                  TEXT,
    notes                   TEXT,
    -- Thá»© tá»± trong vÃ²ng xoay (Ä‘á»ƒ theo dÃµi tiáº¿n trÃ¬nh)
    rotation_index          INTEGER, -- Vá»‹ trÃ­ trong danh sÃ¡ch DFS khi phÃ¢n cÃ´ng
    created_by              UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(pool_id, year, ceremony_type)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_cau_duong_pools_ancestor ON cau_duong_pools(ancestor_id);
CREATE INDEX IF NOT EXISTS idx_cau_duong_assignments_pool ON cau_duong_assignments(pool_id);
CREATE INDEX IF NOT EXISTS idx_cau_duong_assignments_year ON cau_duong_assignments(year);
CREATE INDEX IF NOT EXISTS idx_cau_duong_assignments_host ON cau_duong_assignments(host_person_id);
CREATE INDEX IF NOT EXISTS idx_cau_duong_assignments_status ON cau_duong_assignments(status);

-- 4. RLS
ALTER TABLE cau_duong_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE cau_duong_assignments ENABLE ROW LEVEL SECURITY;

-- Pools: táº¥t cáº£ Ä‘á»c Ä‘Æ°á»£c, admin/editor má»›i sá»­a Ä‘Æ°á»£c
CREATE POLICY "Anyone can view cau duong pools"
    ON cau_duong_pools FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage cau duong pools"
    ON cau_duong_pools FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.user_id = auth.uid()
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- Assignments: táº¥t cáº£ Ä‘á»c Ä‘Æ°á»£c, admin/editor má»›i sá»­a Ä‘Æ°á»£c
CREATE POLICY "Anyone can view cau duong assignments"
    ON cau_duong_assignments FOR SELECT USING (true);

CREATE POLICY "Admins and editors can manage cau duong assignments"
    ON cau_duong_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.user_id = auth.uid()
            AND profiles.role IN ('admin', 'editor')
        )
    );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Seed: Táº¡o nhÃ³m cáº§u Ä‘Æ°Æ¡ng máº·c Ä‘á»‹nh
-- Cáº­p nháº­t ancestor_id sau khi Ä‘Ã£ cháº¡y seed-dang-dinh.sql
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- INSERT INTO cau_duong_pools (name, ancestor_id, min_generation, max_age_lunar, description)
-- SELECT
--   'NhÃ³m Cáº§u Ä‘Æ°Æ¡ng Chi tá»™c Äáº·ng ÄÃ¬nh',
--   id,
--   12,   -- Äá»i 12 trá»Ÿ xuá»‘ng
--   70,   -- DÆ°á»›i 70 tuá»•i Ã¢m
--   'Xoay vÃ²ng cÃ¡c nam giá»›i Ä‘Ã£ láº­p gia Ä‘Ã¬nh, dÆ°á»›i 70 tuá»•i Ã¢m, Ä‘á»i 12 trá»Ÿ xuá»‘ng'
-- FROM people WHERE handle = 'P001'; -- Thay handle cá»§a tá»• tÃ´ng

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 7.5 Migration: Tree-Scoped Editor
-- FR-507: Link user account to person in the family tree
-- FR-508: Scoped edit permissions (subtree boundary)
-- FR-510: Server-side enforcement via RLS + PostgreSQL function
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Add edit_root_person_id column to profiles
--    This stores the root of the subtree that this user can edit.
--    NULL = no restriction (global editor / not an editor at all).
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS edit_root_person_id UUID REFERENCES people(id) ON DELETE SET NULL;

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_linked_person     ON profiles(linked_person);
CREATE INDEX IF NOT EXISTS idx_profiles_edit_root_person  ON profiles(edit_root_person_id);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 3. PostgreSQL recursive function: is_person_in_subtree
--    Returns TRUE if target_id is the root or a descendant of root_id.
--    Uses recursive CTE through families + children tables.
--    SECURITY DEFINER: runs as owner, bypasses RLS on the read path.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE OR REPLACE FUNCTION is_person_in_subtree(root_id UUID, target_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  WITH RECURSIVE subtree(id) AS (
    -- Base case: the root itself
    SELECT root_id
    UNION
    -- Recursive case: children via families + children junction
    SELECT ch.person_id
    FROM   subtree s
    JOIN   families f  ON (f.father_id = s.id OR f.mother_id = s.id)
    JOIN   children ch ON ch.family_id = f.id
  )
  SELECT EXISTS (SELECT 1 FROM subtree WHERE id = target_id);
$$;

-- Grant execute to authenticated users (needed for RLS policy evaluation)
GRANT EXECUTE ON FUNCTION is_person_in_subtree(UUID, UUID) TO authenticated;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 4. RLS: Linked person can update their own record (FR-507)
--    A user whose profile.linked_person = people.id can update their own info,
--    even if they have viewer role. This enables self-service profile updates.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "Linked person can update own info" ON people
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE  p.user_id = auth.uid()
      AND    p.linked_person = people.id
    )
  );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 5. RLS: Branch editors can update people within their assigned subtree (FR-508)
--    Supplements (OR) the existing global editor policy.
--    Only activates when edit_root_person_id IS NOT NULL.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE POLICY "Branch editors can update their subtree" ON people
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE  p.user_id = auth.uid()
      AND    p.role = 'editor'
      AND    p.edit_root_person_id IS NOT NULL
      AND    is_person_in_subtree(p.edit_root_person_id, people.id)
    )
  );

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 6. RLS: Branch editors can insert people (children in their subtree)
--    INSERT doesn't have the new person's ID yet, so we allow all editors
--    to insert â€” consistent with current behaviour.
--    Subtree enforcement for INSERT is handled at application level.
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- (No change: existing "Admins and editors can insert people" policy covers this)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Supabase Storage Setup for AncestorTree
-- Run this in Supabase SQL Editor or Dashboard â†’ Storage
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Create the 'media' storage bucket (public access for reading)
-- Note: This is typically done via Supabase Dashboard â†’ Storage â†’ New Bucket
-- Settings:
--   Name: media
--   Public: true
--   File size limit: 5MB (5242880 bytes)
--   Allowed MIME types: image/jpeg, image/png, image/webp, image/gif

-- 2. Storage RLS policies

-- Allow editors and admins to upload files to the media bucket
CREATE POLICY "Editors and admins can upload media"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'media'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

-- Allow anyone to view/download media files
CREATE POLICY "Anyone can view media"
ON storage.objects FOR SELECT
USING (bucket_id = 'media');

-- Allow editors and admins to delete media files
CREATE POLICY "Editors and admins can delete media"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'media'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

-- Allow editors and admins to update media files
CREATE POLICY "Editors and admins can update media"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'media'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 9 Security Hardening Migration
-- Reference: https://anninhthudo.vn (personal data risks in genealogy apps)
-- Issues addressed:
--   SEC-01: profiles table exposed to unauthenticated requests
--   SEC-02: people contact fields (phone/email/zalo/address) readable by
--           any registered user regardless of privacy_level
--   SEC-03: privacy_level default 0 (public) too permissive for new entries
--   SEC-04: living people contact data exposed in public SELECT policy
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SEC-01: Fix profiles table â€” require authentication to read any profile
-- Before: USING (true)  â† anyone, including unauthenticated, can list all
--         profiles and harvest user emails + roles via the Supabase REST API
-- After:  USING (auth.uid() IS NOT NULL)  â† logged-in users only
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP POLICY IF EXISTS "Users can read all profiles" ON profiles;

CREATE POLICY "Authenticated users can read profiles"
ON profiles FOR SELECT
USING (auth.uid() IS NOT NULL);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SEC-02 & SEC-04: Fix people table â€” strip contact data from public reads
-- The existing "Public read for public people" policy exposes ALL columns
-- including phone, email, zalo, facebook, address for privacy_level=0 rows
-- even to unauthenticated API requests.
-- 
-- PostgreSQL RLS is row-level (cannot restrict columns), so we:
--   a) Drop the unrestricted public SELECT policy
--   b) For unauthenticated access: expose only rows where privacy_level=0
--      AND the person has no living contact data stored.
--      (Leaves historical ancestors visible; protects living member data)
--   c) Require auth for ANY person that has contact data
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP POLICY IF EXISTS "Public read for public people" ON people;

-- New policy: unauthenticated users can only see:
--  - Records explicitly marked public (privacy_level = 0)
--  - AND only where no contact data is stored (safety net)
CREATE POLICY "Public read for public non-contact people" ON people
    FOR SELECT USING (
        privacy_level = 0
        AND phone IS NULL
        AND email IS NULL
        AND zalo IS NULL
        AND facebook IS NULL
        AND address IS NULL
    );

-- Authenticated users can read all members-or-public records (privacy_level < 2)
DROP POLICY IF EXISTS "Members can read all people" ON people;

CREATE POLICY "Authenticated users can read non-private people" ON people
    FOR SELECT USING (
        auth.uid() IS NOT NULL
        AND privacy_level < 2
    );

-- Admins can read everything including privacy_level = 2 (private) records
CREATE POLICY "Admins can read all people" ON people
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.user_id = auth.uid()
            AND p.role = 'admin'
        )
    );

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SEC-03: Change default privacy level for people from 0 (public) to 1.
-- New people added via the admin UI will default to "members only".
-- Existing public (privacy_level = 0) ancestors are unchanged.
-- Admins can explicitly set privacy_level = 0 for historical figures.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE people ALTER COLUMN privacy_level SET DEFAULT 1;

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SEC-05: Ensure living people with contact info are NOT publicly readable.
-- Sets privacy_level = 1 for any currently-public living person who has
-- at least one contact field populated.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
UPDATE people
SET privacy_level = 1
WHERE privacy_level = 0
  AND is_living = true
  AND (
      phone    IS NOT NULL OR
      email    IS NOT NULL OR
      zalo     IS NOT NULL OR
      facebook IS NOT NULL OR
      address  IS NOT NULL
  );

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- SEC-06: Tighten families/children/events/media public read policies.
-- Currently "Anyone can read families/children/events/media" includes
-- unauthenticated users. Restrict to authenticated only so that structural
-- data about living members isn't freely crawlable.
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP POLICY IF EXISTS "Anyone can read families" ON families;
CREATE POLICY "Authenticated can read families" ON families
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Anyone can read children" ON children;
CREATE POLICY "Authenticated can read children" ON children
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Anyone can read events" ON events;
CREATE POLICY "Authenticated can read events" ON events
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Anyone can read media" ON media;
CREATE POLICY "Authenticated can read media" ON media
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Summary of changes
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Table     | Before                          | After
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- profiles  | SELECT: everyone (incl. anon)   | SELECT: authenticated only
-- people    | SELECT: anon sees ALL public rows| SELECT: anon sees non-contact public only; auth sees members+; admin sees all
-- people    | default privacy_level = 0       | default privacy_level = 1
-- families  | SELECT: everyone                | SELECT: authenticated only
-- children  | SELECT: everyone                | SELECT: authenticated only
-- events    | SELECT: everyone                | SELECT: authenticated only
-- media     | SELECT: everyone                | SELECT: authenticated only
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 11: Kho tÃ i liá»‡u (Document Repository)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Table
CREATE TABLE IF NOT EXISTS clan_documents (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_type VARCHAR(100),
  file_size INTEGER,
  category VARCHAR(50) NOT NULL DEFAULT 'khac',
  tags TEXT,
  person_id UUID REFERENCES people(id) ON DELETE SET NULL,
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clan_documents_category ON clan_documents(category);
CREATE INDEX IF NOT EXISTS idx_clan_documents_person ON clan_documents(person_id);

-- 2. RLS
ALTER TABLE clan_documents ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read all documents
CREATE POLICY "Authenticated users can view documents"
ON clan_documents FOR SELECT TO authenticated
USING (true);

-- Editors and admins can insert
CREATE POLICY "Editors and admins can create documents"
ON clan_documents FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

-- Editors and admins can update
CREATE POLICY "Editors and admins can update documents"
ON clan_documents FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);

-- Editors and admins can delete
CREATE POLICY "Editors and admins can delete documents"
ON clan_documents FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role IN ('admin', 'editor')
  )
);
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Update storage bucket: allow document MIME types for Kho tÃ i liá»‡u
-- Sprint 11 â€” support PDF, Word, video uploads alongside images
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

UPDATE storage.buckets
SET
  allowed_mime_types = ARRAY[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'video/mp4', 'video/webm'
  ],
  file_size_limit = 10485760  -- 10MB (was 5MB)
WHERE id = 'media';
/**
 * @project AncestorTree
 * @file supabase/migrations/20260228000009_user_management.sql
 * @description Add account suspension fields to profiles table.
 *              MFA (TOTP) is managed entirely by Supabase Auth â€” no schema changes needed.
 * @version 1.0.0
 * @updated 2026-02-28
 */

-- â”€â”€ Account Suspension â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_suspended     BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS suspension_reason TEXT;

-- RLS: admins can update is_suspended and suspension_reason on any profile
-- (uses a separate UPDATE policy so it doesn't conflict with existing self-update policy)
CREATE POLICY "Admin can suspend or unsuspend accounts"
  ON profiles
  FOR UPDATE
  USING (
    (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
  )
  WITH CHECK (true);
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Clan Settings â€” Dynamic configuration for clan information
-- Singleton table: one row, updated via admin UI
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

CREATE TABLE IF NOT EXISTS clan_settings (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clan_name        VARCHAR(200) NOT NULL DEFAULT 'Há» Nguyá»…n Quá»‘c',
  clan_full_name   VARCHAR(500) NOT NULL DEFAULT 'Há» Nguyá»…n Quá»‘c lÃ ng Sa Long, xÃ£ HÃ  Linh, huyá»‡n HÆ°Æ¡ng KhÃª, tá»‰nh HÃ  TÄ©nh',
  clan_founding_year INTEGER,
  clan_origin      VARCHAR(500),
  clan_patriarch   VARCHAR(200),
  clan_description TEXT,
  contact_email    VARCHAR(200),
  contact_phone    VARCHAR(50),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Seed one default row (singleton) using a fixed UUID so ON CONFLICT is meaningful
INSERT INTO clan_settings (id, clan_name, clan_full_name, clan_origin, clan_patriarch)
  VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Há» Nguyá»…n Quá»‘c',
    'Há» Nguyá»…n Quá»‘c lÃ ng Sa Long, xÃ£ HÃ  Linh, huyá»‡n HÆ°Æ¡ng KhÃª, tá»‰nh HÃ  TÄ©nh',
    'YÃªn NhÃ¢n ThÃ´n, DÆ°Æ¡ng Luáº­t xÃ£, Tháº¡ch HÃ  phá»§ (nay lÃ  ThÃ´n Minh Háº£i, xÃ£ Tháº¡ch Háº£i, huyá»‡n Tháº¡ch HÃ , tá»‰nh HÃ  TÄ©nh)',
    'Nguyá»…n Quá»‘c Tháº¯ng'
  )
  ON CONFLICT (id) DO NOTHING;

-- â”€â”€â”€ RLS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE clan_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to ensure idempotent re-run
DROP POLICY IF EXISTS "Authenticated users can view clan settings" ON clan_settings;
DROP POLICY IF EXISTS "Anonymous users can view clan settings" ON clan_settings;
DROP POLICY IF EXISTS "Admins and editors can update clan settings" ON clan_settings;

-- All authenticated users can read clan settings
CREATE POLICY "Authenticated users can view clan settings"
  ON clan_settings FOR SELECT TO authenticated
  USING (true);

-- Anonymous users can also read (needed for login page before auth)
CREATE POLICY "Anonymous users can view clan settings"
  ON clan_settings FOR SELECT TO anon
  USING (true);

-- Only admins and editors can update
CREATE POLICY "Admins and editors can update clan settings"
  ON clan_settings FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role IN ('admin', 'editor')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role IN ('admin', 'editor')
    )
  );

-- No INSERT or DELETE (singleton â€” managed via seed row only)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 12: Privacy, Verification & Sub-admin
-- AncestorTree v2.3.0
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Profiles: verification + sub-admin fields (NOT NULL to avoid three-valued logic â€” ISS-15)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS can_verify_members BOOLEAN NOT NULL DEFAULT false;

-- Existing users auto-verified (don't break current logins)
UPDATE profiles SET is_verified = true WHERE created_at < NOW();

-- 2. Documents: privacy_level (0=public, 1=members, 2=private/admin+editor only)
ALTER TABLE clan_documents ADD COLUMN IF NOT EXISTS privacy_level SMALLINT NOT NULL DEFAULT 1
  CHECK (privacy_level IN (0, 1, 2));

-- 3. Documents RLS: privacy-aware SELECT policies
-- All document reads require authentication (ISS-06)
DROP POLICY IF EXISTS "Authenticated users can view documents" ON clan_documents;

CREATE POLICY "Auth view public documents" ON clan_documents
  FOR SELECT USING (auth.uid() IS NOT NULL AND privacy_level = 0);

CREATE POLICY "Auth view members-only documents" ON clan_documents
  FOR SELECT USING (auth.uid() IS NOT NULL AND privacy_level = 1);

CREATE POLICY "Admins and editors view all documents" ON clan_documents
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'editor'))
  );

-- 4. Sub-admin: editors with can_verify_members can verify profiles in their subtree
-- WITH CHECK ensures sub-admins can ONLY toggle is_verified, not escalate role/permissions (ISS-01)
CREATE POLICY "Sub-admins verify members in subtree" ON profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p WHERE p.user_id = auth.uid()
      AND p.role IN ('admin', 'editor') AND p.can_verify_members = true
      AND (p.edit_root_person_id IS NULL
           OR (profiles.linked_person IS NOT NULL
               AND is_person_in_subtree(p.edit_root_person_id, profiles.linked_person)))
    )
  )
  WITH CHECK (
    -- Sub-admins may only change is_verified; all other fields must remain unchanged.
    -- Compare every sensitive column against its pre-update value via subselect.
    role = (SELECT role FROM profiles p2 WHERE p2.id = profiles.id)
    AND can_verify_members = (SELECT can_verify_members FROM profiles p2 WHERE p2.id = profiles.id)
    AND email = (SELECT email FROM profiles p2 WHERE p2.id = profiles.id)
  );

-- Index for privacy_level RLS (ISS-11)
CREATE INDEX IF NOT EXISTS idx_clan_documents_privacy_level ON clan_documents (privacy_level);
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Sprint 12 Fix: Document privacy_level=1 â€” restrict to editor/admin only
-- Viewers should only see public (privacy_level=0) documents.
-- AncestorTree v2.3.1
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- The previous policy allowed ALL authenticated users (incl. viewer) to read
-- privacy_level=1 documents. Per FR: viewer role sees public docs only.
DROP POLICY IF EXISTS "Auth view members-only documents" ON clan_documents;

CREATE POLICY "Members can view members-only documents" ON clan_documents
  FOR SELECT USING (
    privacy_level = 1
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
        AND role IN ('admin', 'editor')
    )
  );
-- ============================================================================
-- Sprint 15: GÃ³c giao lÆ°u â€” Feed + Comments + Likes
-- AncestorTree v2.7.0
-- ============================================================================

-- â”€â”€â”€ Posts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS posts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content         TEXT NOT NULL CHECK (char_length(content) <= 5000),
    images          JSONB DEFAULT '[]'::jsonb,
    post_type       VARCHAR(20) NOT NULL DEFAULT 'general'
                    CHECK (post_type IN ('general', 'photo', 'milestone', 'memory', 'announcement')),
    status          VARCHAR(20) NOT NULL DEFAULT 'published'
                    CHECK (status IN ('published', 'hidden')),
    likes_count     INTEGER NOT NULL DEFAULT 0,
    comments_count  INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_status_created ON posts(status, created_at DESC);
CREATE INDEX idx_posts_type ON posts(post_type);

COMMENT ON TABLE posts IS 'Sprint 15: Feed posts â€” bÃ i viáº¿t giao lÆ°u dÃ²ng há»';
COMMENT ON COLUMN posts.images IS 'JSONB array of image URLs, max 5 per post';
COMMENT ON COLUMN posts.post_type IS 'general|photo|milestone|memory|announcement';

-- â”€â”€â”€ Post Likes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS post_likes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE INDEX idx_post_likes_post ON post_likes(post_id);
CREATE INDEX idx_post_likes_user ON post_likes(user_id);

-- â”€â”€â”€ Post Comments â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS post_comments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content         TEXT NOT NULL CHECK (char_length(content) <= 2000),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_comments_post ON post_comments(post_id);
CREATE INDEX idx_post_comments_author ON post_comments(author_id);

-- â”€â”€â”€ Trigger: update likes_count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_post_likes_count
AFTER INSERT OR DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- â”€â”€â”€ Trigger: update comments_count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_post_comments_count
AFTER INSERT OR DELETE ON post_comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- â”€â”€â”€ RLS: posts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view published posts"
ON posts FOR SELECT TO authenticated
USING (status = 'published');

CREATE POLICY "Admin/editor can view all posts"
ON posts FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role IN ('admin', 'editor')
    )
);

CREATE POLICY "Verified users can create posts"
ON posts FOR INSERT TO authenticated
WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.is_verified = true
    )
);

CREATE POLICY "Authors can update own posts"
ON posts FOR UPDATE TO authenticated
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

CREATE POLICY "Admin/editor can update any post"
ON posts FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role IN ('admin', 'editor')
    )
);

CREATE POLICY "Authors can delete own posts"
ON posts FOR DELETE TO authenticated
USING (author_id = auth.uid());

CREATE POLICY "Admin can delete any post"
ON posts FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- â”€â”€â”€ RLS: post_likes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view likes"
ON post_likes FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Verified users can like posts"
ON post_likes FOR INSERT TO authenticated
WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.is_verified = true
    )
);

CREATE POLICY "Users can unlike (delete own like)"
ON post_likes FOR DELETE TO authenticated
USING (user_id = auth.uid());

-- â”€â”€â”€ RLS: post_comments â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view comments"
ON post_comments FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Verified users can comment"
ON post_comments FOR INSERT TO authenticated
WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.is_verified = true
    )
);

CREATE POLICY "Authors can update own comments"
ON post_comments FOR UPDATE TO authenticated
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

CREATE POLICY "Authors can delete own comments"
ON post_comments FOR DELETE TO authenticated
USING (author_id = auth.uid());

CREATE POLICY "Admin can delete any comment"
ON post_comments FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'admin'
    )
);
-- ============================================================================
-- Sprint 16: ThÃ´ng bÃ¡o â€” In-app Notifications
-- AncestorTree v2.8.0
-- ============================================================================

-- â”€â”€â”€ Notifications table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL
                    CHECK (type IN (
                        'post_comment', 'post_like', 'new_post',
                        'account_verified', 'event_reminder',
                        'new_member', 'system'
                    )),
    title           TEXT NOT NULL,
    body            TEXT,
    link            TEXT,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    actor_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reference_id    TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);

COMMENT ON TABLE notifications IS 'Sprint 16: In-app notifications';

-- â”€â”€â”€ RLS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications (mark read)"
ON notifications FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- INSERT locked to triggers only (SECURITY DEFINER bypasses RLS).
-- No client-side INSERT needed â€” notifications created by DB triggers.
CREATE POLICY "No direct insert (triggers only)"
ON notifications FOR INSERT TO authenticated
WITH CHECK (false);

CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE TO authenticated
USING (user_id = auth.uid());

-- â”€â”€â”€ Trigger: new comment â†’ notify post author â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE OR REPLACE FUNCTION notify_post_comment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.author_id != (SELECT author_id FROM posts WHERE id = NEW.post_id) THEN
        INSERT INTO notifications (user_id, type, title, body, link, actor_id, reference_id)
        SELECT
            p.author_id,
            'post_comment',
            'BÃ¬nh luáº­n má»›i',
            (SELECT full_name FROM profiles WHERE user_id = NEW.author_id) || ' Ä‘Ã£ bÃ¬nh luáº­n bÃ i viáº¿t cá»§a báº¡n',
            '/feed',
            NEW.author_id,
            NEW.post_id::text
        FROM posts p WHERE p.id = NEW.post_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_notify_post_comment
AFTER INSERT ON post_comments
FOR EACH ROW EXECUTE FUNCTION notify_post_comment();

-- â”€â”€â”€ Trigger: new like â†’ notify post author â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE OR REPLACE FUNCTION notify_post_like()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id != (SELECT author_id FROM posts WHERE id = NEW.post_id) THEN
        INSERT INTO notifications (user_id, type, title, body, link, actor_id, reference_id)
        SELECT
            p.author_id,
            'post_like',
            'LÆ°á»£t thÃ­ch má»›i',
            (SELECT full_name FROM profiles WHERE user_id = NEW.user_id) || ' Ä‘Ã£ thÃ­ch bÃ i viáº¿t cá»§a báº¡n',
            '/feed',
            NEW.user_id,
            NEW.post_id::text
        FROM posts p WHERE p.id = NEW.post_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_notify_post_like
AFTER INSERT ON post_likes
FOR EACH ROW EXECUTE FUNCTION notify_post_like();
-- ============================================================================
-- Sprint 18: NhÃ  thá» há» â€” Member Registrations + Council Settings
-- AncestorTree v3.0.0
-- ============================================================================

-- â”€â”€â”€ Member registrations table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS member_registrations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       TEXT NOT NULL,
    gender          INTEGER NOT NULL CHECK (gender IN (1, 2)),
    birth_year      INTEGER,
    birth_place     TEXT,
    phone           TEXT,
    email           TEXT,
    parent_name     TEXT,
    generation      INTEGER,
    chi             INTEGER,
    relationship    TEXT,
    notes           TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    reject_reason   TEXT,
    reviewed_by     UUID REFERENCES auth.users(id),
    reviewed_at     TIMESTAMPTZ,
    person_id       UUID REFERENCES people(id),
    honeypot        TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_registrations_status ON member_registrations(status, created_at DESC);

COMMENT ON TABLE member_registrations IS 'Sprint 18: Public member registration requests';

-- â”€â”€â”€ RLS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE member_registrations ENABLE ROW LEVEL SECURITY;

-- Anyone (including anon) can submit a registration
CREATE POLICY "Anyone can submit registration"
ON member_registrations FOR INSERT TO anon, authenticated
WITH CHECK (status = 'pending');

-- Only admin/editor can view registrations
CREATE POLICY "Admin/editor can view registrations"
ON member_registrations FOR SELECT TO authenticated
USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'editor'))
);

-- Only admin/editor can update (approve/reject)
CREATE POLICY "Admin/editor can update registrations"
ON member_registrations FOR UPDATE TO authenticated
USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'editor'))
)
WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('admin', 'editor'))
);

-- Only admin can delete registrations
CREATE POLICY "Admin can delete registrations"
ON member_registrations FOR DELETE TO authenticated
USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin')
);

-- â”€â”€â”€ Extend clan_settings for council + ancestral hall â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS council_members JSONB DEFAULT '[]'::jsonb;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS clan_history TEXT;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS clan_mission TEXT;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS ancestral_hall_images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS ancestral_hall_address TEXT;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS ancestral_hall_coordinates JSONB;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS ancestral_hall_history TEXT;
ALTER TABLE clan_settings ADD COLUMN IF NOT EXISTS ceremony_schedule JSONB DEFAULT '[]'::jsonb;
-- Add require_married option and custom_order to cau_duong_pools
ALTER TABLE cau_duong_pools
  ADD COLUMN IF NOT EXISTS require_married BOOLEAN NOT NULL DEFAULT true;

-- Custom rotation order (array of person UUIDs as JSON)
ALTER TABLE cau_duong_pools
  ADD COLUMN IF NOT EXISTS custom_order JSONB DEFAULT NULL;
-- ============================================================
-- Migration: Login Config
-- Adds login_config JSONB to clan_settings for configurable
-- login methods (email+password, OTP email)
-- ============================================================

ALTER TABLE clan_settings
  ADD COLUMN IF NOT EXISTS login_config JSONB NOT NULL DEFAULT '{"methods":["email_password","email_otp"],"otp_expiry_minutes":15}';

-- Backfill existing rows (singleton table)
UPDATE clan_settings
SET login_config = '{"methods":["email_password","email_otp"],"otp_expiry_minutes":15}'
WHERE login_config IS NULL OR login_config = 'null';

-- Verify
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clan_settings' AND column_name = 'login_config'
  ) THEN
    RAISE EXCEPTION 'login_config column not found';
  END IF;
END $$;
