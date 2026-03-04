# == Schema Information
#
# Table name: tasks
#
#  id         :bigint           not null, primary key
#  completed  :boolean          default(FALSE), not null
#  due_date   :date
#  position   :integer          not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Task < ApplicationRecord
  default_scope { order(:position) }

  validates :title, presence: true
  validates :title, length: { maximum: 200 }
  validates :due_date, comparison: { greater_than_or_equal_to: -> { Date.today } }, allow_nil: true, on: :create

  before_create :set_default_position

  private

  def set_default_position
    self.position = (Task.unscoped.maximum(:position) || -1) + 1
  end
end
