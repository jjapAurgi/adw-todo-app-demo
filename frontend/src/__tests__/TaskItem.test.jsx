import { render, screen, fireEvent } from '@testing-library/react'
import TaskItem from '../components/TaskItem'

vi.mock('@dnd-kit/sortable', () => ({
  useSortable: () => ({
    attributes: {},
    listeners: {},
    setNodeRef: () => {},
    transform: null,
    transition: null,
    isDragging: false
  })
}))

vi.mock('@dnd-kit/utilities', () => ({
  CSS: {
    Transform: {
      toString: () => undefined
    }
  }
}))

const mockTask = {
  id: 1,
  title: 'Test task',
  completed: false
}

test('renders task with title', () => {
  render(<TaskItem task={mockTask} onToggle={() => {}} onDelete={() => {}} />)
  expect(screen.getByText('Test task')).toBeInTheDocument()
})

test('shows checked checkbox when task is completed', () => {
  const completedTask = { ...mockTask, completed: true }
  render(<TaskItem task={completedTask} onToggle={() => {}} onDelete={() => {}} />)

  const checkbox = screen.getByRole('checkbox')
  expect(checkbox).toBeChecked()
})

test('calls onToggle when checkbox is clicked', () => {
  const mockToggle = vi.fn()
  render(<TaskItem task={mockTask} onToggle={mockToggle} onDelete={() => {}} />)

  fireEvent.click(screen.getByRole('checkbox'))
  expect(mockToggle).toHaveBeenCalledWith(1)
})

test('calls onDelete when delete button is clicked', () => {
  const mockDelete = vi.fn()
  render(<TaskItem task={mockTask} onToggle={() => {}} onDelete={mockDelete} />)

  fireEvent.click(screen.getByRole('button', { name: /eliminar/i }))
  expect(mockDelete).toHaveBeenCalledWith(1)
})

test('renders drag handle', () => {
  render(<TaskItem task={mockTask} onToggle={() => {}} onDelete={() => {}} />)
  const handle = document.querySelector('.drag-handle')
  expect(handle).toBeInTheDocument()
})

test('shows due date when it exists', () => {
  const taskWithDate = { ...mockTask, due_date: '2026-12-25' }
  render(<TaskItem task={taskWithDate} onToggle={() => {}} onDelete={() => {}} />)
  expect(screen.getByText(/25/)).toBeInTheDocument()
  expect(screen.getByText(/dic/i)).toBeInTheDocument()
})

test('does not show due date when it does not exist', () => {
  render(<TaskItem task={mockTask} onToggle={() => {}} onDelete={() => {}} />)
  const dueDate = document.querySelector('.due-date')
  expect(dueDate).not.toBeInTheDocument()
})

test('shows overdue indicator for past due date on incomplete task', () => {
  const overdueTask = { ...mockTask, due_date: '2020-01-01', completed: false }
  render(<TaskItem task={overdueTask} onToggle={() => {}} onDelete={() => {}} />)
  const dueDate = document.querySelector('.due-date--overdue')
  expect(dueDate).toBeInTheDocument()
})

test('shows soon indicator for tomorrow due date on incomplete task', () => {
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)
  const tomorrowStr = tomorrow.toISOString().split('T')[0]
  const soonTask = { ...mockTask, due_date: tomorrowStr, completed: false }
  render(<TaskItem task={soonTask} onToggle={() => {}} onDelete={() => {}} />)
  const dueDate = document.querySelector('.due-date--soon')
  expect(dueDate).toBeInTheDocument()
})
