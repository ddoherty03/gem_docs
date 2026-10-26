# frozen_string_literal: true

require 'open3'

module GemDocs
  # Advisory static checks; never evaluates examples or starts Emacs.
  class Doctor
    def self.run
      new.run
    end

    def initialize
      @root = GemDocs.project_root
      @suggestions = []
    end

    def run
      readme = path(README_ORG)
      if File.file?(readme)
        text = File.read(readme)
        outline, ruby_blocks = scan_org(text)
        check_overview(outline)
        check_headers(outline) unless ruby_blocks.empty?
        check_version(outline)
        check_export(readme)
      else
        suggest(README_ORG, "File is missing. Run bundle exec rake docs:skeleton:readme to create it.")
        check_export(readme) if File.file?(path(README_MD))
      end
      check_yard
      puts "GemDocs doctor: #{@root}"
      puts "Advisory static checks; Org's inherited and per-block settings may intentionally differ."
      if @suggestions.empty?
        puts "No suggestions from these checks."
      else
        @suggestions.each { |message| puts "- #{message}" }
      end
      @suggestions
    end

    private

    def path(name)
      File.join(@root, name)
    end

    def suggest(file, message)
      @suggestions << "#{file}: #{message}"
    end

    # Exclude examples and export blocks so quoted headers/headings do not
    # masquerade as document configuration.
    def scan_org(text)
      outline = +''
      ruby_blocks = []
      block = nil
      text.each_line do |line|
        if block
          block = nil if line.match?(/^\s*#\+end_#{Regexp.escape(block)}\b/i)
        elsif (match = line.match(/^\s*#\+begin_(\w+)\b(.*)/i))
          block = match[1]
          ruby_blocks << line if block.casecmp?('src') && match[2].match?(/^\s+ruby\b/i)
        else
          outline << line
        end
      end
      [outline, ruby_blocks]
    end

    def check_overview(outline)
      heads = Array(GemDocs.config.overview_headings)
      return if heads.empty?

      sections = outline.scan(/^\* +([^\n]+)\n(.*?)(?=^\* |\z)/m).to_h
      missing = heads.reject { |head| sections.key?(head) }
      unless missing.empty?
        suggest(README_ORG, "No top-level overview section for #{missing.map(&:inspect).join(', ')}. " \
          "Add prose under that heading, or set c.overview_headings to existing top-level headings " \
          "(for example, ['Overview']) in GemDocs.configure.")
      end
      (heads - missing).each do |head|
        next unless sections[head].strip.empty?

        suggest(README_ORG, "The #{head.inspect} overview section is empty. Add a short description for YARD/ri.")
      end
    end

    def check_headers(outline)
      headers = outline.lines.grep(/^#\+PROPERTY:\s+header-args:ruby\+?\s/i).join
      if headers.empty?
        suggest(README_ORG, "Ruby examples have no file-level Ruby headers. Run bundle exec rake docs:headers " \
          "or review local/inherited settings before adding the defaults.")
        return
      end
      unless headers.match?(/:eval\s+never-export\b/)
        suggest(README_ORG, "Ruby headers do not specify :eval never-export. Consider it to execute examples with " \
          "docs:tangle and reuse results during export; docs:all then runs examples once.")
      end
      if headers.match?(/:eval\s+yes\b/)
        suggest(README_ORG, "Ruby headers contain :eval yes, which allows execution during export. " \
          "Remove or replace conflicting :eval settings if adopting never-export.")
      end
      unless headers.match?(/:session\s+(?!none\b)\S+/)
        suggest(README_ORG, "No shared Ruby :session is declared. Add one if examples depend on earlier variables.")
      end
      unless headers.match?(/:exports\s+both\b/)
        suggest(README_ORG, "Consider :exports both for Ruby examples so exported docs show code and saved results.")
      end
      unless headers.match?(/:wrap\s+example\b/)
        suggest(
          README_ORG,
          "Consider :wrap example to preserve saved Ruby output as literal text during Markdown export.",
        )
      end
      unless headers.match?(/:prologue\b/)
        suggest(README_ORG, "No Ruby :prologue is declared. Ensure examples load the local gem before using it.")
      end
    end

    def check_version(outline)
      blocks = outline.scan(Skeleton::VERSION_BLOCK_RE)
      if blocks.size != 1
        suggest(README_ORG, "Expected one managed README version block, found #{blocks.size}. " \
          "Remove duplicates if needed, then run bundle exec rake docs:skeleton:readme.")
        return
      end
      specs = Dir.glob(path('*.gemspec'))
      return unless specs.one?

      spec = Gem::Specification.load(specs.first)
      return unless spec
      return if blocks.first.lines.any? { |line| line.strip == "Version: #{spec.version}" }

      suggest(
        README_ORG,
        "README version differs from gemspec #{spec.version}. Run bundle exec rake docs:skeleton:readme.",
      )
    end

    def check_export(readme)
      markdown = path(README_MD)
      if !File.file?(markdown)
        suggest(README_MD, "File is missing. Run bundle exec rake docs:export after refreshing example results.")
      elsif File.open(markdown, &:gets).to_s.chomp != Emacs::README_MARKER
        suggest(README_MD, "Protected from export: missing first-line #{Emacs::README_MARKER}. " \
          "Keep handwritten Markdown as-is; review/back up older generated files before adding the marker to opt in.")
      elsif File.file?(readme) && File.mtime(readme) > File.mtime(markdown)
        suggest(README_MD, "README.org is newer; export may be stale. " \
          "Run docs:all after example edits, or docs:export if saved results are current.")
      end
    end

    def check_yard
      unless File.file?(path('.yardopts'))
        suggest(".yardopts", "File is missing. docs:yard creates defaults; review and commit that configuration.")
      end
      %w[.yardoc doc].each do |name|
        next unless File.directory?(path(name))

        tracked, status = Open3.capture2('git', '-C', @root, 'ls-files', '--', name, err: File::NULL)
        next unless status.success?

        if !tracked.empty?
          suggest("#{name}/", "Contains tracked generated YARD files. Consider untracking and ignoring that directory.")
        else
          _, ignored = Open3.capture2('git', '-C', @root, 'check-ignore', '-q', '--', "#{name}/", err: File::NULL)
          suggest(".gitignore", "Add /#{name}/ to exclude generated YARD output.") unless ignored.success?
        end
      rescue Errno::ENOENT
        # Git is optional; the remaining static checks still apply.
        next
      end
    end
  end
end
