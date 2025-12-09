- [Overview](#org37778a1)
- [Contents](#org8ded922)
- [Installation](#orgf945cb5)
  - [Install the gem](#org49fb64e)
  - [Update Your `Rakefile`](#org8404b2f)
- [Usage](#orgc2f661a)
  - [Generate `README.md` from `README.org`](#org7cb65a8)
  - [Run the Code Blocks in README.org](#org62ed5b7)
- [Development](#orga97c6fc)
- [Contributing](#orgf840198)
- [License](#org0a1a9e1)



<a id="org37778a1"></a>

# Overview

This gem contains `rake` tasks to facilitate the production of documentation in other gems.

Right now, it provides tasks for:

-   running the code block examples in a `README.org`
-   exporting `README.org` to Git-flavored markdown in `README.md`
-   generating yard documents for your repo, and
-   copying the introductory contents of the README as a leading comment in your main gem library file so it gets picked up as an overview for `ri` and `yri`


<a id="org8ded922"></a>

# Contents     :toc:

-   
-   -   
    -
-   -   
    -
-   
-   
-   


<a id="orgf945cb5"></a>

# Installation


<a id="org49fb64e"></a>

## Install the gem

Install the gem and add to the application's `Gemfile` by executing:

```sh
bundle add gem_docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install gem_docs
```


<a id="org8404b2f"></a>

## Update Your `Rakefile`

To use this gem place the following lines in your gem's `Rakefile`:

```ruby
require "gem_docs"
GemDocs.install
```


<a id="orgc2f661a"></a>

# Usage


<a id="org7cb65a8"></a>

## Generate `README.md` from `README.org`

Now, you can write the `README` in Emacs org-mode, using all its features including the execution of code blocks, and then export to git-flavored markdown.

Github renders markdown better that it renders org files, so this helps with the readability of the README on github.

```ruby
rake docs:readme
```


<a id="org62ed5b7"></a>

## Run the Code Blocks in README.org

You can invoke `emacsclient` to run all the examples in your `README.org` that are set for evaluation:

```ruby
rake docs:examples
```


<a id="orga97c6fc"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and the created tag, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="orgf840198"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/gem-docs>.


<a id="org0a1a9e1"></a>

# License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
