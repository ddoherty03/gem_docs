- [Overview](#orga49241f)
- [Installation](#org6a44949)
  - [Install the gem](#orgfcd20ce)
  - [Update Your `Rakefile`](#org2520e33)
- [Usage](#orgaf33a08)
  - [Generate `README.md` from `README.org`](#org99acf8a)
  - [Run the Code Blocks in README.org](#org8031be9)
  - [Generate an Overview Comment for the Main gem File](#orgc9be2fa)
- [Development](#orgc93ec55)
- [Contributing](#orgd73c1ad)
- [License](#orga827c7f)



<a id="orga49241f"></a>

# Overview

This gem contains `rake` tasks to facilitate the production of documentation in other gems.

Right now, it provides tasks for:

-   running the code block examples in a `README.org`
-   exporting `README.org` to Git-flavored markdown in `README.md`
-   generating yard documents for your repo, and
-   copying the introductory contents of the README as a leading comment in your main gem library file so it gets picked up as an overview for `ri` and `yri`


<a id="org6a44949"></a>

# Installation


<a id="orgfcd20ce"></a>

## Install the gem

Install the gem and add to the application's `Gemfile` by executing:

```sh
bundle add gem_docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install gem_docs
```


<a id="org2520e33"></a>

## Update Your `Rakefile`

To use this gem place the following lines in your gem's `Rakefile`:

```ruby
require "gem_docs"
GemDocs.install
```


<a id="orgaf33a08"></a>

# Usage


<a id="org99acf8a"></a>

## Generate `README.md` from `README.org`

Now, you can write the `README` in Emacs org-mode, using all its features including the execution of code blocks, and then export to git-flavored markdown.

Github renders markdown better that it renders org files, so this helps with the readability of the README on github.

```ruby
rake docs:readme
```


<a id="org8031be9"></a>

## Run the Code Blocks in README.org

You can invoke `emacsclient` to run all the examples in your `README.org` that are set for evaluation:

```ruby
rake docs:examples
```


<a id="orgc9be2fa"></a>

## Generate an Overview Comment for the Main gem File

Gem's typically gather into a central library file all the require's and other setup needed for the gem and the file is given the same name as the gem. For example, this gem uses the file `lib/gem_docs.rb` for this purpose. Since this `lib` directory is placed in the user's `LOADPATH`, a `require 'gem_docs'` or `require '<gemname>'` effectively initializes the gem.

By convention the first comment after the preliminary comments (such as `# frozen-string: true`) is used by `ri` as the overview for the gem.


<a id="orgc93ec55"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and the created tag, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="orgd73c1ad"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/gem-docs>.


<a id="orga827c7f"></a>

# License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
