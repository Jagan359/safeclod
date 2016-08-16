class CreateDetails < ActiveRecord::Migration
  def change
    create_table :details do |t|
      t.string :filename
      t.string :s1
      t.string :s2
      t.string :s3
      t.string :status
      t.string :drop
      t.string :box
      t.string :google

      t.timestamps null: false
    end
  end
end
