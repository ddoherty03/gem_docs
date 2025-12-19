# frozen_string_literal: true

module GemDocs
  class Repo
    attr_accessor :root, :host, :user, :name

    def initialize(root: nil, host: nil, user: nil, name: nil)
      @root = root
      @host = host
      @user = user
      @name = name
    end

    class << self
      def from_gemspec(path = gemspec_path)
        spec = load_gemspec(path)

        url =
          spec.metadata["source_code_uri"] ||
          spec.metadata["homepage_uri"] ||
          spec.homepage

        abort "No repository URL found in gemspec metadata" unless url

        meta = parse_url(url)
        name = spec.name || meta[:name]
        new(root: File.dirname(File.expand_path(path)), host: meta[:host], user: meta[:user], name: name)
      end

      private

      # Return {host: <git_host>, user: <user_name>, name: <repo_name> } by parsing the given url
      def parse_url(url)
        host_bases = ['github', 'gitlab']
        md = url.match(%r{(?<host>(?:#{host_bases.join('|')})\.com)/(?<user>[^/]+)/(?<repo_name>[^/]+)(?:\.git)?/?})
        abort "Unsupported repository URL: #{url}" unless md

        { host: md[:host], user: md[:user], name: md[:repo_name] }
      end

      def gemspec_path
        candidates = Dir["*.gemspec"]
        abort "No gemspec found" if candidates.empty?
        abort "Multiple gemspecs found: #{candidates.join(', ')}" if candidates.size > 1
        candidates.first
      end

      def load_gemspec(path)
        Gem::Specification.load(path) ||
          abort("Failed to load gemspec: #{path}")
      end
    end
  end
end
