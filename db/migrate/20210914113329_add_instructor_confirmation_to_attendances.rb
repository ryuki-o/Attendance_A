class AddInstructorConfirmationToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :instructor_confirmation, :integer
  end
end
