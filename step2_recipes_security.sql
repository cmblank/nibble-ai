-- STEP 2: Add security to recipes table
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view recipes" ON recipes 
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert recipes" ON recipes 
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
