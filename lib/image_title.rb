require 'fileutils'

class ImageTitle < ActiveRecord::Base
  
  belongs_to :imagable, :polymorphic => true

  before_destroy :delete_current_image
 
  def say(text="",options={})    
    @options = options    
 
    @text = text.gsub(/'/, "\`")

    @options[:command_path] = clean_path( @options[:command_path] )
    @options[:font] = clean_path( @options[:font] )
    @options[:font_path] = clean_path( @options[:font_path] )
    @options[:destination] = clean_path( @options[:destination] )

    setup_title_folder unless has_title_folder?

    if has_current_file?
      backup_current_image
      delete_current_image
    end
      
    @filename = make_unique_filename(@text)
  
    logger.info "[has_image_title] generating image title.."
    logger.info "[has_image_title] #{title_command}" if @options[:log_command]
    
    `#{title_command}` if @options
    
    logger.info "[has_image_title] identify -format \"%b,%w,%h\" #{@options[:destination]}/#{@filename}" if @options[:log_command]
    info = `identify -format "%b,%w,%h" #{@options[:destination]}/#{@filename}`.split(",")
    
    logger.info "[has_image_title] #{info.inspect}"
    
    if info.empty? || !File.exists?("#{@options[:destination]}/#{@filename}")
      msg = "Image generation failed - using backup image if it exists. Please make sure ImageMagick is installed properly."
      err = "[has_image_title] #{msg}"
      logger.error err
      restore_backup_image if has_current_file?
      self.errors.add_to_base(msg)
    else  
      self.file_name = @filename
      self.file_size = info[0].to_i
      self.width = info[1].to_i
      self.height = info[2].to_i
      self.save
    end
  end
  
  def make_unique_filename(str="")
    count = 2
    filename = fileize_string(str)
    exists = File.exists?("#{@options[:destination]}/#{filename})")
    while exists do
      dupe_filename = "#{filename}_#{count}"
      exists = File.exists?("#{@options[:destination]}/#{dupe_filename})")
      count += 1
    end
    filename = dupe_filename || filename
  end
  
  def fileize_string(str="")
    fle = str.to_s.downcase.gsub(/\s/, '_').gsub(/[^a-z0-9\_]/, '').gsub(/[\_]+/, '_').gsub(/\_$/, '')
    fle = (0..25).map{ ('a'..'z').to_a[rand(26)] }.join if fle.empty?
    "#{fle}.png"
  end
  
  def has_title_folder?
    @options ||= self.imagable.options
    return false unless @options
    File.directory?("#{@options[:destination]}")
  end
  
  def setup_title_folder
    @options ||= self.imagable.options
    return false unless @options
    FileUtils.mkdir "#{@options[:destination]}" unless has_title_folder?
  end
  
  def setup_backup_folder
    @options ||= self.imagable.options
    return false unless @options
    FileUtils.mkdir "#{@options[:destination]}/backups/" unless File.directory?("#{@options[:destination]}/backups/")
  end
  
  def backup_current_image
    @options ||= self.imagable.options
    return false unless @options || !has_current_file?
    setup_backup_folder
    path = "#{@options[:destination]}/#{self.file_name}"
    new_path = "#{@options[:destination]}/backups/#{self.file_name}"
    FileUtils.cp(path, new_path) if !path.empty? && File.exists?(path)
  end
  
  def restore_backup_image
    @options ||= self.imagable.options
    return false unless @options || !has_current_file?
    path = "#{@options[:destination]}/backups/#{self.file_name}"
    new_path = "#{@options[:destination]}/#{self.file_name}"
    FileUtils.cp(path, new_path) if !path.empty? && File.exists?(path)
  end
  
  def delete_current_image
    @options ||= self.imagable.options
    return false unless @options    
    path = "#{@options[:destination]}/#{self.file_name}"
    File.delete(path) if !path.empty? && File.exists?(path)
  end
  
  def has_current_file?
    return self.file_name && (!self.file_name.nil? || self.file_name.empty?)
  end
  
  def clean_path(str="")
    str.to_s.gsub(/\/$/, "")
  end
  
  def convert_command
    @options[:command_path] && !@options[:command_path].empty? ? "#{@options[:command_path]}/convert" : "convert"
  end
       
  def title_command
    "#{convert_command} \
    -trim \
    -antialias \
    -background '#{@options[:background_color]}#{@options[:background_alpha]}' \
    -fill '#{@options[:color]}' \
    -font #{@options[:font_path]}/#{@options[:font]} \
    -pointsize #{@options[:size]} \
    -size #{@options[:width]}x#{@options[:height]} \
    -weight #{@options[:weight]} \
    -kerning #{@options[:kerning]} \
    caption:'#{@text}' \
    #{@options[:destination]}/#{@filename}".gsub(/\\/, '').gsub(/\s{1,}/, ' ')
  end
  
        
  def logger
    Citrus::HasImageTitle::logger
  end
  
end