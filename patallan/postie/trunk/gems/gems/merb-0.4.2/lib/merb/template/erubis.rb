module Merb # :nodoc:
  module Template # :nodoc:

    class ErubisViewContext < ViewContext
      include ::Merb::ErubisCaptureMixin
      
      def partial(template, opts={})

        unless @_template_format
          @web_controller.choose_template_format(Merb.available_mime_types, {})
        end

        template = @web_controller._cached_partials["#{template}.#{@_template_format}"] ||=
          @web_controller.send(:find_partial, template)

        template_method = template.gsub(/[^\.a-zA-Z0-9]/, "__").gsub(/\./, "_")

        unless self.respond_to?(template_method)
          raise Merb::ControllerExceptions::TemplateNotFound, "No template matched at #{template}"          
        end

        if with = opts.delete(:with)
          as = opts.delete(:as) || template.match(/(.*\/_)([^\.]*)/)[2]
          @_merb_partial_locals = opts        
          sent_template = [with].flatten.map do |temp|
            @_merb_partial_locals[as.to_sym] = temp
            send(template_method)
          end.join
        else
          @_merb_partial_locals = opts        
          sent_template = send(template_method)
        end

        return sent_template if sent_template

      end      
    end
    
    # Module to allow you to use Embedded Ruby templates through Erubis["http://www.kuwata-lab.com/erubis/"].
    # Your template must end in .herb (HTML and ERb), .jerb (JavaScript ERb), .erb (Embedded Ruby), or .rhtml (Ruby HTML) for Merb to use it.
    module Erubis
      class << self
        
        @@erbs = {}
        @@mtimes = {}
        
        def exempt_from_layout? # :nodoc:
          false    
        end
       
        # Main method to compile the ERb template.
        # 
        # In the case of ERb/Erubis, it first checks the template cache for precompiled
        # templates.  If no precompiled version is found, then it compiles the template
        # by calling <tt>new_eruby_obj</tt>, which will compile the template and return an Erubis
        # object holding the parsed template.
        def transform(options = {})
          opts, text, file, view_context = options.values_at(:opts, :text, :file, :view_context)
          eruby = text ? ::Erubis::MEruby.new(text) : new_eruby_obj(file)
          eruby.evaluate(view_context)
        end
        
        def view_context_klass
          ErubisViewContext
        end
        
        # Creates a new Erubis object to parse the template given in +path+.
        def new_eruby_obj(path)
          if @@erbs[path] && MERB_ENV == 'production' 
            return @@erbs[path]
          else  
            begin
              eruby = ::Erubis::MEruby.new(IO.read(path))
              eruby.init_evaluator :filename => path
              if cache_template?(path)
                @@erbs[path], @@mtimes[path] = eruby, Time.now
              end  
              eruby
            rescue Errno::ENOENT
              raise "No template found at path: #{path}"
            end
          end  
        end
        
        private
          def cache_template?(path)
            return false unless ::Merb::Server.config[:cache_templates]
            return true unless @@erbs[path]
            @@mtimes[path] < File.mtime(path) ||
              (File.symlink?(path) && (@@mtimes[path] < File.lstat(path).mtime))
          end
        
      end
    end
  
  end
   
end