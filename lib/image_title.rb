require 'fileutils'

class ImageTitle < ActiveRecord::Base
  
  belongs_to :imagable, :polymorphic => true

  before_destroy :delete_current_image
 
  def say(text="",options={})
    @options = options    
 
    @text = text.gsub(/'/, "\`")
     
    logger.info "[has_image_title] text will be: #{@text}"
     
    @options[:command_path] = clean_path( @options[:command_path] )
    @options[:font] = clean_path( @options[:font] )
    @options[:font_path] = clean_path( @options[:font_path] )
    @options[:destination] = clean_path( @options[:destination] )

    delete_current_image if self.file_name
    
    @filename = make_unique_filename(@text)
  
    logger.info "[has_image_title] generating image title.."
    logger.info "[has_image_title] #{title_command}" if @options[:log_command]
    
    `#{title_command}` if @options
    
    info = `identify -format "%b,%w,%h" #{@options[:destination]}/#{@filename}`.split(",")
    
    self.file_name = @filename
    self.file_size = info[0]
    self.width = info[1]
    self.height = info[2]
    self.save
  end
  
  #def options
  #  @options
  #end
  
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
  
  def delete_current_image
    @options ||= self.imagable.options
    return false unless @options    
    path = "#{@options[:destination]}/#{self.file_name}"
    File.delete(path) if !path.empty? && File.exists?(path)
  end  
  
  def clean_path(str="")
    str.to_s.gsub(/\/$/, "")
  end
       
  def title_command
    "#{@options[:command_path]}/convert \
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