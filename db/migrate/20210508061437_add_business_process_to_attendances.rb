class AddBusinessProcessToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :business_process, :string
  end
end
