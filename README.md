- [Overview](#org6fa68fe)
- [Installation](#org3eb99b0)
- [Usage](#org4ed5022)
  - [Update Your `Rakefile`](#org3a7a52f)
  - [Generate `README.md` from `README.org`](#org614f3c8)
  - [Run the Code Blocks in README.org](#orgae2b8ab)
- [Development](#orga61b0b7)
- [Contributing](#org46baac6)
  - [License](#org2cc6ec2)



<a id="org6fa68fe"></a>

# Overview

This gem contains `rake` tasks to facilitate the production of documentation in other gems.

Right now, it provides tasks for running all the code blocks in a `README.org` file and a task for exporting `README.org` to Git-flavored markdown in `README.md`


<a id="org3eb99b0"></a>

# Installation

Install the gem and add to the application's `Gemfile` by executing:

```sh
bundle add gem_docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install gem_docs
```


<a id="org4ed5022"></a>

# Usage


<a id="org3a7a52f"></a>

## Update Your `Rakefile`

To use this gem place the following lines in your gem's `Rakefile`:

```ruby
require "gem_docs"
GemDocs.install
```


<a id="org614f3c8"></a>

## Generate `README.md` from `README.org`

Now, you can write the `README` in Emacs org-mode, using all its features including the execution of code blocks, and then export to git-flavored markdown.

Github renders markdown better that it renders org files, so this helps with the readability of the README on github.

```ruby
rake docs:readme
```


<a id="orgae2b8ab"></a>

## Run the Code Blocks in README.org

You can invoke `emacsclient` to run all the examples in your `README.org` that are set for evaluation:

```ruby
rake docs:examples
```


<a id="orga61b0b7"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and the created tag, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="org46baac6"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/gem-docs>.


<a id="org2cc6ec2"></a>

## License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
