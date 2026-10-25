# frozen_string_literal: true

RSpec.describe GemDocs do
  it "has a version number" do
    expect(GemDocs::VERSION).not_to be_nil
  end

  describe ".project_root" do
    around do |example|
      Dir.mktmpdir do |root|
        Dir.chdir(root) { example.run }
      end
    end

    ["Gemfile", "example.gemspec"].each do |marker|
      it "finds an ancestor containing #{marker} without changing directories" do
        root = Dir.pwd
        File.write(marker, "")
        FileUtils.mkdir_p("lib/nested")

        Dir.chdir("lib/nested") do
          working_directory = Dir.pwd
          expect(GemDocs.project_root).to eq(root)
          expect(Dir.pwd).to eq(working_directory)
        end
      end
    end

    it "uses the nearest project marker" do
      File.write("Gemfile", "")
      FileUtils.mkdir_p("nested/lib")
      File.write("nested/example.gemspec", "")
      expected_root = File.expand_path("nested")

      Dir.chdir("nested/lib") do
        expect(GemDocs.project_root).to eq(expected_root)
      end
    end

    it "loads repository metadata from a subdirectory" do
      root = Dir.pwd
      File.write("example.gemspec", <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "example"
          spec.version = "1.0.0"
          spec.homepage = "https://github.com/example/example"
        end
      RUBY
      FileUtils.mkdir_p("lib/nested")

      Dir.chdir("lib/nested") do
        repo = GemDocs::Repo.from_gemspec
        expect(repo.root).to eq(root)
        expect(repo.name).to eq("example")
      end
    end
  end
end
