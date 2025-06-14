-- Create database
CREATE DATABASE IF NOT EXISTS kos_finance;
USE kos_finance;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL,
  type ENUM('income', 'expense') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(100) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  date DATE NOT NULL,
  type ENUM('income', 'expense') NOT NULL,
  category_id INT NOT NULL,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Insert default categories
INSERT INTO categories (name, icon, type) VALUES
-- Income categories
('Salary', 'money_bill', 'income'),
('Allowance', 'gift', 'income'),
('Bonus', 'award', 'income'),
('Investment', 'chart_line', 'income'),
('Other', 'plus_circle', 'income'),

-- Expense categories
('Food', 'utensils', 'expense'),
('Transportation', 'car', 'expense'),
('Housing', 'home', 'expense'),
('Entertainment', 'film', 'expense'),
('Shopping', 'shopping_bag', 'expense'),
('Utilities', 'bolt', 'expense'),
('Health', 'medkit', 'expense'),
('Education', 'book', 'expense'),
('Personal', 'user', 'expense'),
('Other', 'minus_circle', 'expense');
