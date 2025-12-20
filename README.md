- [Overview](#org26cae4e)
- [Installation](#org374b0dd)
  - [Install the gem](#org9059b80)
  - [Update Your `Rakefile`](#org7dd0544)
- [Usage](#org170c429)
  - [Run the Code Blocks in README.org: \`rake docs:tangle\`](#org3520309)
  - [Ensure that a Badge is Present in `README.md`: \`rake docs:badge\`](#org8dac174)
  - [Export `README.org` to `README.md`: \`rake docs:export\`](#orgf7390a4)
  - [Generate Yard Documents: \`rake docs:yard\`](#org1e5514a)
  - [Generate an Overview Comment for the Main gem File: \`rake docs:overview\`](#orgc930a0c)
- [Development](#orgf1926fe)
- [Contributing](#org516db35)
- [License](#org216c105)

[![CI](https://github.com/ddoherty03/actions/workflows/main.yml/badge.svg)](
https://github.com/ddoherty03/actions/workflows/main.yml
)


<a id="org26cae4e"></a>

# Overview

This gem contains `rake` tasks to facilitate the production of documentation in other gems.

Right now, it provides tasks for:

-   running the code block examples in a `README.org`
-   exporting `README.org` to Git-flavored markdown in `README.md`
-   ensuring a workflow or ci badge is present in the `README.md`
-   generating yard documents for your repo, and
-   copying the introductory contents of the README as a leading comment in your main gem library file so it gets picked up as an overview for `ri` and `yri`


<a id="org374b0dd"></a>

# Installation


<a id="org9059b80"></a>

## Install the gem

Install the gem and add to the application's `Gemfile` by executing:

```sh
bundle add gem_docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install gem_docs
```


<a id="org7dd0544"></a>

## Update Your `Rakefile`

To use this gem place the following lines in your gem's `Rakefile`:

```ruby
require "gem_docs"
GemDocs.install
```


<a id="org170c429"></a>

# Usage


<a id="org3520309"></a>

## Run the Code Blocks in README.org: \`rake docs:tangle\`

You can invoke `emacsclient` to run all the example code blocks in your `README.org` that are set for evaluation:

Note that the `tangle` task relies on `emacsclient` to evaluate the code blocks in `README.org`, so your Emacs `init` files should start [the Emacs server](info:emacs#Emacs Server) in order to work properly.

```ruby
rake docs:tangle
```


<a id="org8dac174"></a>

## Ensure that a Badge is Present in `README.md`: \`rake docs:badge\`

It is reassuring to consumers of your gem that you gem passes its workflow tests. This task checks to see if a "badge" indicating success or failure is present and, if not, inserts one at the top of the `README.org` such that it will get exported to `README.md` when `rake docs:export` is run.

If you want to place the badge somewhere else in you `README.org`, place the special comment `#badge` where you want the badge located and the task will place it there.

If there is already a badge present, the task will not modify the `README.org` file.


<a id="orgf7390a4"></a>

## Export `README.org` to `README.md`: \`rake docs:export\`

You can write the `README` in Emacs org-mode, using all its features including the execution of code blocks, and then export to git-flavored markdown.

Github renders markdown better than it renders org files, so this helps with the readability of the `README` on github. For example, if you write the `README` in org mode without exporting to markdown, `github` will not render the `#+RESULTS` blocks unless you manually delete the `#+RESULTS` tag from the output. This is tedious and error-prone, so it is best that you write the `README` in `org-mode` and export to `markdown`. That's what this task enables.

Also note that when `github` renders your `README.md`, it automatically adds a table of contents, so putting one in the `README.org` file is redundant. If you want to have one for your own purposes, just set the `:noexport` tag on it so it doesn't get put into the `README.md`

```ruby
rake docs:export
```


<a id="org1e5514a"></a>

## Generate Yard Documents: \`rake docs:yard\`

This task generates a suitable `.yardopts` file if none exists and then generates `yard` documents into the gem's `doc` directory. It also makes sure that `yard` knows about your `README.md` file so user's of your gem will be able to get an overview of how to use your gem.

```ruby
rake docs:yard
```


<a id="orgc930a0c"></a>

## Generate an Overview Comment for the Main gem File: \`rake docs:overview\`

Gem's typically gather into a central library file all the require's and other setup needed for the gem and the file is given the same name as the gem. For example, this gem uses the file `lib/gem_docs.rb` for this purpose. Since this `lib` directory is placed in the user's `LOADPATH`, a `require 'gem_docs'` or `require '<gemname>'` effectively initializes the gem.

By convention the first comment after the preliminary comments (such as `# frozen-string: true`) is used by `ri` as the overview for the gem.

```ruby
rake docs:overview
```


<a id="orgf1926fe"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`.


<a id="org516db35"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/gem-docs>.


<a id="org216c105"></a>

# License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
