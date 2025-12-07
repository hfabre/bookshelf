require "forwardable"
require "uri"
require "json"
require "zip"
require "nokogiri"

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

    COVER_EXT_TYPE = {
      "image/png" => ".png",
      "image/jpeg" => ".jpeg",
      "image/jpeg" => ".jpg"
    }.freeze

    NODE_NAME_MAPPING = {
      title: "dc:title",
      authors: "dc:creator",
      language: "dc:language",
      date: "dc:date",
      description: "dc:description",
      publisher: "dc:publisher",
      serie: "calibre:series",
      serie_index: "calibre:series_index"
    }.freeze

    NODE_ACCESS = {
      title: lambda { |metadata_node| metadata_node.elements.find { |n| n.name == "dc:title" || n.name == "title" } },
      authors: lambda { |metadata_node| metadata_node.elements.select { |n| n.name == "dc:creator" || n.name == "creator" } },
      language: lambda { |metadata_node| metadata_node.elements.find { |n| n.name == "dc:language" || n.name == "language" } },
      date: lambda { |metadata_node| metadata_node.elements.find { |n| n.name == "dc:date" || n.name == "date" } },
      description: lambda { |metadata_node| metadata_node.elements.find { |n| n.name == "dc:description" || n.name == "description" } },
      publisher: lambda { |metadata_node| metadata_node.elements.find { |n| n.name == "dc:publisher" || n.name == "publisher" } }
    }.freeze

    CUSTOM_NODE_ACCESS = {
      serie: lambda { |custom_metas| custom_metas.find { |n| n.attr("name") == "calibre:series" } },
      serie_index: lambda { |custom_metas| custom_metas.find { |n| n.attr("name") == "calibre:series_index" } }
    }.freeze

    attr_reader :path_or_io, :zip, :opf_content, :epub_version, :metadata_node, :custom_metas, :failure_reason, :logger, :current_buffer
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

    def initialize(path_or_io, logger: Logger.new(IO::NULL), log_level: Logger::INFO)
      @path_or_io = path_or_io
      @logger = logger
      @logger.level = log_level
      load_book
    end

    def reset
      @failure_reason = nil
      @epub_version = nil
      @custom_metas = nil
      load_book
    end

    def load_book
      logger.debug "init zip"
      @zip ||=
        if path_or_io.respond_to?(:path)
          Zip::File.new(path_or_io.path)
        else
          Zip::File.open_buffer(path_or_io)
        end

      raise ContainerMissing unless files.include?(CONTAINER_PATH)

      logger.debug "getting root file"
      root_file = zip.get_input_stream(CONTAINER_PATH)
      logger.debug "loading root file"
      result = Nokogiri::XML(root_file.read)
      logger.debug "getting opf path"
      opf_path = result.root.elements.first.elements.first.attr("full-path")
      raise OPFPathMissing if opf_path.nil?
      raise OPFMissing unless files.include?(opf_path)

      logger.debug "getting opf file"
      opf_file = zip.get_input_stream(opf_path)
      logger.debug "loading opf file"
      @opf_content = Nokogiri::XML(opf_file.read)
      logger.debug "getting epub version"
      @epub_version = Gem::Version.new(opf_content.root.attr("version"))
      logger.debug "getting metadata node"
      @metadata_node = opf_content.root.elements.find { |n| n.name == "metadata" }
      logger.debug "getting custom metas"
      @custom_metas = metadata_node.elements.select { |n| n.name == "meta" }
      logger.debug "done"
    rescue ContainerMissing, OPFPathMissing, OPFMissing => e
      @failure_reason = e.to_s
    end

    def files
      zip.entries.map(&:name)
    end

    def cover_filename
      return find_cover_filename_fallback unless cover_manifest_id

      if epub_version < Gem::Version.new("3.0")
        cover_node(cover_manifest_id)&.attr("href")
      else
        # TODO
      end
    end

    def cover_node(cover_manifest_id)
      ns = {
        "opf" => "http://www.idpf.org/2007/opf"
      }

      opf_content.xpath("//opf:manifest/opf:item[@id='#{cover_manifest_id}']", ns).first ||
      opf_content.xpath("//opf:manifest/*[@id='#{cover_manifest_id}']", ns).first
    end

    def cover_path
      if cover_filename
        files.find { _1.match?(/.*#{cover_filename}/) }
      else
        find_cover_path_heuristic
      end
    end

    def cover_bytes
      zip.get_input_stream(cover_path).read
    end

    # URL OR PATH
    def replace_cover!(cover)
      new_ext = File.extname(cover)
      return unless COVER_EXT.include?(new_ext)

      new_cover_content =
        if cover =~ URI::DEFAULT_PARSER.make_regexp
          open(cover)
        else
          File.open(cover)
        end

      filename = File.basename(cover_filename, ".*")
      new_name = filename + new_ext

      zip.replace(cover_path, new_cover_content)
      zip.rename(cover_path, new_name) if new_name != File.basename(cover_path)

      cover_node(cover_manifest_id)["href"] = new_name
      cover_node(cover_manifest_id)["media-type"] = MEDIA_TYPE[new_ext]

      override_opf!
    end

    def mt_json
      mt_hash.to_json
    end

    def mt_hash
      opf_content ? filled_mt_hash(root_meta_node, epub_version) : default_mt_hash
    end

    def create_container!
      zip.get_output_stream(CONTAINER_PATH) { _1.puts self.class.container_content(opf_path) }
      save_zip!
    end

    def update_mt!(metadata = {})
      metadata.compact!

      metadata.each do |k, v|
        if (node_access = NODE_ACCESS[k])
          node = node_access.call(metadata_node)

          if node && k == :authors
            node = node.is_a?(Array) ? node.first : node
            if node  # Add nil check here
              node.remove
              metadata_node.add_child(new_element(NODE_NAME_MAPPING[k], v))
            else
              metadata_node.add_child(new_element(NODE_NAME_MAPPING[k], v))
            end
          elsif node
            node.content = v
          else
            metadata_node.add_child(new_element(NODE_NAME_MAPPING[k], v))
          end
        elsif (node_access = CUSTOM_NODE_ACCESS[k])
          node = node_access.call(custom_metas)

          if node
            node["content"] = v
          else
            metadata_node.add_child(new_meta_element(NODE_NAME_MAPPING[k], v))
          end
        end
      end

      override_opf!
      @current_buffer
    end

    private

    def root_meta_node
      opf_content.root.elements.find { |el| el.name == "metadata" }
    end

    def override_opf!
      zip.get_output_stream(opf_path) { _1.puts(opf_content.to_xml) }
      save_zip!
    end

    def save_zip!
      zip.commit
      # Save buffer so we can retrieve it as otherwise the new @zip.write_buffer will be enmpty as there is no modification of the zip
      @current_buffer = zip.write_buffer
      @zip = Zip::File.open_buffer(@current_buffer)
      reset
    end

    def cover_manifest_id
      cover_meta = custom_metas.find { |n| n.attr("name") == "cover" }
      cover_meta&.attr("content") || cover_meta&.content
    end

    # EPUB format is a mess...
    # Try to find directly inside the manifest
    def find_cover_filename_fallback
      manifest_node = opf_content.root.elements.find { |n| n.name == "manifest" }
      return nil unless manifest_node

      cover_patterns = [ /cover\.(jpe?g|png)/i, /^cover$/i ]

      manifest_node.elements.each do |node|
        next unless node.attr("href")
        href = node.attr("href").to_s

        return href if cover_patterns.any? { |pattern| File.basename(href) =~ pattern }
      end

      nil
    end

    # Try to find an image that may be the cover base on its name
    # This is from an ai
    def find_cover_path_heuristic
      common_cover_patterns = [
        /cover\.(jpe?g|png)$/i,
        /\bcover\b.*\.(jpe?g|png)$/i,
        /\.(jpe?g|png)$/i
      ]

      # Try first image corresponding to patterns
      common_cover_patterns.each do |pattern|
        match = files.find { |f| f =~ pattern }
        return match if match
      end

      # Take first found image
      image_file = files.find { |f| f =~ /\.(jpe?g|png)$/i }
      image_file
    end

    def opf_path
      files.find { File.extname(_1) == OPF_EXT }
    end

    def new_element(tag, content)
      # Create element with the full tag name (including namespace prefix)
      element = opf_content.create_element(tag)
      element.content = content
      element
    end

    def new_meta_element(name, content)
      meta = opf_content.create_element("meta")
      meta["name"] = name
      meta["content"] = content
      meta
    end

    def filled_mt_hash(metadata_node, _epub_version)
      mt = {}

      NODE_ACCESS.each do |k, access|
        node = access.call(metadata_node)
        mt[k] =
          if node.is_a?(Array)
            node.map { |n| n.content }
          else
            node&.content
          end
      end

      CUSTOM_NODE_ACCESS.each do |k, access|
        node = access.call(custom_metas)
        mt[k] =
          case k
          when :serie
            node&.attr("content")
          when :serie_index
            node&.attr("content")&.to_f
          end
      end

      mt[:cover_filename] = cover_filename
      mt[:cover_path] = cover_path
      mt
    end

    def default_mt_hash
      {
        title: nil,
        authors: nil,
        language: nil,
        date: Date.new(1900, 01, 01).iso8601,
        description: nil,
        publisher: nil,
        serie: nil,
        serie_index: nil,
        cover_filename: nil,
        cover_path: nil,
        failure_reason: failure_reason
      }
    end
  end
end
