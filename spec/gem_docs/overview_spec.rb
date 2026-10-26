# frozen_string_literal: true

module GemDocs
  RSpec.describe Overview do
    let(:main_lib_wo_overview) do
      <<~LIB
        # -*- mode: ruby -*-
        # frozen_string_literal: true

        require "rake"
        require "rake/dsl_definition"
        require "fileutils"

        module FakeGem
          require_relative "gem_docs/version"
          require_relative "gem_docs/config"
          require_relative "gem_docs/repo"
          require_relative "gem_docs/emacs"
          require_relative "gem_docs/overview"
          require_relative "gem_docs/yard"
          require_relative "gem_docs/badge"
          require_relative "gem_docs/tasks"

          # Auto-detect project root (handles being run from subdirs)
          def self.project_root
            here = Dir.pwd
            here = File.dirname(here) until !Dir['*.gemspec', 'Gemfile'].empty? || here == "/"
            here
          end
        end
      LIB
    end

    let(:main_lib_wo_module) do
      <<~LIB
        # -*- mode: ruby -*-
        # frozen_string_literal: true

        require "rake"
        require "rake/dsl_definition"
        require "fileutils"
      LIB
    end

    let(:main_lib_w_overview) do
      <<~LIB
        # -*- mode: ruby -*-
        # frozen_string_literal: true

        require "rake"
        require "rake/dsl_definition"
        require "fileutils"

        # #{Overview::BANNER}
        #
        # * Introduction
        # This gem contains ~rake~ tasks to facilitate the production of documentation
        # in other gems.
        #
        # Right now, it provides tasks for:
        #
        # - running the code block examples in a ~README.org~
        # - exporting ~README.org~ to Git-flavored markdown in ~README.md~
        # - ensuring a workflow or ci badge is present in the ~README.md~
        # - generating yard documents for your repo, and
        # - copying the introductory contents of the README as a leading comment in your
        #   main gem library file so it gets picked up as an overview for ~ri~ and ~yri~
        module FakeGem
          require_relative "gem_docs/version"
          require_relative "gem_docs/config"
          require_relative "gem_docs/repo"
          require_relative "gem_docs/emacs"
          require_relative "gem_docs/overview"
          require_relative "gem_docs/yard"
          require_relative "gem_docs/badge"
          require_relative "gem_docs/tasks"

          # Auto-detect project root (handles being run from subdirs)
          def self.project_root
            here = Dir.pwd
            here = File.dirname(here) until !Dir['*.gemspec', 'Gemfile'].empty? || here == "/"
            here
          end
        end
      LIB
    end

    let(:fake_spec) do
      <<~RUBY
        Gem::Specification.new do |spec|
          spec.name        = "fake_gem"
          spec.version     = "0.9.10"
          spec.summary     = "Fakes as a first-class data type"
          spec.authors     = ["Bruce Wayne"]

          spec.metadata = {
            "source_code_uri" => "https://github.com/bwayne/fake_spec",
          }
        end
      RUBY
    end

    let(:readme) do
      <<~ORG
        #+TITLE: GemDocs Guide
        #+OPTIONS: toc:5
        #+PROPERTY: header-args:ruby :results value :colnames no :hlines yes :exports both :dir "./"
        #+PROPERTY: header-args:ruby :wrap example :session gem_docs_session
        #+PROPERTY: header-args:ruby+ :prologue "require_relative 'lib/gem_docs'" :eval yes
        #+PROPERTY: header-args:sh :exports code :eval no
        #+PROPERTY: header-args:bash :exports code :eval no

        #+BEGIN_EXPORT markdown
        [![CI](https://github.com/ddoherty03/gem_docs/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/ddoherty03/gem_docs/actions/workflows/main.yml)
        #+END_EXPORT

        * Introduction
        This gem contains ~rake~ tasks to facilitate the production of documentation
        in other gems.

        Right now, it provides tasks for:

        - running the code block examples in a ~README.org~
        - exporting ~README.org~ to Git-flavored markdown in ~README.md~
        - ensuring a workflow or ci badge is present in the ~README.md~
        - generating yard documents for your repo, and
        - copying the introductory contents of the README as a leading comment in your
          main gem library file so it gets picked up as an overview for ~ri~ and ~yri~
      ORG
    end

    around do |example|
      Dir.mktmpdir do |dir|
        root = dir
        Dir.chdir(root) do
          File.write(File.join(root, "README.org"), readme)
          File.write(File.join(root, "fake_gem.gemspec"), fake_spec)
          lib_dir = File.join(root, "lib/")
          FileUtils.mkdir_p(lib_dir)
          File.write(File.join(lib_dir, "fake_gem.rb"), main_lib)
          File.write("Gemfile", '#Empty')
          example.run
        end
      end
    end

    describe ".write_overview" do
      context "when the configured section is absent" do
        let(:main_lib) { main_lib_wo_overview }
        let(:readme) { "* ErbTeX\n** Description\nSome documentation.\n" }

        it "leaves the library unchanged across repeated runs" do
          2.times { expect(Overview.write_overview?).to be false }
          expect(File.read("lib/fake_gem.rb")).to eq(main_lib)
        end
      end

      context "when the section starts on the first line" do
        let(:main_lib) { main_lib_wo_overview }
        let(:readme) { "* Introduction\nFirst-line overview.\n" }

        it "extracts the section and remains idempotent" do
          expect(Overview.write_overview?).to be true
          expect(File.read("lib/fake_gem.rb")).to include("# First-line overview.")
          expect(Overview.write_overview?).to be false
        end
      end

      context "when legacy empty banners are duplicated" do
        let(:main_lib) { ("# #{Overview::BANNER}\n#\n\n\n" * 3) + "module FakeGem\nend\n" }

        it "replaces them with one populated overview" do
          expect(Overview.write_overview?).to be true
          contents = File.read("lib/fake_gem.rb")
          expect(contents.scan(Overview::BANNER).size).to eq(1)
          expect(contents).to include("# * Introduction")
          expect(Overview.write_overview?).to be false
        end
      end

      context "when Ruby code separates an old banner from the declaration" do
        let(:main_lib) { "# #{Overview::BANNER}\n#\nKEEP_ME = 42\nmodule FakeGem\nend\n" }

        it "preserves the intervening code" do
          Overview.write_overview?
          expect(File.read("lib/fake_gem.rb")).to include("KEEP_ME = 42")
        end
      end

      context "when there is no overview yet" do
        let(:main_lib) { main_lib_wo_overview }

        it "adds the overview to the lib file" do
          expect(Overview).not_to be_present
          expect(Overview.write_overview?).to be true
          expect(Overview).to be_present
        end
      end

      context "when the top-level constant is a class" do
        let(:main_lib) { "class FakeGem < Object\nend\n" }

        it "adds the overview without changing the class declaration" do
          expect(Overview.write_overview?).to be true
          expect(Overview).to be_present

          contents = File.read("lib/fake_gem.rb")
          expect(contents).to end_with(main_lib)
          expect { Module.new.module_eval(contents) }.not_to raise_error
        end

        it "does not duplicate an existing overview" do
          Overview.write_overview?
          expect(Overview.write_overview?).to be false
        end

        it "replaces the overview when the README changes" do
          Overview.write_overview?
          File.write("README.org", readme.sub("This gem contains", "This library contains"))

          expect(Overview.write_overview?).to be true
          contents = File.read("lib/fake_gem.rb")
          expect(contents).to include("# This library contains")
          expect(contents.scan(Overview::BANNER).size).to eq(1)
        end
      end

      context "when there is no overview or module in lib yet" do
        let(:main_lib) { main_lib_wo_module }

        it "adds the overview to the lib file" do
          expect(Overview).not_to be_present
          expect(Overview.write_overview?).to be true
          expect(Overview).to be_present
        end
      end

      context "when the overview is already present" do
        let(:main_lib) { main_lib_w_overview }

        it "does not add an additional overview" do
          expect(Overview).to be_present
          expect(Overview.write_overview?).to be false
          expect(Overview).to be_present
        end
      end
    end
  end
end
