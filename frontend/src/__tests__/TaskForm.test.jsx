import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import TaskForm from '../components/TaskForm'

test('renders input and button', () => {
  render(<TaskForm onTaskCreated={() => {}} />)
  expect(screen.getByPlaceholderText(/nueva tarea/i)).toBeInTheDocument()
  expect(screen.getByRole('button', { name: /añadir/i })).toBeInTheDocument()
})

test('renders date input', () => {
  render(<TaskForm onTaskCreated={() => {}} />)
  const dateInput = document.querySelector('input[type="date"]')
  expect(dateInput).toBeInTheDocument()
})

test('calls onTaskCreated when form is submitted', async () => {
  const mockCreate = vi.fn().mockResolvedValue()
  render(<TaskForm onTaskCreated={mockCreate} />)

  const input = screen.getByPlaceholderText(/nueva tarea/i)
  fireEvent.change(input, { target: { value: 'Test task' } })
  fireEvent.submit(screen.getByRole('button'))

  await waitFor(() => {
    expect(mockCreate).toHaveBeenCalledWith('Test task', null)
  })
})

test('sends task with due date', async () => {
  const mockCreate = vi.fn().mockResolvedValue()
  render(<TaskForm onTaskCreated={mockCreate} />)

  const input = screen.getByPlaceholderText(/nueva tarea/i)
  const dateInput = document.querySelector('input[type="date"]')
  fireEvent.change(input, { target: { value: 'Task with date' } })
  fireEvent.change(dateInput, { target: { value: '2026-12-31' } })
  fireEvent.submit(screen.getByRole('button'))

  await waitFor(() => {
    expect(mockCreate).toHaveBeenCalledWith('Task with date', '2026-12-31')
  })
})

test('sends task without due date', async () => {
  const mockCreate = vi.fn().mockResolvedValue()
  render(<TaskForm onTaskCreated={mockCreate} />)

  const input = screen.getByPlaceholderText(/nueva tarea/i)
  fireEvent.change(input, { target: { value: 'Task no date' } })
  fireEvent.submit(screen.getByRole('button'))

  await waitFor(() => {
    expect(mockCreate).toHaveBeenCalledWith('Task no date', null)
  })
})

test('clears input after submission', async () => {
  const mockCreate = vi.fn().mockResolvedValue()
  render(<TaskForm onTaskCreated={mockCreate} />)

  const input = screen.getByPlaceholderText(/nueva tarea/i)
  const dateInput = document.querySelector('input[type="date"]')
  fireEvent.change(input, { target: { value: 'Test task' } })
  fireEvent.change(dateInput, { target: { value: '2026-12-31' } })
  fireEvent.submit(screen.getByRole('button'))

  await waitFor(() => {
    expect(input.value).toBe('')
    expect(dateInput.value).toBe('')
  })
})
