require 'native'

class DotBlock < Asciidoctor::Extensions::BlockProcessor
  COLORS = {
    NODE: '#a8e270',
    NODE2: '#95bbe3',
    EDGE: '#a40000'
  }

  include_dsl

  named :dot
  on_context :listing
  parse_content_as :raw

  def process parent, reader, attrs
    settings = %(node [shape="box", penwidth="1.5", fillcolor="#fadcad", color="#2e3436", style="filled,rounded", fontcolor="#1c2021", fontsize=12, fontname="Arial"]
edge [color="#2e3436", penwidth=2, arrowhead="vee", arrowtail="vee", arrowsize=0.75, fontcolor="#1c2021", fontsize=12, fontname="Arial"]
nodesep=0.4)
    source = reader.read.gsub(/([A-Z]+[0-9]?)HIGHLIGHT/) { COLORS[$~[1]] }
    graph_data = %(digraph g {\n#{settings}\n#{source}\n})
    title = (value = attrs['title']) ? %(\n<div class="title">#{value}</div>) : nil
    rendered = <<-EOS
<div class="imageblock">
<div class="content">
<script type="text/vnd.graphviz" class="dotdiagram">
#{graph_data}
</script>
</div>#{title}
</div>
    EOS
    create_pass_block parent, rendered, attrs, subs: nil
  end
end

Asciidoctor::Extensions.register do
  block DotBlock
end

source = <<EOS
= Extension example

.Example Diagram
[dot]
----
"Graph" [fillcolor="NODEHIGHLIGHT"]
"Graph" -> Nodes [label="records data in", weight=2.0]
"Graph" -> Relationships [label="records data in", weight=2.0]
Relationships -> Nodes [label="organize"]
Labels -> Nodes [label="group"]
Nodes -> Properties [label="have"]
Relationships -> Properties [label="have"]
----
EOS

$global.addEventListener 'DOMContentLoaded', proc {
  base_dir = File.dirname $global.window.location.href
  ENV['HOME'] = base_dir
  ENV['PWD'] = base_dir
  timings = Asciidoctor::Timings.new
  html = Asciidoctor.convert source, base_dir: base_dir, safe: :safe, attributes: %w(showtitle sectanchors imagesdir=./images), timings: timings
  timings.print_report
  $global.document.getElementById('content').innerHTML = html
  %x(
    diagrams = document.getElementsByClassName('dotdiagram');
    for (var i = 0, len = diagrams.length; i < len; i++) {
      tag = diagrams[i];
      if (tag.getAttribute('type') == 'text/vnd.graphviz') {
        tag.outerHTML = Viz(tag.innerHTML, 'svg');
      }
    }
  )
}, false
