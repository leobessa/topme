class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.string :url
      t.string :code
    end
    add_index(:urls, :url, :unique => true)
    add_index(:urls, :code, :unique => true)
  end

  def self.down
    drop_table :urls
  end
end
