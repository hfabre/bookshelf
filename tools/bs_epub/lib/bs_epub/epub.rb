require "forwardable"
require "uri"
require "json"
require "zip"
require "ox"

module BsEpub
  class ContainerMissing < StandardError; end
  class OPFPathMissing < StandardError; end
  class OPFMissing < StandardError; end

  class Epub
    extend Forwardable

    COVER_EXT = %w[.png .jpg .jpeg].freeze
    CONTAINER_PATH = "META-INF/container.xml".freeze
    OPF_EXT = ".opf".freeze

    MEDIA_TYPE = {
      ".png" => "image/png",
      ".jpeg" => "image/jpeg",
      ".jpg" => "image/jpeg"
    }.freeze

    NODE_NAME_MAPPING = {
      title: "dc:title",
      author: "dc:creator",
      language: "dc:language",
      date: "dc:date",
      description: "dc:description",
      publisher: "dc:publisher",
      serie: "calibre:series",
      serie_index: "calibre:series_index",
    }.freeze

    NODE_ACCESS = {
      title: lambda { |metadata_node| metadata_node.nodes.find { _1.value == "dc:title" } },
      author: lambda { |metadata_node| metadata_node.nodes.select { _1.value == "dc:creator" } },
      language: lambda { |metadata_node| metadata_node.nodes.find { _1.value == "dc:language" } },
      date: lambda { |metadata_node| metadata_node.nodes.find { _1.value == "dc:date" } },
      description: lambda { |metadata_node| metadata_node.nodes.find { _1.value == "dc:description" } },
      publisher: lambda { |metadata_node| metadata_node.nodes.find { _1.value == "dc:publisher" } }
    }.freeze

    CUSTOM_NODE_ACCESS = {
      serie: lambda { |custom_metas| custom_metas.find { _1.attributes[:name] == "calibre:series" } },
      serie_index: lambda { |custom_metas| custom_metas.find { _1.attributes[:name] == "calibre:series_index" } }
    }.freeze

    attr_reader :path, :zip, :opf_content, :epub_version, :metadata_node, :custom_metas, :failure_reason
    def_delegator :@zip, :close

    def self.container_content(opf_path)
      <<~XML
        <?xml version="1.0"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
              <rootfile full-path="#{opf_path}" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML
    end

    def initialize(path)
      @path = path
      load_book
    end

    def reset
      @zip.close
      @failure_reason = nil
      @epub_version = nil
      @custom_metas = nil
      load_book
    end

    def load_book
      @zip = Zip::File.new(path)

      raise ContainerMissing unless files.include?(CONTAINER_PATH)
      root_file = zip.get_input_stream(CONTAINER_PATH)

      result = Ox.load(root_file.read, mode: :generic)
      opf_path = result.root.nodes.first.nodes.first.attributes[:"full-path"]
      raise RootFilePathMissing if opf_path.nil?
      raise OPFMissing unless files.include?(opf_path)

      opf_file = zip.get_input_stream(opf_path)
      @opf_content = Ox.load(opf_file.read, mode: :generic)
      @epub_version = Gem::Version.new(opf_content.root.attributes[:version])
      @metadata_node = opf_content.root.nodes.find { _1.value == "metadata" }
      @custom_metas = metadata_node.nodes.select { _1.value == "meta" }
    rescue ContainerMissing, OPFPathMissing, OPFMissing => e
      @failure_reason = e.to_s
    end

    def files
      zip.entries.map(&:name)
    end

    def cover_filename
      if epub_version < Gem::Version.new("3.0")
        cover_node(cover_manifest_id)[:href]
      else
        # TODO
      end
    end

    def cover_node(cover_manifest_id)
      opf_content.root.locate("manifest/?[@id=#{cover_manifest_id}]").first
    end

    def cover_path
      files.find { _1.match?(/.*#{cover_filename}/) }
    end

    # URL OR PATH
    def replace_cover!(cover)
      new_ext = File.extname(cover)
      return unless COVER_EXT.include?(new_ext)

      new_conver_content =
        if cover =~ URI::DEFAULT_PARSER.make_regexp
          open(cover)
        else
          File.open(cover)
        end

      filename = File.basename(cover_filename, ".*")
      new_name = filename + new_ext

      zip.replace(cover_path, new_conver_content)
      zip.rename(cover_path, new_name)
      cover_node(cover_manifest_id)[:href] = new_name
      cover_node(cover_manifest_id)[:"media-type"] = MEDIA_TYPE[new_ext]
      override_opf!
    end

    def mt_json
      mt_hash.to_json
    end

    def mt_hash
      opf_content ? filled_mt_hash(opf_content.root.nodes.first, epub_version) : default_mt_hash
    end

    def create_container!
      zip.get_output_stream(CONTAINER_PATH) { _1.puts self.class.container_content(opf_path) }
      zip.commit
    end

    def update_mt!(metadata = {})
      metadata.each do |k, v|
        if (node_access = NODE_ACCESS[k])
          node = node_access.call(metadata_node)

          if node
            node.replace_text(v)
          else
            metadata_node << new_element(NODE_NAME_MAPPING[k], v)
          end
        elsif (node_access = CUSTOM_NODE_ACCESS[k])
          node = node_access.call(custom_metas)

          if node
            node[:content] = v
          else
            metadata_node << new_meta_element(NODE_NAME_MAPPING[k], v)
          end
        end
      end

      override_opf!
    end

    private

    def override_opf!
      zip.get_output_stream(opf_path) { _1.puts(Ox.dump(opf_content, with_xml: true)) }
      zip.commit
    end

    def cover_manifest_id
      custom_metas.find { _1.attributes[:name] == "cover" }.content
    end

    def opf_path
      files.find { File.extname(_1) == OPF_EXT }
    end

    def new_element(tag, content)
      Ox::Element.new(tag).tap do |elem|
        elem.replace_text(content)
      end
    end

    def new_meta_element(name, content)
      Ox::Element.new("meta").tap do |meta|
        meta[:name] = name
        meta[:content] = content
      end
    end

    def filled_mt_hash(metadata_node, _epub_version)
      mt = {}

      NODE_ACCESS.each do |k, access|
        node = access.call(metadata_node)
        mt[k] =
          if node.is_a?(Array)
            node.map { _1.text }.join(" / ")
          else
            node&.text
          end
      end

      CUSTOM_NODE_ACCESS.each do |k, access|
        node = access.call(custom_metas)
        mt[k] =
          case k
          when :serie
            node.attributes[:content] rescue nil
          when :serie_index
            node.attributes[:content].to_f rescue nil
          end
      end

      mt[:cover_filename] = cover_filename
      mt[:cover_path] = cover_path
      mt
    end

    def default_mt_hash(failure_reason = nil)
      {
        title: nil,
        author: nil,
        language: nil,
        date: Date.new(1900, 01, 01).iso8601,
        description: nil,
        publisher: nil,
        serie: nil,
        serie_index: nil,
        cover_filename: nil,
        cover_path: nil
      }
    end
  end
end
