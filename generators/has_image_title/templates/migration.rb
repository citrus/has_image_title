class HasImageTitleMigration < ActiveRecord::Migration
  def self.up
    create_table :image_titles do |t|
      t.references :imagable, :polymorphic => true
      t.string :file_name
      t.string :file_size
      t.integer :width
      t.integer :height
    end
  end

  def self.down
    drop_table :image_titles
  end
end