#!/bin/sh

unset GEM_HOME
unset GEM_PATH
export PATH=~/.rbenv/bin:"$PATH"

~/.rbenv/shims/ruby main.rb
