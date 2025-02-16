class Books < ActiveRecord::Migration[Rails.version.split(".")[0..1].join(".")]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.timestamps null: false
    end
  end
end
