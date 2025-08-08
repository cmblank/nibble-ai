-- Create only the missing tables (skip recipes since it exists)

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT,
    dietary_preferences JSONB DEFAULT '[]'::jsonb,
    allergies JSONB DEFAULT '[]'::jsonb,
    favorite_cuisines JSONB DEFAULT '[]'::jsonb,
    cooking_skill_level TEXT CHECK (cooking_skill_level IN ('beginner', 'intermediate', 'advanced')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create daily_checkins table
CREATE TABLE IF NOT EXISTS daily_checkins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    mood TEXT NOT NULL,
    check_in_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_pantry table
CREATE TABLE IF NOT EXISTS user_pantry (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    item_name TEXT NOT NULL,
    category TEXT,
    quantity TEXT,
    expiry_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_recipes table
CREATE TABLE IF NOT EXISTS user_recipes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    recipe_id UUID NOT NULL,
    is_favorite BOOLEAN DEFAULT FALSE,
    personal_notes TEXT,
    personal_rating INTEGER CHECK (personal_rating >= 1 AND personal_rating <= 5),
    times_cooked INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pantry ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recipes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables
CREATE POLICY "Users can view own profile" ON profiles 
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles 
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles 
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own check-ins" ON daily_checkins 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own check-ins" ON daily_checkins 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own pantry" ON user_pantry 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own pantry" ON user_pantry 
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own saved recipes" ON user_recipes 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own saved recipes" ON user_recipes 
    FOR ALL USING (auth.uid() = user_id);
