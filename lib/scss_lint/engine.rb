require 'sass'

module SCSSLint
  class FileEncodingError < StandardError; end

  # Contains all information for a parsed SCSS file, including its name,
  # contents, and parse tree.
  class Engine
    ENGINE_OPTIONS = { cache: false, syntax: :scss }

    attr_reader :contents, :filename, :lines, :tree

    # Creates a parsed representation of an SCSS document from the given string
    # or file.
    #
    # @param scss_or_filename [String]
    def initialize(scss_or_filename)
      if File.exist?(scss_or_filename)
        build_from_file(scss_or_filename)
      else
        build_from_string(scss_or_filename)
      end

      # Need to force encoding to avoid Windows-related bugs.
      # Need `to_a` for Ruby 1.9.3.
      @lines = @contents.force_encoding('UTF-8').lines.to_a
      @tree = @engine.to_tree
    rescue Encoding::UndefinedConversionError, Sass::SyntaxError => error
      if error.is_a?(Encoding::UndefinedConversionError) ||
         error.message.match(/invalid.*(byte sequence|character)/i)
        raise FileEncodingError,
              "Unable to parse SCSS file: #{error}",
              error.backtrace
      else
        raise
      end
    end

  private

    # @param path [String]
    def build_from_file(path)
      @filename = path
      @engine = Sass::Engine.for_file(path, ENGINE_OPTIONS)
      @contents = File.open(path, 'r').read
    end

    # @param scss [String]
    def build_from_string(scss)
      @engine = Sass::Engine.new(scss, ENGINE_OPTIONS)
      @contents = scss
    end
  end
end
