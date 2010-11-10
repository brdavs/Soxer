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
    
    # === The Filereader class
    #
    # In addition to reading the YAML file it also adds two fields to the file:
    # uuid: Universally Unique Identifier for atom and other feeds. Please, note
    #       that this id is not compared to other uuids. When creating a new
    #       document it's best to let soxer generate it.
    # date: A standard date field. When creating a new document it's best to 
    #       let soxer generate it.
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
        out['url'] = @filename.gsub(/#{@s.origin}(.+)\.yaml$/, "\\1" ).gsub(/(.+)\/index$/, "\\1" )
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
    
    # === The Urlreader class
    #
    # Urlreader simply checks if the URL recieved can be matched to a file.
    # Currelntly it either matches a file path (ending with .yaml) from origin 
    # (the default is "content" directory within application root) or a 
    # directory path with index.yaml
    class Urlreader
      attr_accessor :url

      def settings
        @s = Sinatra::Application
      end
      
      def get_content
        self.settings
        fn = case true
             when File.exist?( f = File.join( @s.origin, @url+'.yaml' ) ) then f
             when File.exist?( f = File.join( @s.origin, @url+'/index.yaml' ) ) then f
             else throw :halt, [404, "Document not found"]
             end
        out = Filereader.new
        out.filename = fn
        out.get_content
      end
    end
    
    module Helpers
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
      # arguments you send it. Get_list only accepts a block.
      #==== &block
      # Block is a callback, which filters the entire array of yaml files.
      # The result is an array of hashes, representing a subset of all yaml
      # files from "origin" directory. It can be sorted by using Array.sort
      # method.
      def get_list &block 
        pattern = File.join( settings.origin, "**", "*.yaml" )
        output = Dir.glob(pattern).map! do |f|
          file = Filereader.new
          file.filename = f
          if block_given?
            f = block.call file.get_content
          end
        end.compact
      end
  
      #=== The "sitemap" the sitemap generator partial
      #
      # This funnction accepts no arguments. It simply renders a sitemap file
      # with all available urls from the site
      def sitemap
        template = File.read File.join( File.dirname(__FILE__), 'views', 'sitemap.haml' )
        out = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
        out << haml( template, :layout => false )
      end
  
  
      #=== The "atom" the atom feed generator partial
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
        pattern = File.join( settings.origin, "**", "*.yaml" )
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
      
      #=== The "google_ads" helper partial
      #
      # This function accepts :locals with the following symbols:
      # :client = google ads client ID
      # :slot   = google ads ad slot
      # :width  = google ads element width
      # :height = google ads element height
      def google_ads options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'google_ads.haml' )
        pattern = File.join( settings.origin, "**", "*.yaml" )
        haml( template, options.merge!( :layout => false ) )
      end
      
      #=== The "Disqus" helper partial
      #
      # This function accepts :locals with the following symbols:
      # :account = Disqus account
      # If you call this helper with :account it will include and render
      # the discuss articles (for instance - at the end of your post). Calling 
      # this helper without :account parameter will include the Disqus closure 
      # script (somewhere close to the bottom of the page).
      def disqus options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'disqus.haml' )
        haml( template, options.merge!( :layout => false ) )
      end
      
      #=== The "Google Analytics" helper partial
      #
      # This function accepts :locals with the following symbols:
      # :tracker = Google Analytics tracker token
      # It uses the new basic async script. For more elaborate use, please
      # consult Google manuals and construct your own partial to suite your
      # needs.
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
        haml ('_'+snippet.to_s).to_sym, options.merge!(:layout => false)
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
    
    def self.registered(app)
      app.helpers Soxer::Helpers
      
      def app.settings 
        Sinatra::Application
      end
      
      set :origin, File.join(app.settings.root, 'content')
      
      app.get("/sitemap.xml") { sitemap }
      
      app.get "/*.css" do
        content_type "text/css", :charset => "utf-8"
        sass params[:splat][0].to_sym
      end
      
      app.get '*.*' do
        file = File.join( settings.origin, params[:splat].join('.') )
        case params[:splat][1]
          when /[jpg|png|pdf|doc|docx|xls|xlsx|pdf|]/i then send_file(file, :disposition => nil)
        end
      end
 
      app.get '*/?' do
        content_type "text/html", :charset => "utf-8"
        
        if params[:splat].last =~ /\.atom$/ then
          set :haml, { :format => :xhtml }
          content_type "application/atom+xml", :charset => "utf-8"
        end
      
        page = get_page
        page['layout'] ||= 'layout'
        haml page['content'], :layout => page['layout'].to_sym, :locals => { :page => page }
      end
    end
  end
  
  register Soxer
end

