# Exports a hash of all defined pages
# Usage:
# HomeView = require("pages").home

items = {}

if window?
    thisDir = module.id.replace(/\/[^\/]*$/,'/')
    for name in window.require.list() when name.indexOf(thisDir) is 0
        continue if name is module.id # skip this file

        # only include whole subdirs with index files
        if name.match(/\/index$/)
            itemName = name.replace(/^pages\//, '').replace(/\/index$/, '')
            items[itemName] = require(name)

else
    fs = require("fs")
    itemFiles = fs.readdirSync(__dirname)
    for filename in itemFiles
        continue if filename[0] is '.' # skip dot-files
        continue if filename is 'index.coffee' # skip this file

        itemName = filename.replace(/\..*$/, '') # remove extension
        items[itemName] = require('./'+filename)

module.exports = items
