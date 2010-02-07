module HasImageTitleHelper
  
  def image_title(image, text, height=nil)
    styles = { 'background-image' => "url(#{image})", 'height' => height ? "#{height}px" : nil }
    content_tag(:h1, text, :class => "is_image", :style => styles.map{|s| "#{s[0]}:#{s[1]};" if s[1] })
  end
  
  def image_title_for(record)
    title = eval("record.#{record.class.options[:field_name]}")
    if record.has_image?
      image_title("/images/titles/#{record.title_url}", title, record.image_title.height)
    else
      styles = { 'color' => record.class.options[:color], 'font-size' => record.class.options[:size] }
      content_tag(:h1, text, :style => styles.map{|s| "#{s[0]}:#{s[1]};" if s[1] })
    end
  end
    
end