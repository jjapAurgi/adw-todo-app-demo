import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import App from '../App'
import { fetchTasks, createTask, updateTask } from '../services/api'

// Mock del servicio API
vi.mock('../services/api', () => ({
  fetchTasks: vi.fn().mockResolvedValue([]),
  createTask: vi.fn(),
  updateTask: vi.fn().mockResolvedValue({}),
  deleteTask: vi.fn(),
  reorderTasks: vi.fn().mockResolvedValue([])
}))

test('renders Todo List heading', () => {
  render(<App />)
  const heading = screen.getByRole('heading', { name: /todo list/i })
  expect(heading).toBeInTheDocument()
})

test('renders task form', () => {
  render(<App />)
  expect(screen.getByPlaceholderText(/nueva tarea/i)).toBeInTheDocument()
})

test('renders task list', () => {
  render(<App />)
  expect(screen.getByText(/no hay tareas/i)).toBeInTheDocument()
})

test('toggle calls updateTask with completed: true when task is not completed', async () => {
  fetchTasks.mockResolvedValue([{ id: 1, title: 'Test task', completed: false }])

  render(<App />)
  const checkbox = await screen.findByRole('checkbox')
  fireEvent.click(checkbox)

  await waitFor(() => {
    expect(updateTask).toHaveBeenCalledWith(1, { completed: true })
  })
})

test('toggle calls updateTask with completed: false when task is completed', async () => {
  fetchTasks.mockResolvedValue([{ id: 1, title: 'Test task', completed: true }])

  render(<App />)
  const checkbox = await screen.findByRole('checkbox')
  fireEvent.click(checkbox)

  await waitFor(() => {
    expect(updateTask).toHaveBeenCalledWith(1, { completed: false })
  })
})

test('create task with due date calls createTask with title and date', async () => {
  fetchTasks.mockResolvedValue([])
  createTask.mockResolvedValue({ id: 2, title: 'Dated task', completed: false, due_date: '2026-12-31' })

  render(<App />)

  const titleInput = screen.getByPlaceholderText(/nueva tarea/i)
  const dateInput = document.querySelector('input[type="date"]')

  fireEvent.change(titleInput, { target: { value: 'Dated task' } })
  fireEvent.change(dateInput, { target: { value: '2026-12-31' } })
  fireEvent.submit(screen.getByRole('button', { name: /añadir/i }))

  await waitFor(() => {
    expect(createTask).toHaveBeenCalledWith('Dated task', '2026-12-31')
  })
})
