class HasImageTitleGenerator < Rails::Generator::Base 
  def manifest 
    record do |m| 
      m.migration_template 'migration.rb', 'db/migrate'
    end 
  end
  
  def file_name
    "has_image_title_migration"
  end
end
