class AddChangeToAttendance < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change, :integer
  end
end
