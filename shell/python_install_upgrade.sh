#!/bin/sh
# on os x
brew install python
brew unlink python && brew link python

pip3 insall ansible
