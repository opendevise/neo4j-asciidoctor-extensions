#$:.unshift File.join File.dirname(__FILE__), '..', '..', '..', 'asciidoctor', 'lib'

require 'asciidoctor'
require 'asciidoctor/extensions'

include ::Asciidoctor

# An extension to render directed graphs using the graphviz syntax.
#
# NOTE We'll probably want to merge the logic in this extension upstream
# to the Asciidoctor Diagram extension (https://github.com/asciidoctor/asciidoctor-diagram)
#
# Example (in use)
#
#   [dot, target.svg, meta]
#   ....
#   Graph [fillcolor="NODEHIGHLIGHT"]
#   Graph -> Nodes [label="records data in" weight=2.0]
#   Graph -> Relationships [label="records data in" weight=2.0]
#   Relationships -> Nodes [label="organize"]
#   Labels -> Nodes [label="group"]
#   Nodes -> Properties [label="have"]
#   Relationships -> Properties [label="have"]
#   ....
#
#--
# NOTE could implement in JavaScript using https://github.com/mdaines/viz.js
class DotBlock < Extensions::BlockProcessor
  include_dsl

  named :dot
  on_contexts :listing, :literal, :paragraph
  name_positional_attributes 'target', 'colorset', 'graphattrs'
  parse_content_as :raw

  def process parent, reader, attrs
    doc = parent.document
    indata = reader.read
    nodefontsize = 10
    edgefontsize = nodefontsize
    nodefontcolor = '#1c2021' # darker grey
    edgefontcolor = nodefontcolor
    edgecolor = '#2e3436' # dark grey
    boxcolor = edgecolor
    edgehighlight = '#a40000' # dark red
    nodefillcolor = '#ffffff'
    nodehighlight = '#fcee7d' # lighter yellow
    nodehighlight2 = '#fcc574' # lighter orange
    nodeshape = 'box'
    
    fontpath = doc.attr 'fontsdir' 
    targetimage = doc.normalize_web_path attrs['target'], (doc.attr 'imagesdir')
    case attrs['colorset']
    when 'meta'
      nodefillcolor = '#fadcad' # lighter brown
      nodehighlight = '#a8e270' # lighter green
      nodehighlight2 = '#95bbe3' # lighter blue
    when 'neoviz'
      nodeshape = 'Mrecord'
      nodefontsize = 8
      edgefontsize = nodefontsize
    end
    graphattrs = attrs['graphattrs']
    graphsettings = %(graph [size="7.0,9.0" fontpath="#{fontpath}"])
    nodestyle='filled,rounded'
    nodesep = 0.4
    textnode = 'shape=plaintext,style=diagonals,height=0.2,margin=0.0'
    arrowhead = 'vee'
    arrowsize = '0.75'
    indata = indata.gsub('NODEHIGHLIGHT', nodehighlight)
      .gsub('NODE2HIGHLIGHT', nodehighlight2)
      .gsub('EDGEHIGHLIGHT', edgehighlight)
      .gsub('BOXCOLOR', boxcolor)
      .gsub('TEXTNODE', textnode)
    svgfile = targetimage
    pngfile = %(#{svgfile}.png)
    #attrs['alt'] ||= svgfile.sub(/\.[^.]+$/, '').tr('-_', ' ')
    graphfont = 'FreeSans'
    nodefont = graphfont
    edgefont = graphfont

    data = %(digraph g{ #{graphsettings}
  node [shape="#{nodeshape}" penwidth=1.5 fillcolor="#{nodefillcolor}" color="#{boxcolor}"
   fontcolor="#{nodefontcolor}" style="#{nodestyle}" fontsize=#{nodefontsize}
   fontname="#{nodefont}"]
  edge [color="#{boxcolor}" penwidth=2 arrowhead="#{arrowhead}" arrowtail="#{arrowhead}"
   arrowsize=#{arrowsize} fontcolor="#{edgefontcolor}"
   fontsize=#{edgefontsize} fontname="#{edgefont}"]
  nodesep=#{nodesep}
  fontname="#{graphfont}"
  #{graphattrs} #{indata} })

    escaped_data = data.tr("\n", ' ').gsub('"', '\\"')
    %x{echo "#{escaped_data}" | dot -Tsvg -o"#{svgfile}"}
    create_image_block parent, attrs
  end
end

Extensions.register(:dot) do
  block DotBlock
end

fonts_dir = ARGV[1] || '/home/dallen/projects/asciidoctor/use-cases/neo4j-doctools/src/bin/fonts'

if ARGV[0] && (ARGV[0].end_with? '.adoc')
  Asciidoctor.convert_file ARGV[0], in_place: true, safe: :safe, attributes: { 'fontsdir' => fonts_dir }
end

exit 0 unless ARGV[0] == 'run'

input = <<-EOS
.Graph Database
[dot, graphdb-gve.svg, meta]
----
"Graph" [fillcolor="NODEHIGHLIGHT"]
"Graph" -> Nodes [label="records data in" weight=2.0]
"Graph" -> Relationships [label="records data in" weight=2.0]
Relationships -> Nodes [label="organize"]
Labels -> Nodes [label="group"]
Nodes -> Properties [label="have"]
Relationships -> Properties [label="have"]
----
EOS

# HTML
#puts Asciidoctor.convert input, safe: :safe, attributes: %w(fontsdir=/home/dallen/projects/asciidoctor/use-cases/neo4j-doctools/src/bin/fonts)
Asciidoctor.convert input, safe: :safe, to_file: 'dot.html', attributes: { 'fontsdir' => fonts_dir }
