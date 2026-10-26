# frozen_string_literal: true

require 'rake'

RSpec.describe GemDocs::Doctor do
  before do
    allow(GemDocs).to receive(:config).and_return(GemDocs::Config.new)
  end

  around do |example|
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        File.write('Gemfile', '')
        example.run
      end
    end
  end

  def diagnose
    suggestions = nil
    expect { suggestions = described_class.run }.to output(/GemDocs doctor:/).to_stdout
    suggestions.join("\n")
  end

  it 'reports missing inputs without creating them or invoking Emacs' do
    allow(GemDocs::Emacs).to receive(:tangle)
    expect(diagnose).to include('README.org: File is missing', '.yardopts: File is missing')
    expect(Dir.children('.')).to eq(['Gemfile'])
    expect(GemDocs::Emacs).not_to have_received(:tangle)
  end

  it 'does not ask a prose-only README to acquire Ruby headers' do
    File.write('README.org', "* ErbTeX\n** Description\nUseful prose.\n")
    report = diagnose
    expect(report).to include('README.org: No top-level overview section', 'README.md: File is missing')
    expect(report).not_to include('Ruby')
  end

  it 'explains protection for a Markdown-only project without adding a marker' do
    File.write('README.md', '# Written by hand')
    expect(diagnose).to include('README.md: Protected from export', GemDocs::Emacs::README_MARKER)
    expect(File.read('README.md')).to eq('# Written by hand')
  end

  it 'recognizes configured first-line headings and ignores sample configuration' do
    GemDocs.config.overview_headings = ['Overview']
    File.write('README.org', <<~ORG)
      * Overview
      Real introduction.
      #+begin_example
      #+PROPERTY: header-args:ruby :eval never-export
      #+end_example
      #+begin_src ruby
      42
      #+end_src
    ORG
    report = diagnose
    expect(report).not_to include('No top-level overview section')
    expect(report).to include('no file-level Ruby headers')
  end

  it 'reports conflicting evaluation settings without overwriting custom headers' do
    content = <<~ORG
      #+PROPERTY: header-args:ruby :eval never-export :session demo
      #+PROPERTY: header-args:ruby+ :eval yes
      * Introduction
      #+begin_src ruby
      42
      #+end_src
    ORG
    File.write('README.org', content)
    expect(diagnose).to include('conflicting :eval', 'overview section is empty')
    expect(File.read('README.org')).to eq(content)
  end

  it 'detects a stale version against the consuming gemspec' do
    File.write('example.gemspec', <<~GEMSPEC)
      Gem::Specification.new do |s|
        s.name = 'example'
        s.version = '2.0.0'
      end
    GEMSPEC
    File.write('README.org', <<~ORG)
      # gem_docs:version begin
      Version: 1.0.0
      # gem_docs:version end
      * Introduction
      Useful prose.
    ORG
    expect(diagnose).to include('README version differs from gemspec 2.0.0')
  end

  it 'runs as a standalone Rake task from a subdirectory without creating a skeleton' do
    previous = Rake.application
    begin
      Rake.application = Rake::Application.new
      GemDocs.install
      FileUtils.mkdir_p('lib')
      Dir.chdir('lib') do
        expect { Rake::Task['docs:doctor'].invoke }.to output(/README.org: File is missing/).to_stdout
      end
      expect(File).not_to exist('README.org')
      expect(File).not_to exist('lib/README.org')
    ensure
      Rake.application = previous
    end
  end

  it 'checks tracked and ignored YARD output using Git rules' do
    system('git', 'init', '-q')
    FileUtils.mkdir_p(%w[doc .yardoc])
    File.write('doc/index.html', 'generated')
    File.write('.gitignore', "/.yardoc/\n")
    system('git', 'add', 'doc/index.html')
    report = diagnose
    expect(report).to include('doc/: Contains tracked generated YARD files')
    expect(report).not_to include('Add /.yardoc/')
  end
end
