-- Nibble Fresh App Database Schema - Clean Version
-- Run this in your Supabase SQL Editor

-- Create profiles table (extends Supabase auth.users)
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

-- Create recipes table
CREATE TABLE IF NOT EXISTS recipes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    cuisine TEXT,
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    cooking_time_minutes INTEGER,
    difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    ingredients JSONB DEFAULT '[]'::jsonb,
    instructions JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    nutrition_info JSONB DEFAULT '{}'::jsonb,
    image_url TEXT,
    source_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_recipes table (for saved/favorite recipes)
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
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recipes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Profiles: Users can only see and edit their own profile
CREATE POLICY "Users can view own profile" ON profiles 
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles 
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles 
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Daily check-ins: Users can only see and edit their own check-ins
CREATE POLICY "Users can view own check-ins" ON daily_checkins 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own check-ins" ON daily_checkins 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User pantry: Users can only see and edit their own pantry
CREATE POLICY "Users can view own pantry" ON user_pantry 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own pantry" ON user_pantry 
    FOR ALL USING (auth.uid() = user_id);

-- Recipes: Public read, authenticated users can add
CREATE POLICY "Anyone can view recipes" ON recipes 
    FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert recipes" ON recipes 
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- User recipes: Users can only see and edit their own saved recipes
CREATE POLICY "Users can view own saved recipes" ON user_recipes 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own saved recipes" ON user_recipes 
    FOR ALL USING (auth.uid() = user_id);

-- Insert sample recipes
INSERT INTO recipes (name, description, cuisine, meal_type, cooking_time_minutes, difficulty_level, ingredients, instructions, tags, nutrition_info) VALUES
(
    'Mediterranean Chickpea Salad',
    'A fresh and healthy chickpea salad with Mediterranean flavors',
    'Mediterranean',
    'lunch',
    15,
    'easy',
    '["1 can chickpeas, drained", "1 cucumber, diced", "2 tomatoes, diced", "1/4 red onion, diced", "1/4 cup olive oil", "2 tbsp lemon juice", "2 tbsp parsley", "Salt and pepper"]'::jsonb,
    '["Drain and rinse chickpeas", "Dice vegetables", "Mix olive oil and lemon juice", "Combine all ingredients", "Season with salt and pepper", "Chill for 30 minutes before serving"]'::jsonb,
    '["vegetarian", "vegan", "gluten-free", "healthy", "quick"]'::jsonb,
    '{"calories": 280, "protein": 12, "carbs": 35, "fat": 12, "fiber": 10}'::jsonb
),
(
    'Thai Green Curry',
    'Aromatic and spicy Thai green curry with vegetables',
    'Thai',
    'dinner',
    30,
    'medium',
    '["400ml coconut milk", "3 tbsp green curry paste", "1 eggplant, cubed", "1 bell pepper, sliced", "100g green beans", "2 tbsp fish sauce", "1 tbsp brown sugar", "Thai basil leaves", "Jasmine rice"]'::jsonb,
    '["Heat coconut milk in a pan", "Add curry paste and cook for 2 minutes", "Add vegetables and cook for 10 minutes", "Season with fish sauce and sugar", "Simmer until vegetables are tender", "Garnish with Thai basil", "Serve over jasmine rice"]'::jsonb,
    '["spicy", "gluten-free", "dairy-free"]'::jsonb,
    '{"calories": 320, "protein": 8, "carbs": 25, "fat": 22, "fiber": 6}'::jsonb
),
(
    'Italian Pasta Primavera',
    'Light pasta dish with fresh seasonal vegetables',
    'Italian',
    'dinner',
    25,
    'easy',
    '["300g penne pasta", "1 zucchini, sliced", "1 bell pepper, strips", "1 cup cherry tomatoes", "2 cloves garlic", "1/4 cup olive oil", "1/2 cup parmesan cheese", "Fresh basil", "Salt and pepper"]'::jsonb,
    '["Cook pasta according to package directions", "Sauté garlic in olive oil", "Add vegetables and cook until tender", "Toss pasta with vegetables", "Add parmesan and fresh basil", "Season to taste"]'::jsonb,
    '["vegetarian", "quick", "family-friendly"]'::jsonb,
    '{"calories": 420, "protein": 16, "carbs": 58, "fat": 14, "fiber": 5}'::jsonb
),
(
    'Mexican Black Bean Tacos',
    'Delicious vegetarian tacos with seasoned black beans',
    'Mexican',
    'lunch',
    20,
    'easy',
    '["1 can black beans", "8 corn tortillas", "1 avocado", "1/4 red onion", "1 lime", "1 tsp cumin", "1 tsp chili powder", "Cilantro", "Salsa", "Hot sauce"]'::jsonb,
    '["Heat black beans with cumin and chili powder", "Warm tortillas", "Mash avocado with lime juice", "Dice red onion", "Assemble tacos with beans, avocado, onion", "Top with cilantro and salsa"]'::jsonb,
    '["vegetarian", "vegan", "gluten-free", "quick"]'::jsonb,
    '{"calories": 240, "protein": 10, "carbs": 42, "fat": 6, "fiber": 12}'::jsonb
),
(
    'Japanese Miso Soup',
    'Traditional Japanese soup with tofu and seaweed',
    'Japanese',
    'breakfast',
    10,
    'easy',
    '["3 tbsp miso paste", "4 cups water", "100g silken tofu", "2 sheets nori seaweed", "2 scallions", "1 tsp soy sauce"]'::jsonb,
    '["Heat water in a pot", "Whisk in miso paste until dissolved", "Add cubed tofu", "Tear nori into pieces and add", "Simmer for 2 minutes", "Garnish with sliced scallions"]'::jsonb,
    '["vegetarian", "vegan", "low-carb", "quick", "healthy"]'::jsonb,
    '{"calories": 80, "protein": 6, "carbs": 8, "fat": 3, "fiber": 2}'::jsonb
),
(
    'American Pancakes',
    'Fluffy pancakes perfect for weekend breakfast',
    'American',
    'breakfast',
    20,
    'easy',
    '["2 cups flour", "2 tbsp sugar", "2 tsp baking powder", "1 tsp salt", "2 eggs", "1.5 cups milk", "1/4 cup melted butter", "Maple syrup", "Butter for serving"]'::jsonb,
    '["Mix dry ingredients in a bowl", "Whisk eggs, milk, and melted butter", "Combine wet and dry ingredients", "Heat griddle over medium heat", "Pour batter and cook until bubbles form", "Flip and cook until golden", "Serve with butter and syrup"]'::jsonb,
    '["vegetarian", "breakfast", "family-friendly", "comfort-food"]'::jsonb,
    '{"calories": 350, "protein": 12, "carbs": 52, "fat": 12, "fiber": 2}'::jsonb
);
