# vim-go

A small plugin that I wrote to capture useful commands when working in go. 

Pre-requisites:
* [vim-dispatch](https://github.com/tpope/vim-dispatch)

## Installation

Install using your favorite package manager, or use Vim's built-in package support:

```
mkdir -p ~/.vim/pack/plugin/start
cd ~/.vim/pack/plugin/start
git clone https://github.com/joe-mcgovern/vim-go.git
vim -u NONE -c "helptags bowlcut/doc" -c q
```

## Usage

### `run`

You can run the current package via:

* `<leader>grp` (go run package)
* `:GoRun`
* `:GoRun <args>`

#### Persist args

You can also set an arg string in the buffer if you are testing the binary and
want the same set of args to be applied each time:

`let b:go_run_args="--arg1 foo --arg2 bar"`

Then,

`:GoRun`

### `test`

You can test the current package via:

* `<leader>gtp` (go test package)
* `:GoTest`

#### Test nearest

You can filter the tests to only execute the test function closest to your cursor via:

* `<leader>gtn` (go test nearest)
* `:GoTestNearest`

### New test

Get a boilerplate for a table-driven test by calling:

* `<leader>gnt`
* `GoNewTest`


### Copy package path

Copy the current package path by running:

* `<leader>gyp`
* `GoYankPackage`
