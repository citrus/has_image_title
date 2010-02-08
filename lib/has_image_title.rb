#require 'image_title'

module Citrus
  module HasImageTitle
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    class << self
    
      def default_options
        @options ||= {
          :field_name => 'title',
          :font => "HelveticaNeueLTStd-UltLt.otf",
          :font_path => "#{RAILS_ROOT}/fonts",
          :size => 72,
          :width => 840,
          :height => nil,
          :background_color => '#f9f9f9',
          :background_alpha => '00',
          :color => '#e04e10',
          :weight => 400,
          :kerning => -2,
          :destination => "#{RAILS_ROOT}/public/images/titles",
          :command_path => '',
          :log_command => true,
          :debug => true
        }
      end
          
      def logger
        ActiveRecord::Base.logger
      end
  
    end  
   
    module ClassMethods
      
      def has_image_title(options={})
        include InstanceMethods
        
        self.set_options(Citrus::HasImageTitle.default_options.merge(options))
        
        has_one :image_title, :as => :imagable, :dependent => :destroy
        after_save :generate_image_title
      end
      
      def set_options(options={})
        @options = options
      end     
      
      def options
        @options
      end
       
    end
   
    module InstanceMethods

      def has_image?
        self.image_title != nil
      end

      def title_url
        self.image_title.file_name
      end
      
      def generate_image_title

        txt = eval("self.#{self.class.options[:field_name]}")        
        @title = self.image_title || ImageTitle.new(:imagable => self)
        @title.say txt, self.class.options
        
        self.image_title = @title
        
      end
      
      def options
        self.class.options
      end
      
    end
    
    
  end
end

ActiveRecord::Base.send(:include, Citrus::HasImageTitle)
