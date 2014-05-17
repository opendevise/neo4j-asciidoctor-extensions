#$:.unshift File.join File.dirname(__FILE__), '..', '..', '..', 'asciidoctor', 'lib'

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'tilt'
require 'slim'

include ::Asciidoctor

BLOCK_CONFIGSETTING_HTML = Tilt.new('block_configsetting.html.slim', format: :html5, pretty: true, disable_escape: true) {|t|
  <<-EOS
table.configsetting id=@id cellspacing=0 cellpadding=0
  - if title?
    caption=title
    tfoot: tr: td.configsetting-default valign='top' align='left' colspan=1
      => 'Default value:'
      code.literal=(attr :default_value)
    tbody: tr: td valign='top' align='left' colspan=1
      p.configsetting-key: code.literal=(attr :key)
      p.configsetting-desc=(attr :description)
  EOS
}

# An extension to process and display a Neo4j configuration
# setting for the Neo4j manual.
#
# Example (in use)
#
#   .All stores total mapped memory size
#   [configsetting]
#   ----
#   all_stores_total_mapped_memory_size: 524288000
#   The size to allocate for a memory mapping pool to be shared between all stores.
#   ----
#
class ConfigSettingBlock < Extensions::BlockProcessor
  include_dsl

  named :configsetting
  on_contexts :open, :listing
  parse_content_as :raw

  def process parent, reader, attrs
    lines = reader.read_lines
    key, default_value = lines.shift.split(': ')
    description = lines.shift
    attrs.update({
      'id' => key,
      'key' => key,
      'default_value' => default_value,
      'description' => description
    })
    create_block parent, :configsetting, nil, attrs
  end
end

Extensions.register(:configsetting) do
  block ConfigSettingBlock
  if @document.basebackend? 'html'
    @document.renderer.register_view 'block_configsetting', BLOCK_CONFIGSETTING_HTML
  end
end

exit 0 unless ARGV[0] == 'run'

input = <<-EOS
.All stores total mapped memory size
[configsetting]
--
all_stores_total_mapped_memory_size: 524288000
The size to allocate for a memory mapping pool to be shared between all stores.
--
EOS

# HTML
puts Asciidoctor.convert input, safe: :safe

=begin
# old template
BLOCK_CONFIGSETTING_HTML = Tilt.new('block_configsetting.html.slim', format: :html5, pretty: true) {|t|
  <<-EOS
.configsetting.table id=@id
  - if title?
    p.title: strong=title
  .configsetting.table-contents
    table cellspacing=0 cellpadding=0 border=1 summary=(title? ? title : nil)
      colgroup: col.col1
      tfoot: tr: th.configsetting-default valign='top' align='left'
        => 'Default value:'
        code.literal=(attr 'default_value')
      tbody: tr: td valign='top' align='left'
        p.configsetting-key: code.literal=(attr 'key')
        p.configsetting-desc=(attr 'description')
br.configsetting.table-break
  EOS
}
=end
