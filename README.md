- [Overview](#orgd52888f)
- [Installation](#orgd5bbede)
  - [Install the ox-gfm Emacs package](#org3920409)
  - [Install the gem](#org0f218e1)
  - [Update Your `Rakefile`](#org40cbe96)
- [Usage](#org32113b7)
  - [Add proper `#+PROPERTY` headers in `README.org`: \`rake docs:headers\`](#orgff01eed)
  - [Run the Code Blocks in README.org: \`rake docs:tangle\`](#org7672d93)
  - [Ensure that a Badge is Present in `README.md`: \`rake docs:badge\`](#orgc5383ea)
  - [Export `README.org` to `README.md`: \`rake docs:export\`](#orge84f0cd)
  - [Generate Yard Documents: \`rake docs:yard\`](#org3bffbc8)
  - [Generate an Overview Comment for the Main gem File: \`rake docs:overview\`](#org4588c51)
- [Development](#orgf0cd137)
- [Contributing](#org68546e5)
- [License](#orgb7f51cd)

[![CI](https://github.com/ddoherty03/gem_docs/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/ddoherty03/gem_docs/actions/workflows/main.yml)


<a id="orgd52888f"></a>

# Overview

One of the more onerous tasks when writing a `gem` or other `github` project is maintaining the documentation, and keeping it consistent and up-to-date. One of the better options for writing the `README` file that gets displayed by `github` as the main documentation is to write the file in `org-mode`, `README.org` the export it to markdown `README.md` for display by `github`.

Doing so gives you access to `org-mode`'s code blocks for writing example code to demonstrate the `gem` or other documents being presented. If you do so, `github` will render your `README.org` file in `HTML` and give you a credible result. However, `github` cannot handle some `org-mode` features, and in particular, it will not render `'#+RESULTS` blocks showing the results of code block execution unless you wrap the results in something like a `#+begin_example` block and manually delete the `'#+RESULTS` markers. Exporting to markdown eliminates that hassle.

This gem contains `rake` tasks to facilitate the production of documentation in other gems.

It provides tasks for:

-   ensuring that proper code block setup is included in `README.org` to facilitate running `ruby` code blocks in a session using the current version of the library,
-   running the code block examples in a `README.org` by invoking `emacsclient`,
-   exporting `README.org` to Git-flavored markdown in `README.md`
-   ensuring a workflow or ci badge is present in the `README.md`
-   generating yard documents for your repo, and
-   copying the introductory contents of the README as a leading comment in your main gem library file so it gets picked up as an overview for `ri` and `yri`


<a id="orgd5bbede"></a>

# Installation


<a id="org3920409"></a>

## Install the ox-gfm Emacs package

The export of `README.org` to `README.md` requires the `ox-gfm` package to be installed in Emacs. If you use `use-package`, this will suffice:

```emacs-lisp
(use-package ox-gfm)
```


<a id="org0f218e1"></a>

## Install the gem

Install the gem and add to the application's `Gemfile` by executing:

```sh
bundle add gem_docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install gem_docs
```


<a id="org40cbe96"></a>

## Update Your `Rakefile`

To use this gem place the following lines in your gem's `Rakefile`:

```ruby
require "gem_docs"
GemDocs.install
```


<a id="org32113b7"></a>

# Usage


<a id="orgff01eed"></a>

## Add proper `#+PROPERTY` headers in `README.org`: \`rake docs:headers\`


<a id="org7672d93"></a>

## Run the Code Blocks in README.org: \`rake docs:tangle\`

You can invoke `emacsclient` to run all the example code blocks in your `README.org` that are set for evaluation:

Note that the `tangle` task relies on `emacsclient` to evaluate the code blocks in `README.org`, so your Emacs `init` files should start [the Emacs server](info:emacs#Emacs Server) in order to work properly.

```ruby
rake docs:tangle
```


<a id="orgc5383ea"></a>

## Ensure that a Badge is Present in `README.md`: \`rake docs:badge\`

It is reassuring to consumers of your gem that you gem passes its workflow tests. This task checks to see if a "badge" indicating success or failure is present and, if not, inserts one at the top of the `README.org` such that it will get exported to `README.md` when `rake docs:export` is run.

If you want to place the badge somewhere else in you `README.org`, place the special comment `#badge` where you want the badge located and the task will place it there.

If there is already a badge present, the task will not modify the `README.org` file.


<a id="orge84f0cd"></a>

## Export `README.org` to `README.md`: \`rake docs:export\`

You can write the `README` in Emacs org-mode, using all its features including the execution of code blocks, and then export to git-flavored markdown.

Github renders markdown better than it renders org files, so this helps with the readability of the `README` on github. For example, if you write the `README` in org mode without exporting to markdown, `github` will not render the `#+RESULTS` blocks unless you manually delete the `#+RESULTS` tag from the output. This is tedious and error-prone, so it is best that you write the `README` in `org-mode` and export to `markdown`. That's what this task enables.

Also note that when `github` renders your `README.md`, it automatically adds a table of contents, so putting one in the `README.org` file is redundant. If you want to have one for your own purposes, just set the `:noexport` tag on it so it doesn't get put into the `README.md`

```ruby
rake docs:export
```


<a id="org3bffbc8"></a>

## Generate Yard Documents: \`rake docs:yard\`

This task generates a suitable `.yardopts` file if none exists and then generates `yard` documents into the gem's `doc` directory. It also makes sure that `yard` knows about your `README.md` file so user's of your gem will be able to get an overview of how to use your gem.

```ruby
rake docs:yard
```


<a id="org4588c51"></a>

## Generate an Overview Comment for the Main gem File: \`rake docs:overview\`

Gem's typically gather into a central library file all the require's and other setup needed for the gem and the file is given the same name as the gem. For example, this gem uses the file `lib/gem_docs.rb` for this purpose. Since this `lib` directory is placed in the user's `LOADPATH`, a `require 'gem_docs'` or `require '<gemname>'` effectively initializes the gem.

By convention the first comment after the preliminary comments (such as `# frozen-string: true`) is used by `ri` as the overview for the gem.

```ruby
rake docs:overview
```


<a id="orgf0cd137"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`.


<a id="org68546e5"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/gem-docs>.


<a id="orgb7f51cd"></a>

# License

The gem is available as open source under the terms of the [MIT License](<https://opensource.org/licenses/MIT>).
