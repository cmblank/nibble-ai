-- STEP 3: Insert sample recipes
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
);
