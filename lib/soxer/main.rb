require 'sinatra/base'
require 'yaml'
require 'haml'
require 'uuid'


module Sinatra

  #== Soxer, the web publishing tool.
  #
  # Soxer is a Sinatra module that adds additional methods to sinatra routes.
  # These methods allow for route-to-yaml-file mapping in order to serve a set
  # files from disk with minimal effort. By clever use of views and/or
  # templating Soxer makes for a simple and effective web site creation tool.
  # You can get more information about Soxer, including the latest version at
  # http://soxer.mutsu.org
  #
  # Author:    Toni Anzlovar  (toni[at]formalibre.si)
  # Copyright: Copyright (c) 1010 Toni Anzlovar, www.formalibre.si
  # License:   Distributed under the GPL licence. http://www.gnu.org/licenses/gpl.html
  module Soxer
    
    class Filereader
      attr_accessor :filename

      def settings
        @s = Sinatra::Application
      end
      
      def get_content
        self.settings
        out = YAML.load_file( @filename )
        add_date unless out['date']
        add_id unless out['uuid']
        out['url'] = @filename.gsub(/#{@s.root}\/#{@s.origin}(.+)\.yaml$/, "\\1" ).gsub(/(.+)\/index$/, "\\1" )
        out['mtime'] =  File.mtime( @filename )
        out
      end
      
      private
      
      def add_id
        mtime = File.mtime( @filename )
        File.open( @filename, 'r+' ) do |f|
          out = "uuid: #{UUID.new.generate}\n"
          out << f.read; f.pos =  0
          f << out
        end
        File.utime( 0, mtime, @filename )
      end
      
      def add_date
        mtime = File.mtime( @filename )
        File.open( @filename, 'r+' ) do |f|
          out = "date: #{mtime.xmlschema}\n"
          out << f.read; f.pos =  0
          f << out
        end
      end
    end
    
    class Urlreader
      attr_accessor :url

      def settings
        @s = Sinatra::Application
      end
      
      def get_content
        self.settings
        fn = case true
             when File.exist?( f = File.join( @s.root, @s.origin, @url+'.yaml' ) ) then f
             when File.exist?( f = File.join( @s.root, @s.origin, @url+'/index.yaml' ) ) then f
             else throw :halt, [404, "Document not found"]
             end
        out = Filereader.new
        out.filename = fn
        out.get_content
      end
    end

    # === The "get_page", the document reading function
    #
    # Read the document in yaml format (with .yaml) ending directly mapped from
    # the given parameter. Sinatra's *settings.route* and Soxers 
    # *settings.origin* are prefixed to the path in order to get an absolute
    # filename. If the filename cannot be found, a directory by that name and
    # an index file within are probed and read.
    # 
    # If no parameter is given, the entire route is taken as the argument.
    def get_page url=params[:splat][0]
      out = Urlreader.new
      out.url = url
      out.get_content
    end

    #=== The "get_list" the document listing function
    #
    # The get_list function is the aggregator function. It reads all available
    # yaml files (that map to urls directly) and outputs them according to the
    # arguments you send it. Get_list only accepts 1 argument and a block.
    # 
    #==== sort='desc'
    # Direction of output. 'desc' (descending) or 'asc' (ascending)The default 
    # is 'desc'. If :sort conatins anything else, the output is unsorted.
    #
    #==== &block
    # Block is a callback. Every file (in hash form) is passed to block and
    # the block acts as the filter. :sort only takes the result and sorts it
    # according to the first key/value pair, so hash order IS signifficant.
    def get_list sort='desc', &block 
      pattern = File.join( settings.root, settings.origin, "**", "*.yaml" )
      output = Dir.glob(pattern).map! do |f|
        file = Filereader.new
        file.filename = f
        if block_given?
          f = block.call file.get_content
        end
      end.compact
      case sort
        when 'desc' then output.sort!{|b,a| a.to_a[0] <=> b.to_a[0] }
        when 'asc'  then output.sort!{|a,b| a.to_a[0] <=> b.to_a[0] }
      end
    end

    #=== The "sitemap" the sitemap generator
    #
    # This funnction accepts no arguments. It simply renders a sitemap file
    # with all available urls from the site
    def sitemap
      template = File.read File.join( File.dirname(__FILE__), 'views', 'sitemap.haml' )
      out = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
      out << haml( template, :layout => false )
    end


    #=== The "atom" the atom feed generator
    #
    # This method accepts an author (which is the global feed's author)
    # This is a required option, as the feed is only valid if it has at least
    # the global author. If individual articles have a yaml field "author",
    # the individual article's author is used for that article. In both cases,
    # author is a hash consisting of values 'name', 'email', 'url', of which
    # at least the 'name' should always be present.
    # 
    #==== autor
    # Hash of values as required by the Atom standard:
    # 'name', 'email' and 'url'. Only name is reuired.
    #
    #==== &block
    # Block is a callback. Every file (in hash form) is passed to block and
    # the block acts as the filter. That way only pages which are returned by
    # block are included in the feed
    def atom author=author, &block
      template = File.read File.join( File.dirname(__FILE__), 'views', 'atom.haml' )
      pattern = File.join( settings.root, settings.origin, "**", "*.yaml" )
      output = Dir.glob(pattern).map! do |f|
        file = Filereader.new
        file.filename = f
        if block_given?
          block.call file.get_content
        end
      end.compact!.sort!{|b,a| a.to_a[0] <=> b.to_a[0] }
      out = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
      out << haml( template, :layout => false, :locals => { :page=>get_page, :feed=>output, :author=>author } )
    end
    
    def google_ads options={}
      template = File.read File.join( File.dirname(__FILE__), 'views', 'google_ads.haml' )
      pattern = File.join( settings.root, settings.origin, "**", "*.yaml" )
      haml( template, options.merge!( :layout => false ) )
    end
    
    def disqus options={}
      template = File.read File.join( File.dirname(__FILE__), 'views', 'disqus.haml' )
      haml( template, options.merge!( :layout => false ) )
    end
    
    def google_analytics options={}
      template = File.read File.join( File.dirname(__FILE__), 'views', 'google_analytics.haml' )
      haml( template, options.merge!( :layout => false ) )
    end

    #=== "partial" rails like partial generator
    #
    # This funnction accepts a string and matches it to a haml layout (with a
    # underscore prepended) Sinatra's layouts directory. 
    # 
    #==== snippet
    # A string that maps to a haml view in the views directory
    # "partial :example, :layout => false" would map to a views/_example.haml
    #
    #==== options={}
    # Any options you pass to this partial ger merged and sent to haml as
    # sinatra's haml options (this is usefull for passing sinatra's :layout,
    # :locals and other variables)
    def partial(snippet, options={})
      haml ('_'+snippet).to_sym, options.merge!(:layout => false)
    end
    
    #=== "link_to" rails like link_to generator
    #
    # This funnction accepts a 1 or 2 strings. 
    # 
    #==== text
    # A string that becomes the link text. If there is no second parameter,
    # link_to converts the string into a local url by replacing all spaces with
    # an underscore and downcasing the string.
    #
    #==== url
    # This string is used for 'href' in a link
    def link_to(text, url="/#{text.downcase.gsub(/\s/,'_')}")
      url.gsub!(/^\//, '') if url =~ /.+:\/\//
      "<a href=\"#{url}\"> #{text}</a>"
    end
    
    # A simple string obuscator.
    # Useful for hiding emails and such
    #=== "obfuscate" simple string obuscator.
    #
    # This funnction accepts a 1 or 2 strings. 
    # 
    #==== str=nil
    # Obfuscates a string replacing characters with html entities.
    # Useful for hiding emails and such
    def obfuscate(str=nil)
      out = []
      str.each_byte {|c| out << "&##{c};" }
      out.join
    end

  end

  helpers Soxer
end
