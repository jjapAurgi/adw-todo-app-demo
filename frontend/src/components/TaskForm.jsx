import { useState } from 'react'

function TaskForm({ onTaskCreated }) {
  const [title, setTitle] = useState('')
  const [dueDate, setDueDate] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (title.trim()) {
      await onTaskCreated(title, dueDate || null)
      setTitle('')
      setDueDate('')
    }
  }

  return (
    <form onSubmit={handleSubmit} className="task-form">
      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Nueva tarea..."
        className="task-input"
      />
      <input
        type="date"
        value={dueDate}
        onChange={(e) => setDueDate(e.target.value)}
        className="task-date-input"
      />
      <button type="submit" className="btn btn-primary">
        Añadir
      </button>
    </form>
  )
}

export default TaskForm
