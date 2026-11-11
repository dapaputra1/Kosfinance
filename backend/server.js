const express = require("express")
const mysql = require("mysql2/promise")
const cors = require("cors")
const bcrypt = require("bcryptjs")
const jwt = require("jsonwebtoken")
const dotenv = require("dotenv")

dotenv.config()

const app = express()
app.use(cors())
app.use(express.json())

// Database connection
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "kos_finance",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
})

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"]
  const token = authHeader && authHeader.split(" ")[1]

  if (token == null) return res.sendStatus(401)

  jwt.verify(token, process.env.JWT_SECRET || "your_jwt_secret", (err, user) => {
    if (err) return res.sendStatus(403)
    req.user = user
    next()
  })
}

// Auth routes
app.post("/api/auth/register", async (req, res) => {
  try {
    const { name, email, password } = req.body

    // Check if email already exists
    const [existingUsers] = await pool.query("SELECT * FROM users WHERE email = ?", [email])

    if (existingUsers.length > 0) {
      return res.status(400).json({ message: "Email already in use" })
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10)

    // Insert user
    const [result] = await pool.query("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", [
      name,
      email,
      hashedPassword,
    ])

    // Generate token
    const token = jwt.sign({ id: result.insertId, email }, process.env.JWT_SECRET || "your_jwt_secret", {
      expiresIn: "30d",
    })

    res.status(201).json({
      id: result.insertId,
      name,
      email,
      token,
    })
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body

    // Find user
    const [users] = await pool.query("SELECT * FROM users WHERE email = ?", [email])

    if (users.length === 0) {
      return res.status(401).json({ message: "Invalid credentials" })
    }

    const user = users[0]

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password)

    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" })
    }

    // Generate token
    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || "your_jwt_secret", {
      expiresIn: "30d",
    })

    res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      token,
    })
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.put("/api/auth/profile", authenticateToken, async (req, res) => {
  try {
    const { name, password } = req.body
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ message: "Name is required" })
    }

    if (password && password.length >= 6) {
      const hashedPassword = await bcrypt.hash(password, 10)
      await pool.query(
        "UPDATE users SET name = ?, password = ? WHERE id = ?",
        [name.trim(), hashedPassword, req.user.id],
      )
    } else {
      await pool.query(
        "UPDATE users SET name = ? WHERE id = ?",
        [name.trim(), req.user.id],
      )
    }

    const [users] = await pool.query(
      "SELECT id, name, email FROM users WHERE id = ?",
      [req.user.id],
    )

    res.json({
      id: users[0].id,
      name: users[0].name,
      email: users[0].email,
    })
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

// Transaction routes
app.get("/api/transactions", authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon 
       FROM transactions t 
       LEFT JOIN categories c ON t.category_id = c.id 
       WHERE t.user_id = ? 
       ORDER BY t.date DESC, t.id DESC`,
      [req.user.id],
    )

    res.json(rows)
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.post("/api/transactions", authenticateToken, async (req, res) => {
  try {
    const { title, amount, date, type, category_id, note } = req.body

    const [result] = await pool.query(
      `INSERT INTO transactions (user_id, title, amount, date, type, category_id, note) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.user.id, title, amount, date, type, category_id, note],
    )

    const [newTransaction] = await pool.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon 
       FROM transactions t 
       LEFT JOIN categories c ON t.category_id = c.id 
       WHERE t.id = ?`,
      [result.insertId],
    )

    res.status(201).json(newTransaction[0])
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.put("/api/transactions/:id", authenticateToken, async (req, res) => {
  try {
    const { title, amount, date, type, category_id, note } = req.body

    const [transaction] = await pool.query(
      "SELECT * FROM transactions WHERE id = ? AND user_id = ?",
      [req.params.id, req.user.id]
    )

    if (transaction.length === 0) {
      return res.status(404).json({ message: "Transaction not found" })
    }

    await pool.query(
      `UPDATE transactions 
       SET title = ?, amount = ?, date = ?, type = ?, category_id = ?, note = ? 
       WHERE id = ? AND user_id = ?`,
      [title, amount, date, type, category_id, note, req.params.id, req.user.id]
    )

    const [updatedTransaction] = await pool.query(
      `SELECT t.*, c.name as category_name, c.icon as category_icon 
       FROM transactions t 
       LEFT JOIN categories c ON t.category_id = c.id 
       WHERE t.id = ?`,
      [req.params.id]
    )

    res.json(updatedTransaction[0])
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.delete("/api/transactions/:id", authenticateToken, async (req, res) => {
  try {
    const [transaction] = await pool.query("SELECT * FROM transactions WHERE id = ? AND user_id = ?", [
      req.params.id,
      req.user.id,
    ])

    if (transaction.length === 0) {
      return res.status(404).json({ message: "Transaction not found" })
    }

    await pool.query("DELETE FROM transactions WHERE id = ?", [req.params.id])

    res.json({ message: "Transaction deleted" })
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

// Category routes
app.get("/api/categories", authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT * FROM categories ORDER BY name ASC")
    res.json(rows)
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

app.post("/api/categories", authenticateToken, async (req, res) => {
  try {
    const { name, icon, type } = req.body
    if (!name || !type) {
      return res.status(400).json({ message: "Name and type are required" })
    }

    const [result] = await pool.query(
      "INSERT INTO categories (name, icon, type) VALUES (?, ?, ?)",
      [name.trim(), icon || "tag", type],
    )

    const [newCategory] = await pool.query(
      "SELECT * FROM categories WHERE id = ?",
      [result.insertId],
    )

    res.status(201).json(newCategory[0])
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

// Dashboard data
app.get("/api/dashboard", authenticateToken, async (req, res) => {
  try {
    // Get total income
    const [totalIncome] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = "income"',
      [req.user.id],
    )

    // Get total expense
    const [totalExpense] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = "expense"',
      [req.user.id],
    )

    // Get monthly income
    const [monthlyIncome] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = "income" AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())',
      [req.user.id],
    )

    // Get monthly expense
    const [monthlyExpense] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = "expense" AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())',
      [req.user.id],
    )

    // Get category expense breakdown for current month
    const [categoryExpenses] = await pool.query(
      `SELECT c.id, c.name, c.icon, COALESCE(SUM(t.amount), 0) as total
       FROM transactions t
       JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = ? AND t.type = 'expense'
         AND MONTH(t.date) = MONTH(CURRENT_DATE())
         AND YEAR(t.date) = YEAR(CURRENT_DATE())
       GROUP BY c.id, c.name, c.icon
       ORDER BY total DESC`,
      [req.user.id],
    )

    const totInc = parseFloat(totalIncome[0].total) || 0
    const totExp = parseFloat(totalExpense[0].total) || 0
    const mInc = parseFloat(monthlyIncome[0].total) || 0
    const mExp = parseFloat(monthlyExpense[0].total) || 0

    res.json({
      totalIncome: totInc,
      totalExpense: totExp,
      balance: totInc - totExp,
      monthlyIncome: mInc,
      monthlyExpense: mExp,
      categoryExpenses: categoryExpenses.map((c) => ({
        id: c.id,
        name: c.name,
        icon: c.icon,
        total: parseFloat(c.total) || 0,
      })),
    })
  } catch (error) {
    console.error(error)
    res.status(500).json({ message: "Server error" })
  }
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
})

