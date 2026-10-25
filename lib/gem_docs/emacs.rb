# frozen_string_literal: true

module GemDocs
  module Emacs
    class Error < StandardError; end

    def self.tangle
      path = File.expand_path(README_ORG, GemDocs.project_root)
      # A conservative fast path: leave header inheritance and eligibility to Org.
      unless File.read(path).match?(/#\+begin_src\b|#\+call:|\bsrc_\w+|\bcall_\w+/i)
        puts "Skipped: no executable code blocks"
        return
      end

      expr = <<~ELISP
        (with-current-buffer (find-file-noselect #{path.dump})
          (save-buffer)
          (require 'ob-ruby)
          (let ((eligible nil))
            (let ((org-confirm-babel-evaluate nil))
              (org-babel-map-executables nil
                (let ((info (org-babel-get-src-block-info 'light)))
                  (when (or (null info) (org-babel-check-confirm-evaluate info))
                    (setq eligible t)))))
            (if (not eligible)
                "Skipped: no evaluable code blocks"
              (let ((session (get-buffer #{session_name.dump})))
                (when session
                  (let ((process (get-buffer-process session)))
                    (when process (set-process-query-on-exit-flag process nil)))
                  (kill-buffer session)))
              (org-babel-execute-buffer)
              (save-buffer)
              "Babel execution complete")))
      ELISP

      run(expr, "Babel execution")
    end

    def self.export_readme
      export(README_ORG)
    end

    def self.export_changelog
      export(CHANGELOG_ORG)
    end

    def self.session_name
      "*#{Repo.from_gemspec.name}_session*"
    end

    class << self
      private

      def export(filename)
        path = File.expand_path(filename, GemDocs.project_root)
        raise Error, "Cannot export missing file: #{path}" unless File.file?(path)

        expr = <<~ELISP
          (with-current-buffer (find-file-noselect #{path.dump})
            (save-buffer)
            (require 'ox-gfm)
            (org-gfm-export-to-markdown)
            #{"Export #{filename} complete".dump})
        ELISP
        run(expr, "Export #{filename}")
      end

      def run(expr, operation)
        seconds = Float(GemDocs.config.emacs_timeout)
        raise ArgumentError,
              "emacs_timeout must be a positive, finite number" unless seconds.positive? && seconds.finite?

        # Fail on prompts rather than leaving emacsclient waiting in the background.
        wrapped = <<~ELISP
          (progn
            (require 'cl-lib)
            (save-window-excursion
              (cl-letf (((symbol-function 'yes-or-no-p)
                         (lambda (&rest args)
                           (error "GemDocs requires interactive confirmation: %s. Run this operation in Emacs first" (car args))))
                        ((symbol-function 'y-or-n-p)
                         (symbol-function 'yes-or-no-p)))
                (with-timeout (#{seconds} (error "GemDocs timed out: #{operation}"))
                  #{expr}))))
        ELISP
        pid = Process.spawn("emacsclient", "--quiet", "--eval", wrapped)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
        loop do
          result = Process.waitpid2(pid, Process::WNOHANG)
          if result
            pid = nil
            unless result.last.success?
              raise Error,
                    "#{operation} failed (emacsclient exit #{result.last.exitstatus.inspect}); see Emacs output above"
            end

            return true
          end
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            raise Error,
                  "#{operation} timed out after #{seconds}s. " \
                    "The Emacs server may still be executing; inspect it before retrying."
          end

          sleep 0.05
        end
      rescue Errno::ENOENT
        raise Error, "#{operation} failed: emacsclient was not found"
      ensure
        if pid
          begin
            Process.kill("KILL", pid)
          rescue Errno::ESRCH
            # The client exited between the timeout and cleanup.
          end
          Process.waitpid(pid)
        end
      end
    end
  end
end
