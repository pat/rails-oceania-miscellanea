#require 'hpricot'

class Hash
 	  
  class << self
      # Converts valid XML into a Ruby Hash structure.
      # <tt>xml</tt>:: A string representation of valid XML
      # 
      # == Typecasting
      # Typecasting is performed on elements that have a "<tt>type</tt>" attribute of
      # <tt>integer</tt>:: 
      # <tt>boolean</tt>:: anything other than "true" evaluates to false
      # <tt>datetime</tt>:: Returns a Time object.  See +Time+ documentation for valid Time strings
      # <tt>date</tt>:: Returns a Date object.  See +Date+ documentation for valid Date strings 
      # 
      # Keys are automatically converted to +snake_case+
      #
      # == Caveats
      # * Mixed content tags are assumed to be text and any xml tags are kept as a String
      # * Any attributes other than type on a node containing a text node will be discarded
      #
      # == Examples
      #
      # === Standard 
      # <user gender='m'>
      #   <age type='integer'>35</age>
      #   <name>Home Simpson</name>
      #   <dob type='date'>1988-01-01</dob>
      #   <joined-at type='datetime'>2000-04-28 23:01</joined-at>
      #   <is-cool type='boolean'>true</is-cool>
      # </user>
      #
      # evaluates to 
      # 
      # { "user" => 
      #         { "gender"    => "m",
      #           "age"       => 35,
      #           "name"      => "Home Simpson",
      #           "dob"       => DateObject( 1998-01-01 ),
      #           "joined_at" => TimeObject( 2000-04-28 23:01),
      #           "is_cool"   => true 
      #         }
      #     }
      #
      # === Mixed Content
      # <story>
      #   A Quick <em>brown</em> Fox
      # </story>
      #
      # evaluates to
      # { "story" => "A Quick <em>brown</em> Fox" }
      # 
      # === Attributes other than type on a node containing text
      # <story is-good='fasle'>
      #   A Quick <em>brown</em> Fox
      # </story>
      #
      # evaluates to
      # { "story" => "A Quick <em>brown</em> Fox" }
      #
      # <bicep unit='inches' type='integer'>60</bicep>
      #
      # evaluates with a typecast to an integer.  But ignores the unit attribute
      # { "bicep" => 60 }
      
      def from_xml( xml )
        ToHashParser.from_xml(xml)  
      end
  end
  
  # convert this hash into a Mash for string or symbol key access
  def to_mash
 	  hash = Mash.new(self) 
 	  hash.default = self.default 
 	  hash
 	end
 	
 	# convert this hash to a query string param
 	#   {:name => "Bob", :address => {:street => '111 Ruby Ave.', :city => 'Ruby Central', :phones => ['111-111-1111', '222-222-2222']}}
  #   #=> "name=Bob&address[city]=Ruby Central&address[phones]=111-111-1111222-222-2222&address[street]=111 Ruby Ave."
  def to_params
    result = ''
    stack = []

    each do |key, value|
      Hash === value ? stack << [key, value] : result <<  "#{key}=#{value}&"
    end

    stack.each do |parent, hash|
      hash.each do |key, value|
        if Hash === value
          stack << ["#{parent}[#{key}]", value]
        else
          result << "#{parent}[#{key}]=#{value}&"
        end
      end
    end
    result.chop
  end
  
  # lets through the keys in the argument
  #   $ {:one => 1, :two => 2, :three => 3}.pass(:one)
  #   #=> {:one=>1}
  def pass(*allowed) 
    self.reject { |k,v| ! allowed.include?(k) } 
  end
  alias only pass
  
  # blocks the keys in the arguments
  #   $ {:one => 1, :two => 2, :three => 3}.block(:one)
  #   #=> {:two=>2, :three=>3}
  def block(*rejected) 
    self.reject { |k,v| rejected.include?(k) } 
  end
  alias except block

  # Converts the hash into xml attributes
  #   { :one => "ONE", "two"=>"TWO" }.to_xml_attributes
  #   #=> 'one="ONE" two="TWO"'
  def to_xml_attributes
    map do |k,v|
      "#{k.to_s.camelize.sub(/^(.{1,1})/){|m| m.downcase}}=\"#{v}\""
    end.join(" ")
  end
  
  alias_method :to_html_attributes, :to_xml_attributes
 
  # Adds the given class symbol or string to the hash in the
  # :class key.  This will add a html class if there are already any existing
  # or create the key and add this as the first class
  #
  # Example
  #   @hash[:class] #=> nil
  #   @hash.add_html_class!(:selected) #=> @hash[:class] == "selected"
  #
  #   @hash.add_html_class!("class1 class2") #=> @hash[:class] == "selected class1 class2"
  def add_html_class!(html_class)
    if self[:class]
      self[:class] = "#{self[:class]} #{html_class}"
    else
      self[:class] = html_class.to_s
    end
  end
  
  # Destructively convert all keys to symbols recursively.
  def symbolize_keys!
    keys.each do |key|
      unless key.is_a?(Symbol)
        self[key.to_sym] = self[key]
        delete(key)
      end
      if Hash === (sub = self[key.to_sym])
        sub.symbolize_keys!
      end  
    end
    self
  end
  
  # Converts every key to an uppercase string (non-recursive.)
  #   {:name => "Bob", "age" => 12, "nick" => "Bobinator"}.environmentize_keys!
  #   #=> {"NAME"=>"Bob", "NICK"=>"Bobinator", "AGE"=>12}
  def environmentize_keys!
    self.each do |key, value|
      self[key.to_s.upcase] = delete(key)
    end
    self
  end
    
 def method_missing(m,*a) #:nodoc:
   m.to_s =~ /=$/ ? self[$`]=a[0] : a==[] ? self[m] : raise(NoMethodError,"#{m}")
 end
  
  def respond_to?(method, include_private=false)
    return true if keys.include?(method)
    super(method, include_private)
  end
  
end  

require 'rexml/parsers/streamparser'
require 'rexml/parsers/baseparser'
require 'rexml/light/node'

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the underlying
# parser
class REXMLUtilityNode # :nodoc:
  attr_accessor :name, :attributes, :children
  
  def initialize(name, attributes = {})
    @name       = name.tr("-", "_")
    @attributes = undasherize_keys(attributes)
    @children   = []
    @text       = false
  end
  
  def add_node(node)
    @text = true if node.is_a? String
    @children << node
  end
  
  def to_hash
    if @text
      return { name => typecast_value( translate_xml_entities( inner_html ) ) }
    else
      #change repeating groups into an array
      # group by the first key of each element of the array to find repeating groups
      groups = @children.group_by{ |c| c.name }

      hash = {}  
      groups.each do |key, values|
        if values.size == 1
          hash.merge!( values.first ) 
        else
          hash.merge!( key => values.map{ |element| element.to_hash[key] } )
        end
      end

      # merge the arrays, including attributes
      hash.merge!( attributes ) unless attributes.empty?
      return { name => hash }
    end
  end

  def to_s 
    self.to_html
  end


  def typecast_value(value)
    return value unless attributes["type"] 
    
    case attributes["type"]
      when "integer"  then value.to_i
      when "boolean"  then value.strip == "true"
      when "datetime" then ::Time.parse(value).utc
      when "date"     then ::Date.parse(value)
      else                 value
    end
  end

  def translate_xml_entities(value)
    value.gsub(/&lt;/,   "<").
          gsub(/&gt;/,   ">").
          gsub(/&quot;/, '"').
          gsub(/&apos;/, "'").
          gsub(/&amp;/,  "&")
  end

   def undasherize_keys(params)
     params.keys.each do |key, vvalue|
       params[key.tr("-", "_")] = params.delete(key)
     end
     params 
  end

  def inner_html
    @children.join
  end

  def to_html 
    "<#{name}#{attributes.to_xml_attributes}>#{inner_html}</#{name}>"
  end
end

class ToHashParser # :nodoc:
	def self.from_xml(xml)
		stack = []
		parser = REXML::Parsers::BaseParser.new(xml)
		
		while true
			event = parser.pull
			case event[0]
			when :end_document
				break
			when :end_doctype, :start_doctype
				# do nothing
			when :start_element
			  stack.push REXMLUtilityNode.new(event[1], event[2])
			when :end_element
			  if stack.size > 1
			    temp = stack.pop
			    stack.last.add_node(temp)
			  end
			when :text
			  stack.last.add_node(event[1]) unless event[1].strip.length == 0
			end
		end
		stack.pop.to_hash
	end	
end
