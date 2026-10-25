# frozen_string_literal: true

module GemDocs
  module Skeleton
    VERSION_BLOCK_RE = /^# gem_docs:version begin\n.*?^# gem_docs:version end\n?/m

    # Create the README or refresh its managed gemspec version block.
    # @return [Boolean] whether the README changed
    def self.make_readme?
      repo = Repo.from_gemspec
      return write_version?(File.read(README_ORG), repo.version) if readme_present?

      content = <<~SKEL
        #+TITLE: #{repo.module_name} Guide
        #{Header.org_headers.strip}

        * Introduction

        * Installation

        #+begin_src sh :eval no
          bundle add #{repo.name}
        #+end_src

        If bundler is not being used to manage dependencies, install the gem by executing:

        #+begin_src sh :eval no
          gem install #{repo.name}
        #+end_src

        * Usage

        * Development
        After checking out the repo, run `bin/setup` to install dependencies. Then,
        run `rake spec` to run the tests. You can also run `bin/console` for an
        interactive prompt that will allow you to experiment.

        To install this gem onto your local machine, run `bundle exec rake
        install`.

        * Contributing
        Bug reports and pull requests are welcome on GitHub at
        https://github.com/#{repo.user}/#{repo.name}.

        * License
        The gem is available as open source under the terms of the [MIT
        License](https://opensource.org/licenses/MIT).
      SKEL
      write_version?(content, repo.version)
    end

    def self.write_version?(content, version)
      block = <<~ORG
        # gem_docs:version begin
        Version: #{version}
        # gem_docs:version end
      ORG
      updated = if content.match?(VERSION_BLOCK_RE)
        content.sub(VERSION_BLOCK_RE, block)
      else
        # Keep the version below the initial Org metadata and near the CI badge.
        header = content[/\A(?:#\+[^\n]*\n)*/]
        header + "\n" + block + "\n" + content.delete_prefix(header)
      end
      return false if File.exist?(README_ORG) && updated == content

      File.write(README_ORG, updated)
      true
    end
    private_class_method :write_version?

    def self.readme_present?
      File.exist?(README_ORG)
    end

    def self.make_changelog?
      return false if changelog_present?

      content = <<~SKEL
        * COMMENT CHANGELOG tips:
        1. Don't dump your git change logs into this file, write them yourself.
        2. Keep entries short and user-focused,
        3. Use non-technical language, but do speak in the vocabulary of your gem.
        4. Don't document changes only of interest to the programmers, just those the
           user would find useful.
        5. Give each heading a version number and an inactive date (C-c ! is useful here).

        * Version 0.3.0 [2025-12-27 Sat]
        - First change
        - Second change
      SKEL
      File.write(CHANGELOG_ORG, content) > 0
    end

    def self.changelog_present?
      File.exist?(CHANGELOG_ORG)
    end
  end
end
