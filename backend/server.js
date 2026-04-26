const express = require('express')
const Database = require('better-sqlite3')
const cors = require('cors')

const app = express()
const db = new Database('/data/todos.db')

app.use(cors())
app.use(express.json())

// Init table
db.exec(`
  CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    text TEXT NOT NULL,
    completed INTEGER NOT NULL DEFAULT 0
  )
`)

// GET all todos
app.get('/api/todos', (req, res) => {
  const todos = db.prepare('SELECT * FROM todos ORDER BY id ASC').all()
  res.json(todos.map(t => ({ ...t, completed: t.completed === 1 })))
})

// POST new todo
app.post('/api/todos', (req, res) => {
  const { text } = req.body
  if (!text || !text.trim()) {
    return res.status(400).json({ error: 'text is required' })
  }
  const result = db.prepare('INSERT INTO todos (text) VALUES (?)').run(text.trim())
  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(result.lastInsertRowid)
  res.status(201).json({ ...todo, completed: todo.completed === 1 })
})

// PATCH toggle completed
app.patch('/api/todos/:id', (req, res) => {
  const { id } = req.params
  const { completed } = req.body
  db.prepare('UPDATE todos SET completed = ? WHERE id = ?').run(completed ? 1 : 0, id)
  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(id)
  if (!todo) return res.status(404).json({ error: 'not found' })
  res.json({ ...todo, completed: todo.completed === 1 })
})

// DELETE a todo
app.delete('/api/todos/:id', (req, res) => {
  const { id } = req.params
  db.prepare('DELETE FROM todos WHERE id = ?').run(id)
  res.status(204).end()
})

const PORT = process.env.PORT || 3001
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`))
