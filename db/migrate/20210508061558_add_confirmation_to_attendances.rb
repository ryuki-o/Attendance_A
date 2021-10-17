class AddConfirmationToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :confirmation, :string
  end
end
