# frozen_string_literal: true

require_relative "gem-docs/version"
require_relative "gem-docs/tasks"

# Rake tasks for generating documentation for gems.
module GemDocs
end

# Install tasks when loaded via a Rakefile
GemDocs.install if defined?(Rake)
