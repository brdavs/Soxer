Soxer, the web publishing tool
==============================

[Soxer](http://soxer.mutsu.org) is a document/url centric web publishing 
system. It enables the developer to quickly setup, design and deploy any web based project, from quick mockups to complete portals. 

Soxer is distributed under the terms of [GNU General Public License](http://www.gnu.org/licenses/gpl.htm) and is supported by [Formalibre](http://www.formalibre.si).

It's strong points include:

- All data and configuration is disk based. 
- Everything is editable with a text editor.
- There is no relational database back end.
- It uses and follows standards. The document format is [YAML](http://www.yaml.org)
- Document model is loose (adaptable "on the fly") and only determined by your views or partials.
- It's a Sinatra modular application, so you can easily incorporate it into existing project.

What Soxer is not (yet)...

- ... a complete CMS in classic sense.
- ... a *turn-key-slap-the-logo-on-and-charge-for-it* solution.
- ... mature product.


Test drive the soxer
--------------------

You can install soxer by:  
`$ sudo gem install soxer`

You can benefit by installing 2 more gems:  
`$ sudo gem install thin rdiscount`

Thin and rdiscount are not necessary for Soxer to run, but they make it run much faster even in development mode. [Thin](http://code.macournoyer.com/thin) is a production ready rubyweb server, [rdiscount](http://github.com/rtomayko/rdiscount) is a ruby interface to [discount](http://www.pell.portland.or.us/~orc/Code/discount), a C implementation of [Markdown](http://daringfireball.net/projects/markdown).

To create a "hello world" type 'empty' application named 'webpage', you can run:  
`$ soxer create empty webpage`

The directory webpage, which you just created has everything you need to run your first soxer application. Just enter it and run soxer in developement mode:  
<code>
  $ cd webpage; soxer test
</code>

It's that simple.

You can read more about soxer on <http://soxer.mutsu.org>, which hosts a growing list of tutorials. You can also contact the author at **toni at formalibre dot si**.

