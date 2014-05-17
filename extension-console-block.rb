#$:.unshift File.join File.dirname(__FILE__), '..', '..', '..', 'asciidoctor', 'lib'

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'tilt'
require 'slim'

include ::Asciidoctor

BLOCK_CONSOLE_HTML = Tilt.new('block_console.html.slim', format: :html5, pretty: true, disable_escape: true) {|t|
  <<-EOS
p.cypherconsole
  - if title?
    strong=title
  span.database=(attr :database)
  ="\\n"
  span.command: strong=(attr :command) 
button#console-iframe-button.cypherconsole title='Show a console' type='button'
  img src='css/utilities-terminal.svg'
  span=title
="\\n"
button#console-external-button.cypherconsole title='Open the console in a new window' type='button'
  img src='css/external.svg'
  EOS
}

# An extension to process and display an interactive Neo4j console for the Neo4j manual.
#
# Example (in use)
#
#   .Interactive Example
#   [console]
#   ----
#   CREATE (n {name: 'Neo4j'})
# 
#   MATCH (n)
#   return n
#   ----
#
class ConsoleBlock < Extensions::BlockProcessor
  include_dsl

  named :console
  on_contexts :listing
  parse_content_as :raw

  def process parent, reader, attrs
    source = reader.read
    database, command = source.split("\n\n")
    attrs.update({
      'database' => database,
      'command' => command
    })
    create_block parent, :console, nil, attrs
  end
end

Extensions.register(:console) do
  block ConsoleBlock
  if @document.basebackend? 'html'
    @document.renderer.register_view 'block_console', BLOCK_CONSOLE_HTML
  end
end

exit 0 unless ARGV[0] == 'run'

input = <<-EOS
.Interactive Example
[console]
----
CREATE (n {name: 'Neo4j'})
 
MATCH (n)
return n
----
EOS

# HTML
puts Asciidoctor.convert input, safe: :safe
