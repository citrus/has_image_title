require 'fileutils'

class ImageTitle < ActiveRecord::Base
  
  belongs_to :imagable, :polymorphic => true

  before_destroy :delete_current_image
 
  def say(text="",options={})    
  
    @options = Citrus::HasImageTitle.default_options.merge(options)
 
    @text = text.gsub(/'/, "\`")

    @options[:command_path] = clean_path( @options[:command_path] )
    @options[:font] = clean_path( @options[:font] )
    @options[:font_path] = clean_path( @options[:font_path] )
    @options[:destination] = clean_path( @options[:destination] )

    setup_destination_folder
    
    if has_current_file?
      backup_current_image
      delete_current_image
    end
      
    @filename = make_unique_filename(@text)
  
    logger.info "[has_image_title] generating image title..."

    run('convert', title_command_string)
    info = run('identify', info_command_string)
    
    
    logger.info "[has_image_title] has info? #{!info.empty?}, file info: #{info.inspect}, file exists? #{File.exists?(new_image_path)}" if @options[:debug]
    
    if info.empty? || !File.exists?(new_image_path)
      msg = "Image generation failed - using backup image if it exists. Please make sure ImageMagick is installed properly."
      err = "[has_image_title] #{msg}"
      logger.error err
      restore_backup_image if has_current_file?
      self.errors.add_to_base(msg)
    else
      file_info = info.split(",")
      self.file_name = @filename
      self.file_size = file_info[0].to_i
      self.width = file_info[1].to_i
      self.height = file_info[2].to_i
      self.save
    end
    self
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
  
  
  def setup_destination_folder
    FileUtils.mkdir "#{@options[:destination]}" unless File.directory?("#{@options[:destination]}")
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
    path = current_image_path
    new_path = "#{@options[:destination]}/backups/#{self.file_name}"
    FileUtils.cp(path, new_path) if !path.empty? && File.exists?(path)
  end
  
  def restore_backup_image
    @options ||= self.imagable.options
    return false unless @options || !has_current_file?
    path = "#{@options[:destination]}/backups/#{self.file_name}"
    new_path = current_image_path
    FileUtils.cp(path, new_path) if !path.empty? && File.exists?(path)
  end
  
  def delete_current_image
    @options ||= self.imagable.options
    return false unless @options    
    path = current_image_path
    File.delete(path) if !path.empty? && File.exists?(path)
  end
  
  
  def current_image_path
    "#{@options[:destination]}/#{self.file_name}"
  end
  
  def new_image_path
    "#{@options[:destination]}/#{@filename}"
  end
  
  def has_current_file?
    return self.file_name && (!self.file_name.nil? || self.file_name.empty?)
  end
  
  def clean_path(str="")
    str.to_s.gsub(/\/$/, "")
  end
    
  def info_command_string
    "-format '%b,%w,%h' #{new_image_path}"
  end
       
  def title_command_string
    "-trim \
    -antialias \
    -background '#{@options[:background_color]}#{@options[:background_alpha]}' \
    -fill '#{@options[:color]}' \
    -font #{@options[:font_path]}/#{@options[:font]} \
    -pointsize #{@options[:size]} \
    -size #{@options[:width]}x#{@options[:height]} \
    -weight #{@options[:weight]} \
    -kerning #{@options[:kerning]} \
    caption:'#{@text}' \
    #{new_image_path}"
  end  
      
  def path_for_command command
    path = [@options[:command_path], command].compact
    File.join(*path)
  end
  
  def run cmd, params
    command = %Q<#{%Q[#{path_for_command(cmd)} #{params.to_s.gsub(/\\|\n|\r/, '')}].gsub(/\s+/, " ")}>
    logger.info command if @options[:log_command]
    `#{command}`
  end  
        
  def logger
    Citrus::HasImageTitle::logger
  end
  
end
