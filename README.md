# Zodiac

Developmental [Express](http://expressjs.com/) server with [Brunch](http://brunch.io) frontend and [Riak](http://basho.com/riak/) backend

## Install

### Debian

**Step 1.** Update apt-get

    apt-get update

**Step 2.** Make sure that `curl`, `make`, `gcc`/`g++`, and `git` are installed

    apt-get install curl
    apt-get install make
    apt-get install build-essential
    apt-get install git

**Step 3.** Install node.js and npm

    echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
    apt-get install nodejs-legacy
    curl https://npmjs.org/install.sh | sh

**Step 4.** Grab the framework

    git clone https://github.com/DestinationSoftware/stacktest.git
    cd stacktest

**Step 5.** Install dependencies with npm and bower (***DO NOT RUN AS SUDO***)

    npm install

**Step 6.** Set up `.env` file and append `node_modules/.bin` to path

    echo NODE_ENV=development > .env
    export PATH=$PATH:node_modules/.bin

**Step 7.** Launch

    cake develop

## Code Style Guide

Reusable components should be broken into separate repositories that can be installed by `npm` or `bower`.

When parentheses or braces are optional, use them.

Filenames should be in `kebab-case`. JavaScript symbol names and properties should be in `camelCase`. JavaScript Class constructors should be in `UpperCamelCase`. CSS class names should be in `kebab-case`. Environment variables should be in `ALL_CAPS`.

Most server modules should export a singleton. Most client modules should export a class constructor.

### Custom Backbone Events

- `render:before` - triggered each time a view begins rendering
- `render:after` - triggered each time a view finishes rendering
- `hydrate` - triggered on a view once when it has attached to a DOM element after being transmitted and instantiated separately
- `filter` - triggered on a collection when a its `filterCond` has been updated

### Load order / file support
```
[                  /server/index.js                           ]
[ spdy-server.coffee or http-server.coffee |  cluster.coffee  ]
[            express-app.coffee            |__________________]
[resource.coffee | error-handler.coffee | dust-renderer.coffee]
[_______________________________________| dust-helpers.coffee ]
[                                       | layout.dust         ]
[                                       | {model-based views} ]
```
### Directory Organization

[.env](.env) - specify development environment variables
[Cakefile](Cakefile) - run tasks in the specified environment with `cake`
[Procfile](Procfile) - define production tasks
[scripts/](scripts/) - tasks that don't fit in the Cakefile
[generators/](generators/) - scaffolds for use with `scaffolt`

[package.json](package.json) - specify server libraries for installation with `npm`
[node_modules/](node_modules/) - installed server libraries
[server/](server/index.html) - original backend source code

[config.coffee](config.coffee) - `brunch` configuration
[bower.json](bower.json) - specify client libraries for installation with `bower`
[bower_components/](bower_components/) - installed client libraries
[client/](client/) - original frontend source code
[build/](build/) - compiled frontend

## Documentation

### Build Tools

You may wish to install some of these globally with `npm install -g`

- [Cake](http://coffeescript.org/documentation/docs/cake.html) - Task runner. Run `cake` with no arguments to see a list of supported tasks.
- [NPM](https://npmjs.org/doc/cli/npm.html) - Node Package Manager
- [Bower](http://twitter.github.com/bower/) - Web component manager
- [Scaffolt](https://github.com/paulmillr/scaffolt) - Module generator
- [Brunch](http://brunch.io/) - Web app assembler

### Backend Frameworks (installed in `node_modules/`)

- [Express](http://expressjs.com/) - Middleware-oriented asynchronous web server
based on [Connect](http://www.senchalabs.org/connect/)
- [Mocha](http://visionmedia.github.com/mocha/) - Unit testing
- [Riak-js](http://riakjs.com/) - Client for [Riak](http://docs.basho.com/riak/latest/dev/references/http/)
- [Passport](http://passportjs.org/) - Authentication

### Frontend Frameworks (installed in `bower_components/`)

- [jQuery](http://api.jquery.com/) - DOM manipulation and AJAX
- [Lodash](http://lodash.com/docs) - Functional programming utilities based on [Underscore](http://underscorejs.org/)
- [Backbone](http://backbonejs.org/) - Data transport modeling and event binding
- [Dust](http://akdubya.github.io/dustjs/) - Asynchronous templates
- [Rivets](http://rivetsjs.com/) - Reactive data binding, used for declaratively specifying behavior of view elements
- [Font Awesome](http://fortawesome.github.com/Font-Awesome/) - Icon font
- [Bourbon Neat](http://neat.bourbon.io/) - Semantic grid framework

### Language Reference

- [CoffeeScript](http://coffeescript.org/)
- [Sass](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html)
- [HTTP/1.1](http://www.w3.org/Protocols/rfc2616/rfc2616.html) - [Header Fields](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html), [Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
