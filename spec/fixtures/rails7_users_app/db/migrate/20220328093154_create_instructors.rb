class CreateInstructors < ActiveRecord::Migration[7.0]
  def change
    create_table :instructors do |t|

      t.timestamps
    end
  end
end
