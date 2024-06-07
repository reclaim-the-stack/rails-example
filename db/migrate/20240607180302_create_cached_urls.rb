class CreateCachedUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :cached_urls do |t|
      t.text :url, null: false
      t.string :tags, array: true, default: []
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :cached_urls, :url, unique: true
  end
end
