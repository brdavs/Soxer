# encoding: utf-8
require 'hashie'
require 'sinatra/base'
require 'yaml'
require 'haml'
require 'sass'
require 'uuid'

#== Sinatra, web publishing DSL
#
# http://www.sinatrarb.com
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

    # === The FileReader class
    #
    # FileReader is responsible for reading a YAML file, that contains the
    # content and metadata for each web page.
    #
    # FileReader also assumes that each YAML file contains 2 top level fields:
    # uuid:: A Universally Unique Identifier field 
    # date:: A standard date and time field
    # if the fields are not present, they are automatically generated and
    # saved in the file.
    class FileReader

      attr_accessor :filename
      
      def initialize filename, settings
        @f, @s = filename, settings
      end
      
      # The method, that retuns the YAML structure in a ::hashie hash::.
      # Hashie makes the hash keys accessible either strings, symbols or methods.
      def get_content
        out = YAML.load_file( @f )
        add_date unless out['date']
        add_id unless out['uuid']
        out['url'] = @f.gsub(/#{@s.origin}\/(.+)\.yaml$/, "\\1" ).gsub(/(.+)\/index$/, "\\1" )
        out['mtime'] =  File.mtime( @f )
        Hashie::Mash.new out
      end
      
      private
      
      # A private method, that generates and adds a Universally Unique 
      # Identifier field to the data structure.
      def add_id
        mtime = File.mtime( @filename )
        File.open( @f, 'r+' ) do |f|
          out = "uuid: #{UUID.new.generate}\n"
          out << f.read; f.pos =  0
          f << out
        end
        File.utime( 0, mtime, @f )
      end
      
      # A private method, that adds a standard Time.now to the data structure.
      def add_date
        mtime = File.mtime( @f )
        File.open( @f, 'r+' ) do |f|
          out = "date: #{mtime.xmlschema}\n"
          out << f.read; f.pos =  0
          f << out
        end
      end
    end
    
    # === The UrlReader class
    #
    # UrlReader simply checks if the URL recieved can be matched to a file.
    # Currelntly it either matches a file path (ending with .yaml) from origin 
    # (the default is "content" directory within application root) or a 
    # directory path with index.yaml
    class UrlReader
    
      attr_accessor :url
      
      def initialize url, settings
        @url, @s = url, settings
      end
      
      # Creates a FileReader instance, maps the url to either yaml file or 
      # index.yaml within a directory represented by url.
      def get_content
        fn = case true
             when File.exist?( f = File.join( @s.origin, @url+'.yaml' ) ) then f
             when File.exist?( f = File.join( @s.origin, @url+'/index.yaml' ) ) then f
             else throw :halt, [404, "Document not found"]
             end
        FileReader.new(fn, @s).get_content
      end
    end
    
    # === Helper module
    # 
    # This module introduces several helper methods to Soxer application.
    module Helpers

      # === Document reader
      # This method reads a yaml file from disk and returns a hash.
      # 
      # ====Accepts
      # [url => String] 
      #   The string url. If empty, url recieved is used.
      #
      # ====Returns
      # [=> Hash]
      #   A hash representation of yaml file.
      def get_page url=params[:splat][0]
        UrlReader.new(url, options).get_content
      end
  
      # === Document list generator method
      # This method returns a list of documents filtered by &block statement.
      # 
      # ====Accepts
      # [&block] 
      #   A callback method for filtering all available file.
      #
      # ====Returns
      # [=> Array]
      #   Array of hashes representing yaml files.
      def get_list &block 
        fileset= Dir.glob File.join( options.origin, "**", "*.yaml" )
        fileset.delete_if {|d| (d=~/\/index.yaml$/ and fileset.include? d[0..-12]+'.yaml') }
        output = fileset.map! do |f|
          file = FileReader.new f, options
          if block_given?
            f = block.call file.get_content
          else
            f = file.get_content
          end
        end.compact
      end
  
      #=== The "sitemap" the sitemap generator partial
      #
      # This funnction accepts no arguments. It simply renders a sitemap file
      # with all available urls from the site
      
      # === Sitemap generator method
      # This generated an XML sitemap.
      # 
      # ====Accepts
      # This method does not accept arguments.
      #
      # ====Returns
      # [=> String]
      #   An XML representing the contents of the web site.
      def sitemap
        template = File.read File.join( File.dirname(__FILE__), 'views', 'sitemap.haml' )
        out = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
        out << haml( template, :layout => false )
      end

      # === The breadcrumb generator
      # This method generates a stylable breadcrumb based on document's directory path.
      # 
      # ==== Accepts
      # [options => Hash]
      #   Additional options, passed to haml interpreter
      #
      # ==== Returns
      # [ => String]
      #   Html string containing breadcrumb path with links.
      def breadcrumb options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'breadcrumb.haml' )
        haml( template, options.merge!( :layout => false ) )
      end
        
      # === The atom feed generator
      # This method generates an atom entry from a document.
      # 
      # ====Accepts
      # [doc => Hash] 
      #   The document hash, read from a YAML source
      # [options => hash]
      #   Additional options, passed to haml interpreter
      #
      # ====Returns
      # [=> String]
      #   Atom feed entry.
      def atom doc, options={}
				template = File.read File.join( File.dirname(__FILE__), 'views', 'atom.haml' )
				haml template, options.merge!( { :layout => false, 
				                                 :format => :xhtml,
				                                 :locals => { :doc => doc } } )
      end
      
      # === Google ads generator method
      # Returns the google ads code, according to arguments.
      # 
      # ====Accepts
      # [options => Hash] 
      #   Hash element :locals containing the following symbols
      #     :client = google ads client ID
      #     :slot   = google ads ad slot
      #     :width  = google ads element width
      #     :height = google ads element height
      #
      # ====Returns
      # [=> String]
      #   Html partial for the particular google ad.
      def google_ads options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'google_ads.haml' )
        pattern = File.join( settings.origin, "**", "*.yaml" )
        haml( template, options.merge!( :layout => false ) )
      end
      
      # === Disquss helper method
      # Returns the code for disqus comments.  
      # Calling this method without parameters generates javascript code needed
      # at the end of each page containing disqus comments code.
      # 
      # ====Accepts
      # [options => Hash] 
      #   Hash element :locals containing the following symbols
      #     :account = google ads client ID
      #
      # ====Returns
      # [=> String]
      #   Html code that includes Disquss comments.
      def disqus options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'disqus.haml' )
        haml( template, options.merge!( :layout => false ) )
      end
      
      # === Google analytics helper method
      # Returns the basic google analytics asynchronous tracking code.
      # 
      # ====Accepts
      # [options => Hash] 
      #   Hash element :locals containing the following symbols
      #     :tracker = google analytics tracker token
      #
      # ====Returns
      # [=> String]
      #   Google analytics asynchronous tracking code.
      def google_analytics options={}
        template = File.read File.join( File.dirname(__FILE__), 'views', 'google_analytics.haml' )
        haml( template, options.merge!( :layout => false ) )
      end
  
      # === Partial snippet generator method
      # Returns a partial from ./views directory as specified in sinatra's
      # manual.
      # 
      # ====Accepts
      # [snippet => Symbol]
      #   Symbol, representing a partial in the ./views directory (as specified by Sinatra)
      #   Note, that the name of the file follows a RoR convention:
      #   :some_file maps to ./views/_some_file.haml
      # [options => hash]
      #   Additional options, passed to haml interpreter
      #
      # ====Returns
      # [=> String]
      #   Html partial.
      def partial(snippet, options={})
        haml ('_'+snippet.to_s).to_sym, options.merge!(:layout => false)
      end
      
      # === Link tag generator method
      # Generates Html <a href="#"></a> tag accordng to RoR convention.
      # 
      # ==== Accepts
      # [test => string]
      #   Visible content of the link (the linked text).
      # [url => string]
      #   Url the linked text points to.
      #
      # ==== Returns
      # [ => String]
      #   Html link tag.
      def link_to text, url="/#{text.downcase.gsub(/\s/,'_')}"
        url.gsub!(/^\//, '') if url =~ /.+:\/\//
        "<a href=\"#{url}\"> #{text}</a>"
      end
      
      # === String obfuscator method
      # Converts strings into a stream of html character codes.
      # 
      # ==== Accepts
      # [str => string]
      #   String of arbitrary length.
      #
      # ==== Returns
      # [ => String]
      #   Html character string.
      def obfuscate str=nil
        out = []
        str.each_byte {|c| out << "&##{c};" }
        out.join
      end
      
    end
    
    def self.registered(app)
      
      if app.settings.root then
        app.set :origin, File.join(app.settings.root, 'content') unless app.settings.respond_to? 'content'
        app.set :public, File.join(app.settings.root, 'public') unless app.settings.respond_to? 'public'
        app.set :views, File.join(app.settings.root, 'views') unless app.settings.respond_to? 'views'
        app.set :log, File.join(app.settings.root, 'log') unless app.settings.respond_to? 'log'
      end
      
      app.helpers Soxer::Helpers
      
      app.mime_type :otf, 'application/x-font-TrueType'
      app.mime_type :ttf, 'application/x-font-TrueType'
      app.mime_type :eot, 'application/vnd.ms-fontobject'
      
      app.get("/sitemap.xml") { sitemap }

      app.get %r{(.*\.([^.]*))$} do
				content_type "text/html", :charset => "utf-8"
				url = params[:captures][0]
				type = params[:captures][1]
				file = File.join app.settings.origin, url
				
				case type
					when 'yaml' then 
						throw :halt, [404, "Document not found"]
						
					when /^jpg|png|pdf|doc|docx|xls|xlsx|pdf|ttf|otf$/i then
						send_file(file, :disposition => nil) if File.exist? file
						throw :halt, [404, "Document not found"]if  !File.exist? file
						
					when /^css$/i then
            content_type "text/css", :charset => "utf-8"
            sass url.sub('.'+type, '').to_sym
					  
					when 'atom' then 
						content_type "application/atom+xml", :charset => "utf-8"
						page = get_page url
						layout = File.read File.join( File.dirname(__FILE__), 'views', 'atom_layout.haml' )
						haml page['content'], :layout => layout,
																  :format => :xhtml,
						                      :locals => { :page => page }

					when 'rss' then 
						'RSS is not supported yet'
						
					else throw :halt, [404, "Document not found"]
				end
			end

      app.get '*/?' do
        content_type "text/html", :charset => "utf-8"
        page = get_page
        page.layout ||= 'layout'
        page.layout == 'false' ? layout = false : layout = page.layout.to_sym
        haml page.content, :layout => layout, :locals => { :page => page }
      end
      
    end
  end
  
  register Soxer
end
