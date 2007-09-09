require 'thinking_sphinx/client/filter'

module ThinkingSphinx
  class VersionError < StandardError;  end
  class ResponseError < StandardError; end
  
  # This class was heavily based on the existing Client API by Dmytro Shteflyuk
  # and Alexy Kovyrin. Their code worked fine, I just wanted something a bit
  # more Ruby-ish (ie. lowercase and underscored method names). I also have
  # used a few helper classes, just to neaten things up.
  #
  # I do plan to release this part of the plugin as a standalone library at
  # some point - if you're interested in using it, and are feeling impatient,
  # feel free to hassle me.
  #
  class Client
    Commands = {
      :search  => 0, # SEARCHD_COMMAND_SEARCH
      :excerpt => 1, # SEARCHD_COMMAND_EXCERPT
      :update  => 2  # SEARCHD_COMMAND_UPDATE
    }
    
    Versions = {
      :search  => 0x107, # VER_COMMAND_SEARCH
      :excerpt => 0x100, # VER_COMMAND_EXCERPT
      :update  => 0x100  # VER_COMMAND_UPDATE
    }
    
    Statuses = {
      :ok      => 0, # SEARCHD_OK
      :error   => 1, # SEARCHD_ERROR
      :retry   => 2, # SEARCHD_RETRY
      :warning => 3  # SEARCHD_WARNING
    }
    
    MatchModes = {
      :all      => 0, # SPH_MATCH_ALL
      :any      => 1, # SPH_MATCH_ANY
      :phrase   => 2, # SPH_MATCH_PHRASE
      :boolean  => 3, # SPH_MATCH_BOOLEAN
      :extended => 4  # SPH_MATCH_EXTENDED
    }
    
    SortModes = {
      :relevance     => 0, # SPH_SORT_RELEVANCE
      :attr_desc     => 1, # SPH_SORT_ATTR_DESC
      :attr_asc      => 2, # SPH_SORT_ATTR_ASC
      :time_segments => 3, # SPH_SORT_TIME_SEGMENTS
      :extended      => 4  # SPH_SORT_EXTENDED
    }
    
    AttributeTypes = {
      :integer   => 1, # SPH_ATTR_INTEGER
      :timestamp => 2  # SPH_ATTR_TIMESTAMP
    }
    
    GroupFunctions = {
      :day   => 0, # SPH_GROUPBY_DAY
      :week  => 1, # SPH_GROUPBY_WEEK
      :month => 2, # SPH_GROUPBY_MONTH
      :year  => 3, # SPH_GROUPBY_YEAR
      :attr  => 4  # SPH_GROUPBY_ATTR
    }
    
    attr_accessor :server, :port, :offset, :limit, :max_matches,
      :match_mode, :sort_mode, :sort_by, :weights, :id_range, :filters
    
    # Can instantiate with a specific server and port - otherwise it assumes
    # defaults of localhost and 3312 respectively. All other settings can be
    # accessed and changed via the attribute accessors.
    def initialize(server=nil, port=nil)
      @server = server || "localhost"
      @port   = port   || 3312
      
      # defaults
      @offset         = 0
      @limit          = 20
      @max_matches    = 1000
      @match_mode     = :all
      @sort_mode      = :relevance
      @sort_by        = ''
      @weights        = []
      @id_range       = 0..0xFFFFFFFF
      @filters        = []
      @group_by       = ''
      @group_function = :day
      @group_clause   = '@group desc'
    end
    
    # Query the Sphinx daemon - defaulting to all indexes, but you can specify
    # a specific one if you wish. The search parameter should be a string
    # following Sphinx's expectations.
    def query(search, index = '*')      
      response = Response.new request(:search, query_message(search, index))
      
      result = {
        :matches         => {},
        :fields          => [],
        :attributes      => {},
        :attribute_names => [],
        :words           => {}
      }
      
      result[:fields] = response.next_array
      
      attributes = response.next_int
      for i in 0...attributes
        attribute_name = response.next
        type           = response.next_int
        
        result[:attributes][attribute_name] = type
        result[:attribute_names] = attribute_name
      end
      
      matches = response.next_int
      for i in 0...matches
        doc    = response.next_int
        weight = response.next_int
        
        result[:matches][doc] = {:weight => weight, :index => i, :attributes => {}}
        result[:attribute_names].each do |attr|
          result[:matches][doc][:attributes][attr] = response.next_int
        end
      end
      
      result[:total] = response.next_int
      result[:total_found] = response.next_int
      result[:time] = '%.3f' % (response.next_int / 1000.0)
      
      words = response.next_int
      for i in 0...words
        word = response.next
        docs = response.next_int
        hits = response.next_int
        result[:words][word] = {:docs => docs, :hits => hits}
      end
      
      result
    end
    
    # Grab excerpts from the indexes. As part of the options, you will need to
    # define:
    # * :docs
    # * :words
    #
    # Optional settings include:
    # * :index (defaults to all indexes)
    # * :before_match (defaults to <span class="match">)
    # * :after_match (defaults to </span>)
    # * :chunk_separator (defaults to ' &#8230; ' - which is an HTML ellipsis)
    # * :limit (defaults to 256)
    # * :around (defaults to 5)
    #
    def excerpts(options = {})
      options[:index]           ||= '*'
      options[:before_match]    ||= '<span class="match">'
      options[:after_match]     ||= '</span>'
      options[:chunk_separator] ||= ' &#8230; ' # ellipsis
      options[:limit]           ||= 256
      options[:around]          ||= 5
      
      response = Response.new request(:excerpts, excerpts_message(options))
      
      options[:docs].collect { |doc| response.next }
    end
    
    # Updates are pre-alpha in Sphinx, so I'm not supporting that functionality
    # just yet. This method returns nil.
    def update(index, attributes, values)
      nil
    end
    
    private
    
    # Connects to the Sphinx daemon, and yields a socket to use. The socket is
    # closed at the end of the block.
    def connect(&block)
      socket = TCPSocket.new @server, @port
      
      version = socket.recv(4).unpack('N*').first
      if version < 1
        socket.close
        raise VersionError, "Can only connect to searchd version 1.0 or better, not version #{version}"
      end
      
      socket.send [1].pack('N'), 0
      
      begin
        yield socket
      ensure
        socket.close
      end
    end
    
    # Send a specific message, for a command type (eg, search, excerpts,
    # update), to the Sphinx daemon.
    def request(command, message)
      response = ""
      status   = -1
      version  = 0
      
      connect do |socket|
        socket.send [Commands[command], Versions[command], message.length].pack('nnN') + message, 0
      
        header = socket.recv(8)
        status, version, length = header.unpack('n2N')
        
        while response.length < length
          part = socket.recv(length - response.length)
          response << part if part
        end
      end
      
      raise ResponseError, "No response from searchd (status: #{status}, version: #{version})" if response.empty?
      
      case status
      when Statuses[:ok]
        response
      when Statuses[:warning]
        length = response[0, 4].unpack('N*').first
        puts response[4, length]
        response[4 + length, response.length - 4 - length]
      when Statuses[:error], Statuses[:retry]
        raise ResponseError, "searchd error (status: #{status}): #{response[4, response.length - 4]}"
      else
        raise ResponseError, "Unknown searchd error (status: #{status})"
      end
    end
    
    # Generation of the message to send to Sphinx for a search.
    def query_message(search, index)
      message = Message.new
      
      # Mode, Limits, Sort Mode
      message.append_ints @offset, @limit, MatchModes[@match_mode], SortModes[@sort_mode]
      message.append_string @sort_by
      
      # Query
      message.append_string search
      
      # Weights
      message.append_int @weights.length
      message.append_ints *@weights
      
      # Index
      message.append_string index
      
      # ID Range
      message.append_ints @id_range.first, @id_range.last
      
      # Filters
      message.append_int @filters.length
      @filters.each { |filter| message.append filter.query_message }
      
      # Grouping
      message.append_int GroupFunctions[@group_function]
      message.append_string @group_by
      message.append_int @max_matches
      message.append_string @group_clause
    end
    
    # Generation of the message to send to Sphinx for an excerpts request.
    def excerpts_message(options)
      message = Message.new
      
      message.append [0, 1].pack('N2') # mode = 0, flags = 1
      message.append_string options[:index]
      message.append_string options[:words]
      
      # options
      message.append_string options[:before_match]
      message.append_string options[:after_match]
      message.append_string options[:chunk_separator]
      message.append_int options[:limit]
      message.append_int options[:around]
      
      message.append_array options[:docs]
      
      message.to_s
    end
  end
end