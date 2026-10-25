# frozen_string_literal: true

module GemDocs
  RSpec.describe Skeleton do
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
      <<~README
        #+TITLE: FakeGem Guide

        * Introduction
        You're gonna love it!
      README
    end

    let(:add_readme) { false }

    around do |example|
      Dir.mktmpdir do |dir|
        root = dir
        Dir.chdir(root) do
          File.write(File.join(root, "README.org"), readme) if add_readme
          File.write(File.join(root, "fake_gem.gemspec"), fake_spec)
          # lib_dir = File.join(root, "lib/")
          # FileUtils.mkdir_p(lib_dir)
          # File.write(File.join(lib_dir, "fake_gem.rb"), main_lib)
          File.write("Gemfile", '#Empty')
          example.run
        end
      end
    end

    describe ".make_readme?" do
      context "when there is no README.org yet" do
        it "adds README.org the repo" do
          expect(Skeleton).not_to be_readme_present
          expect(Skeleton.make_readme?).to be true
          expect(Skeleton).to be_readme_present
          expect(File.read("README.org")).to include("Version: 0.9.10")
          expect(File.read("README.org")).to include(":session fake_gem_session :eval never-export")
          expect(Header.write_header?).to be false
          expect(Skeleton.make_readme?).to be false
        end
      end

      context "when the overview is already present" do
        let(:add_readme) { true }

        it "adds the version without replacing existing content and is idempotent" do
          expect(Skeleton).to be_readme_present
          expect(Skeleton.make_readme?).to be true
          written = File.read("README.org")
          expect(written).to include("Version: 0.9.10", "You're gonna love it!")
          expect(Skeleton.make_readme?).to be false
          expect(File.read("README.org")).to eq(written)
        end

        it "refreshes the version after the consuming gemspec changes" do
          Skeleton.make_readme?
          File.write("fake_gem.gemspec", fake_spec.sub('0.9.10', '0.10.0.pre.1'))
          # A new rake invocation starts without RubyGems' loaded gemspec cache.
          Gem::Specification.reset

          expect(Skeleton.make_readme?).to be true
          written = File.read("README.org")
          expect(written).to include("Version: 0.10.0.pre.1", "You're gonna love it!")
          expect(written).not_to include("Version: 0.9.10")
          expect(written.scan("# gem_docs:version begin").size).to eq(1)
        end

        it "refreshes the version through the rake skeleton task" do
          require "rake"
          original_application = Rake.application
          begin
            Rake.application = Rake::Application.new
            GemDocs.install
            expect { Rake::Task["docs:skeleton:readme"].invoke }.to output(/version updated/).to_stdout
            expect(File.read("README.org")).to include("Version: 0.9.10")
          ensure
            Rake.application = original_application
          end
        end
      end
    end
  end
end
