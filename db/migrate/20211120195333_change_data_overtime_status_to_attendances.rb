class ChangeDataOvertimeStatusToAttendances < ActiveRecord::Migration[5.1]
  def change
    change_column :attendances, :overtime_status, :datetime
  end
end
