# frozen_string_literal: true

require 'strscan'

module GemDocs
  module Overview
    BANNER = 'Gem Overview (extracted from README.org by gem_docs)'

    # @return String The overview from README per config
    def self.write_overview?
      repo = Repo.from_gemspec
      target = File.join("lib", "#{repo.name}.rb")

      return false unless File.exist?(target)

      overview = extract
      return false unless overview

      old_lib = File.read(target)
      old_match = old_lib.match(overview_re)
      old_comment = old_match.to_s

      new_comment = <<~RUBY.chomp
        # #{BANNER}
        #
        #{overview.lines.map { |l| l.match?(/\A\s*\z/) ? '#' : "# #{l.rstrip}" }.join("\n")}
      RUBY
      return false if old_comment.rstrip == new_comment

      new_lib =
        if old_match
          # There was an overview in the old_lib_content, so replace it with
          # the new_lib_comment.
          old_lib.sub(old_comment, new_comment)
        else
          scanner = StringScanner.new(old_lib)
          if scanner.scan_until(/^(?:class|module) #{Regexp.escape(repo.module_name)}\b/)
            scanner.pre_match + "\n" + new_comment + "\n" + scanner.matched + scanner.rest
          else
            # No matching class or module in the file. Add an empty module at the end.
            old_lib + "\n" + new_comment + "\nmodule #{repo.module_name}\nend"
          end
        end
      File.write(target, new_lib) > 0
    end

    # Return a Regexp that capture any GemDocs-generated overview comment in
    # the main library file. The Regex requires the comment to come immediately
    # before the `class <GemName>` or `module <GemName>` line, or it will not match.
    def self.overview_re
      repo = Repo.from_gemspec
      # Match only comment/blank lines, never Ruby code between the banner and
      # declaration. This also recognizes legacy empty or duplicated banners.
      %r{^\#[ ]#{Regexp.escape(BANNER)}[^\n]*
        (?:\n(?:[ \t]*\#[^\n]*|[ \t]*))*
        (?=\n(?:class|module)\s+#{Regexp.escape(repo.module_name)}\b)}ix
    end

    def self.present?
      repo = Repo.from_gemspec
      target = File.join("lib", "#{repo.name}.rb")

      return false unless File.exist?(target)

      File.read(target).match?(overview_re)
    end

    class << self
      private

      # Extract the Overview from the concatenation of all the README.org
      # top-level sections given in GemDocs.config.overview_headings.
      def extract
        text = File.read(README_ORG)
        heads = GemDocs.config.overview_headings
        return if heads.nil? || heads.empty?

        result = +''
        scanner = StringScanner.new(text)
        heads.each do |h|
          if scanner.scan_until(/^(?<head>\* +#{Regexp.escape(h)})(?=[ \t\n]|\z)[^\n]*\n/)
            this_head = scanner.named_captures['head'] + "\n"
            body_start = scanner.pos
            body_end =
              if scanner.scan_until(/\n^\s*\*[^\*\n]+/)
                scanner.pos - scanner.matched.size
              else
                scanner.string.size - 1
              end
            scanner.pos = body_end
            result << this_head + scanner.string[body_start..body_end]
          end
        end
        return if result.empty?

        result.sub(/\A\n*/, '')
      end
    end
  end
end
