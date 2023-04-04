class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.string :url, null: false
      t.string :state, null: false, default: "pending"
      t.string :title
      t.string :description
      t.string :image_url

      t.timestamps
    end
  end
end
