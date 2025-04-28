
-- Drop and recreate the database
DROP DATABASE IF EXISTS MLRG;
CREATE DATABASE MLRG;
USE MLRG;

-- Users table
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    cooking_level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    experience_points INT DEFAULT 0
);

-- Recipes table
CREATE TABLE Recipes (
    recipe_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    ingredients TEXT,
    instructions TEXT,
    preparation_time INT,
    cooking_time INT,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced'),
    servings INT,
    image_url TEXT,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- Categories table
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- Junction table for many-to-many between recipes and categories
CREATE TABLE Recipe_Categories (
    recipe_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (recipe_id, category_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE
);

-- UserProgress table to track completed recipes
CREATE TABLE UserProgress (
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

-- Reviews table
CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    recipe_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Trophies table
CREATE TABLE Trophies (
    trophy_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    image_url TEXT
);

-- User_Trophies table
CREATE TABLE User_Trophies (
    user_id INT NOT NULL,
    trophy_id INT NOT NULL,
    PRIMARY KEY (user_id, trophy_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (trophy_id) REFERENCES Trophies(trophy_id)
);

-- Stored procedures
DELIMITER //
CREATE PROCEDURE sp_register_user(IN p_username VARCHAR(50), IN p_email VARCHAR(100), IN p_password VARCHAR(255))
BEGIN
  INSERT INTO Users (username, email, password_hash)
  VALUES (p_username, p_email, p_password);
END //
CREATE PROCEDURE sp_login_user(IN p_username VARCHAR(50), IN p_password VARCHAR(255))
BEGIN
  SELECT * FROM Users
  WHERE username = p_username AND password_hash = p_password;
END //
CREATE PROCEDURE sp_get_recipe_by_id(IN p_recipe_id INT)
BEGIN
  SELECT * FROM Recipes WHERE recipe_id = p_recipe_id;
END //

CREATE PROCEDURE sp_add_review(
    IN p_recipe_id INT,
    IN p_user_id INT,
    IN p_rating INT,
    IN p_comment TEXT
)
BEGIN
    INSERT INTO Reviews (recipe_id, user_id, rating, comment)
    VALUES (p_recipe_id, p_user_id, p_rating, p_comment);
END //

CREATE PROCEDURE sp_complete_recipe(IN p_user_id INT, IN p_recipe_id INT)
BEGIN
  INSERT INTO UserProgress (user_id, recipe_id)
  VALUES (p_user_id, p_recipe_id)
  ON DUPLICATE KEY UPDATE completed_at = CURRENT_TIMESTAMP;
  UPDATE Users SET experience_points = experience_points + 10 WHERE user_id = p_user_id;
END //
CREATE PROCEDURE sp_get_user_profile(IN p_user_id INT)
BEGIN
  SELECT username, cooking_level, experience_points FROM Users WHERE user_id = p_user_id;
END //
CREATE PROCEDURE sp_get_user_trophies(IN p_user_id INT)
BEGIN
  SELECT T.* FROM Trophies T JOIN User_Trophies UT ON T.trophy_id = UT.trophy_id WHERE UT.user_id = p_user_id;
END //
CREATE PROCEDURE sp_get_dashboard_stats(IN p_user_id INT)
BEGIN
  SELECT COUNT(DISTINCT UP.recipe_id) AS completed_recipes, U.cooking_level, U.experience_points,
         (SELECT COUNT(*) FROM User_Trophies WHERE user_id = p_user_id) AS trophies_earned
  FROM Users U LEFT JOIN UserProgress UP ON U.user_id = UP.user_id
  WHERE U.user_id = p_user_id GROUP BY U.user_id;
END //
DELIMITER ;

-- Sample Data
INSERT INTO Users (username, email, password_hash) VALUES 
('testchef', 'chef@example.com', 'password123'),
('user2', 'u2@example.com', 'pass'),
('user3', 'u3@example.com', 'pass'),
('user4', 'u4@example.com', 'pass'),
('user5', 'u5@example.com', 'pass'),
('user6', 'u6@example.com', 'pass'),
('1', 'u6@example.com', '1');

-- Recipes (including all difficulty levels)
-- (data continues next cell due to length)

INSERT INTO Recipes (recipe_id,title, description, ingredients, instructions, preparation_time, cooking_time, difficulty_level, servings, image_url, user_id) VALUES
(1,'Classic Pancakes', 'Perfect pancakes are easier to make than you think. This pancake recipe produces thick, fluffy, and all-around delicious pancakes with just a few ingredients that are probably already in your kitchen.',
 '1 cup flour\n1 tbsp sugar\n2 tsp baking powder\n1/4 tsp salt\n1 cup milk\n1 egg\n2 tbsp melted butter',
 '1. Mix dry ingredients\n2. Add wet ingredients\n3. Cook on griddle\n4. Serve with syrup',
 10, 15, 'beginner', 4, 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445', 1),

(2,'Beef Bourguignon', 'Beef bourguignon, or beef Burgundy, is a classic French beef stew made with onions (regular and pearl onions), carrots, mushrooms, and herbs, and simmered in a sauce of red wine and beef broth. Its just as much about the impossibly tender chunks of beef as it is the deeply flavored sauce.PS-He later got beaten up because he made beef.',
 '2 lbs beef chuck\n1 bottle red wine\n1 onion\n2 carrots\n3 cloves garlic\n1 tbsp tomato paste\n1 tsp thyme',
 '1. Brown the beef\n2. Sauté vegetables\n3. Deglaze with wine\n4. Slow cook for 3 hours',
 30, 180, 'advanced', 6, 'https://images.unsplash.com/photo-1547592180-85f173990554', 2),

(3,'Caesar Salad', 'A Caesar salad (also spelled Cesar, César and Cesare), also known as Caesars salad, is a green salad of romaine lettuce and croutons dressed with lemon juice (or lime juice), olive oil, eggs, Worcestershire sauce, anchovies, garlic, Dijon mustard, Parmesan and black pepper. Made by our very own master of masterchefs, overlord of lords,etc.,etc. Lohith Reddy.',
 '1 romaine lettuce\n1/2 cup parmesan cheese\n1 cup croutons\n2 cloves garlic\n1 egg yolk\n1/2 cup olive oil\n1 lemon',
 '1. Make dressing\n2. Toss lettuce with dressing\n3. Add croutons and cheese\n4. Serve immediately',
 15, 0, 'beginner', 2, 'https://images.unsplash.com/photo-1546793665-c74683f339c1', 3),

(4,'Homemade Pizza', 'Pizza is an Italian, specifically Neapolitan, dish typically consisting of a flat base of leavened wheat-based dough topped with tomato, cheese, and other ingredients, baked at a high temperature, traditionally in a wood-fired oven.',
 '2 cups flour\n1 tsp yeast\n1 tsp salt\n3/4 cup warm water\n1/2 cup tomato sauce\n2 cups mozzarella cheese\ntoppings of choice',
 '1. Make dough and let rise\n2. Roll out dough\n3. Add sauce and toppings\n4. Bake at 450°F for 12-15 minutes',
 60, 15, 'intermediate', 4, 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38', 4),

(5,'Chocolate Soufflé', 'Light as a feather, these hot chocolate soufflés are sure to please. Perfect for a dinner party dessert, served with chocolate cream sauce. The recipe has been through so many struggles as it was first initialized by an amateur or a below amateur chef namely Krishaa Daga but was saved and fixed by, you guessed who, Lohith',
 '4 oz dark chocolate\n1/4 cup butter\n1/3 cup sugar\n3 eggs\n1 tsp vanilla extract\npinch of salt',
 '1. Melt chocolate and butter\n2. Beat egg whites\n3. Fold ingredients together\n4. Bake at 375°F for 15 minutes',
 20, 15, 'advanced', 2, 'https://images.unsplash.com/photo-1571115177098-24ec42ed204d', 5),

(6,'Vegetable Stir Fry', 'Vegetable Stir Fry is a mixture of colorful vegetables sautéed in a sweet and savory sauce that makes for a simple weeknight meal! Less than 30 minutes to make from start to finish!',
 '2 cups mixed vegetables\n1 tbsp oil\n2 cloves garlic\n1 tbsp soy sauce\n1 tsp ginger\n1 tsp sesame oil',
 '1. Heat oil in wok\n2. Add garlic and ginger\n3. Stir fry vegetables\n4. Add sauces and serve',
 10, 10, 'beginner', 2, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 6),

(7,'Garlic Bread', 'Garlic bread (also called garlic toast) consists of bread (usually baguette, sourdough or ciabatta) topped with garlic and occasionally olive oil or butter, and may include additional herbs, such as oregano or chives.',
 '1 baguette\n4 tbsp butter\n2 cloves garlic\nParsley\nSalt',
 '1. Slice bread\n2. Mix garlic butter\n3. Spread and toast',
 5, 10, 'beginner', 4, 'https://www.ambitiouskitchen.com/wp-content/uploads/2023/02/Garlic-Bread-4.jpg', 1),

(8,'Scrambled Eggs', 'Scrambled eggs are a dish made from eggs that have been whisked or beaten together and then cooked, resulting in a fluffy, soft texture. The egg mixture is typically seasoned with salt and pepper and can be cooked with butter, oil, or milk.',
 '3 eggs\n1 tbsp milk\nSalt\nPepper\nButter',
 '1. Beat eggs\n2. Cook on low heat\n3. Stir gently\n4. Serve warm',
 2, 5, 'beginner', 2, 'https://www.livingonadime.com/wp-content/uploads/easy-scrambled-eggs-recipe-tr.jpg', 1),

(9,'Chicken Tikka Masala', 'Spiced chicken in creamy tomato sauce. A classic by our world renowned masterchef Lohith Reddy. He really knows everything. His sous chef Krish Garg helped in making this dish but was later disowned by his parents for touching chicken as he is actually a vegetarian(eww). ',
 '500g chicken\nYogurt\nTomatoes\nCream\nSpices\nGarlic\nGinger',
 '1. Marinate chicken\n2. Cook in sauce\n3. Simmer and serve',
 20, 30, 'intermediate', 4, 'https://www.seriouseats.com/thmb/DbQHUK2yNCALBnZE-H1M2AKLkok%3D/1500x0/filters%3Ano_upscale%28%29%3Amax_bytes%28150000%29%3Astrip_icc%28%29/chicken-tikka-masala-for-the-grill-recipe-hero-2_1-cb493f49e30140efbffec162d5f2d1d7.JPG', 1),

(10,'Pad Thai', 'Pad Thai is a popular Thai street food dish primarily made with stir-fried rice noodles, scrambled eggs, tofu, and a variety of vegetables and protein options.',
 'Rice noodles\nEggs\nTofu\nTamarind\nPeanuts\nBean sprouts\nFish sauce',
 '1. Soak noodles\n2. Stir-fry everything\n3. Add sauce\n4. Serve hot',
 15, 20, 'intermediate', 3, 'https://tastythriftytimely.com/wp-content/uploads/2023/01/Homemade-Vegan-Pad-Thai-Featured.jpg', 1),

(11,'Ratatouille', 'Ratatouille is a French stew made with late summer vegetables like eggplant, tomatoes, peppers, and zucchini. Its rich with olive oil, bright with vinegar, and flecked with fresh herbs.',
 'Zucchini\nEggplant\nTomatoes\nOnion\nGarlic\nOlive oil\nHerbs',
 '1. Slice vegetables\n2. Layer in dish\n3. Bake with sauce',
 25, 60, 'advanced', 6, 'https://images.immediate.co.uk/production/volatile/sites/30/2019/05/Ratatouille-ea27a5c.jpg?quality=90&resize=440%2C400', 1),

(12,'Lamb Rogan Josh', 'Rogan josh consists of pieces of lamb or mutton braised with a gravy flavoured with garlic, ginger and aromatic spices (clove, bay leaves, cardamom, and cinnamon), and in some versions incorporating onions or yoghurt.',
 '1kg lamb\nYogurt\nOnion\nGarlic\nGinger\nSpices\nGhee',
 '1. Sear lamb\n2. Add spices and yogurt\n3. Cook till tender',
 20, 90, 'advanced', 5, 'https://img.taste.com.au/TFQ_zAsZ/taste/2017/06/lamb-rogan-josh-127388-1.jpg', 1);

INSERT INTO Categories (name) VALUES ('Breakfast');
INSERT INTO Recipe_Categories (recipe_id, category_id) VALUES (1, 1);

-- ✅ Insert a test review
INSERT INTO Reviews (recipe_id, user_id, rating, comment)
VALUES (1, 1, 5, 'Delicious and easy to make!');

-- ✅ Insert a trophy
INSERT INTO Trophies (name, description, image_url)
VALUES ('First Cook', 'Completed your first recipe!', 'https://cdn-icons-png.flaticon.com/512/3132/3132773.png');

-- ✅ Give the trophy to the user
INSERT INTO User_Trophies (user_id, trophy_id)
VALUES (1, 1);

-- ✅ Mark the recipe as complete
INSERT INTO UserProgress (user_id, recipe_id)
VALUES (1, 1);

select * from Users;
select * from UserProgress;
select * from Reviews;



