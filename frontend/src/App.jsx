import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [todos, setTodos] = useState([])
  const [input, setInput] = useState('')
  const [filter, setFilter] = useState('all')

  useEffect(() => {
    fetch('/api/todos')
      .then(r => r.json())
      .then(setTodos)
  }, [])

  const addTodo = () => {
    const trimmed = input.trim()
    if (!trimmed) return
    fetch('/api/todos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: trimmed }),
    })
      .then(r => r.json())
      .then(todo => setTodos(prev => [...prev, todo]))
    setInput('')
  }

  const toggleTodo = (id, completed) => {
    fetch(`/api/todos/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ completed: !completed }),
    })
      .then(r => r.json())
      .then(updated => setTodos(prev => prev.map(t => t.id === id ? updated : t)))
  }

  const deleteTodo = (id) => {
    fetch(`/api/todos/${id}`, { method: 'DELETE' })
      .then(() => setTodos(prev => prev.filter(t => t.id !== id)))
  }

  const clearCompleted = () => {
    const completed = todos.filter(t => t.completed)
    Promise.all(completed.map(t => fetch(`/api/todos/${t.id}`, { method: 'DELETE' })))
      .then(() => setTodos(prev => prev.filter(t => !t.completed)))
  }

  const filtered = todos.filter(t => {
    if (filter === 'active') return !t.completed
    if (filter === 'completed') return t.completed
    return true
  })

  const activeCount = todos.filter(t => !t.completed).length

  return (
    <div className="app">
      <h1>Todo</h1>

      <div className="input-row">
        <input
          type="text"
          placeholder="What needs to be done?"
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && addTodo()}
        />
        <button className="add-btn" onClick={addTodo}>Add</button>
      </div>

      <ul className="todo-list">
        {filtered.map(todo => (
          <li key={todo.id} className={todo.completed ? 'completed' : ''}>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo(todo.id, todo.completed)}
            />
            <span>{todo.text}</span>
            <button className="delete-btn" onClick={() => deleteTodo(todo.id)}>✕</button>
          </li>
        ))}
        {filtered.length === 0 && (
          <li className="empty">No todos here.</li>
        )}
      </ul>

      <div className="footer">
        <span>{activeCount} item{activeCount !== 1 ? 's' : ''} left</span>
        <div className="filters">
          {['all', 'active', 'completed'].map(f => (
            <button
              key={f}
              className={filter === f ? 'active' : ''}
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
        <button className="clear-btn" onClick={clearCompleted}>Clear completed</button>
      </div>
    </div>
  )
}

export default App
