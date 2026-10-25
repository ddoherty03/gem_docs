# frozen_string_literal: true

require 'rbconfig'

RSpec.describe GemDocs::Emacs do
  before do
    allow(GemDocs).to receive(:config).and_return(GemDocs::Config.new)
  end

  describe 'client failure handling' do
    it 'raises on an unsuccessful client exit' do
      pid = Process.spawn(RbConfig.ruby, '-e', 'exit 7')
      allow(Process).to receive(:spawn).and_return(pid)
      expect { described_class.send(:run, 'nil', 'Export README.org') }
        .to raise_error(GemDocs::Emacs::Error, /Export README.org failed.*exit 7/)
    end

    it 'reports a missing emacsclient' do
      allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)
      expect { described_class.send(:run, 'nil', 'Export README.org') }
        .to raise_error(GemDocs::Emacs::Error, /emacsclient was not found/)
    end

    it 'times out and reaps the client process' do
      GemDocs.config.emacs_timeout = 0.1
      pid = Process.spawn(RbConfig.ruby, '-e', 'sleep 60')
      allow(Process).to receive(:spawn).and_return(pid)
      expect { described_class.send(:run, 'nil', 'Babel execution') }
        .to raise_error(GemDocs::Emacs::Error, /timed out.*server may still be executing/)
      expect { Process.waitpid(pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    end

    it 'rejects a nonpositive timeout before starting the client' do
      GemDocs.config.emacs_timeout = 0
      allow(Process).to receive(:spawn)
      expect { described_class.send(:run, 'nil', 'Babel execution') }
        .to raise_error(ArgumentError, /emacs_timeout/)
      expect(Process).not_to have_received(:spawn)
    end
  end

  describe 'Org execution in an isolated batch Emacs' do
    around do |example|
      Dir.mktmpdir do |root|
        Dir.chdir(root) do
          File.write('Gemfile', '')
          example.run
        end
      end
    end

    before do
      allow(described_class).to receive(:session_name).and_return('*gem_docs_test_session*')
      allow(Process).to receive(:spawn).and_wrap_original do |original, *args|
        # Use actual Org parsing without touching the user's Emacs server.
        load_path = ENV.fetch('GEM_DOCS_TEST_EMACS_LOAD_PATH', '').split(File::PATH_SEPARATOR)
        original.call(
          'emacs',
          '--batch',
          '-Q',
          *load_path.flat_map { |path| ['-L', path] },
          '--eval',
          '(progn (require \'org) (setq org-confirm-babel-evaluate nil))',
          '--eval',
          args.last,
          out: File::NULL,
          err: File::NULL,
        )
      end
    end

    it 'skips a README with no executable syntax without starting Emacs' do
      File.write('README.org', "* Introduction\nJust prose.\n")
      expect { described_class.tangle }.to output(/Skipped/).to_stdout
      expect(Process).not_to have_received(:spawn)
    end

    it 'skips blocks disabled by inherited and local headers' do
      readme = <<~ORG
        #+PROPERTY: header-args:emacs-lisp :eval never

        * Examples
        #+begin_src emacs-lisp
        (error "must not execute")
        #+end_src
        #+begin_src emacs-lisp :eval no
        (error "must not execute either")
        #+end_src
      ORG
      File.write('README.org', readme)
      expect(described_class.tangle).to be true
      expect(File.read('README.org')).to eq(readme)
    end

    it 'executes a local override and a never-export block in document order' do
      File.write('README.org', <<~ORG)
        #+PROPERTY: header-args:emacs-lisp :eval never

        * Examples
        #+begin_src emacs-lisp :eval yes
        (setq gem-docs-test-value 40)
        #+end_src
        #+begin_src emacs-lisp :eval never-export
        (+ gem-docs-test-value 2)
        #+end_src
      ORG
      expect(described_class.tangle).to be true
      expect(File.read('README.org')).to include(': 40', ': 42')
    end

    it 'fails promptly when a block explicitly requires confirmation' do
      File.write('README.org', <<~ORG)
        #+begin_src emacs-lisp :eval query
        (error "must not execute")
        #+end_src
      ORG
      expect { described_class.tangle }.to raise_error(GemDocs::Emacs::Error, /Babel execution failed/)
    end

    context 'with ox-gfm available' do
      before do
        skip 'Set GEM_DOCS_TEST_EMACS_LOAD_PATH to the ox-gfm directory' unless ENV['GEM_DOCS_TEST_EMACS_LOAD_PATH']
      end

      it 'exports the badge and saved results from a subdirectory without creating a changelog' do
        File.write('README.org', <<~ORG)
          #+TITLE: Examples
          #+BEGIN_EXPORT markdown
          [![CI](https://example.com/badge.svg)](https://example.com/workflow)
          #+END_EXPORT

          #+begin_src emacs-lisp :eval never :exports both
          (+ 40 2)
          #+end_src

          #+RESULTS:
          : 42
        ORG
        FileUtils.mkdir_p('lib/nested')
        Dir.chdir('lib/nested') { described_class.export_readme }

        markdown = File.read('README.md')
        expect(markdown).to include('[![CI](https://example.com/badge.svg)](https://example.com/workflow)')
        expect(markdown).to include('(+ 40 2)', '42')
        expect(File).not_to exist('CHANGELOG.org')
        expect(File).not_to exist('CHANGELOG.md')
      end

      it 'exports the changelog independently' do
        File.write('CHANGELOG.org', "* Changes\nFixed exports.\n")
        described_class.export_changelog
        expect(File.read('CHANGELOG.md')).to include('Fixed exports.')
        expect(File).not_to exist('README.org')
      end

      it 'propagates evaluation errors during export' do
        File.write('README.org', <<~ORG)
          #+begin_src emacs-lisp :eval yes :exports results
          (error "broken example")
          #+end_src
        ORG
        expect { described_class.export_readme }
          .to raise_error(GemDocs::Emacs::Error, /Export README.org failed/)
      end
    end
  end
end
