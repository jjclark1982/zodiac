# Zodiac

Developmental [Express](http://expressjs.com/) server with [Brunch](http://brunch.io) frontend and [Riak](http://basho.com/riak/) backend

## Installation

Presently, this framework uses Riak as its data store.
Instructions for installing Riak are available [here](http://docs.basho.com/riak/latest/quickstart/).

### Step 1. Install [node.js](http://nodejs.org/)

### Step 2. Clone the project template

    git clone https://github.com/DestinationSoftware/zodiac.git
    cd zodiac

### Step 3. Install dependencies with npm and bower

    npm install

This will install all backend and frontend dependencies locally. Running this as superuser or with the `-g` (global) flag could cause conflicts.

### Step 4. Set environment variables

    echo NODE_ENV=development > .env
    echo RIAK_SERVERS=example.com:8098 >> .env
    export PATH=$PATH:node_modules/.bin

### Step 5. Launch

Run `cake` without any arguments to see what it can do. (All the items in the `scripts` directory are automatically added to this list.) Cake loads environment variables from an `.env` file and/or a configuration management server, and runs commands in that environment.

In development you usually want to run the server with auto-reloading:

    cake develop

And in production you usually want to start the server without auto-reloading:

    cake start

## Code Style Guide

Reusable components should be broken into separate repositories that can be installed by `npm` or `bower`.

When parentheses or braces are optional, use them.

Filenames should be in `kebab-case`. JavaScript symbol names and properties should be in `camelCase`. JavaScript Class constructors should be in `UpperCamelCase`. CSS class names should be in `kebab-case`. Environment variables should be in `ALL_CAPS`.

Most server modules should export a singleton. Most client modules should export a class constructor.

### Custom Backbone Events

- `render:before` - triggered each time a view begins rendering
- `render:after` - triggered each time a view finishes rendering
- `filter` - triggered on a collection when a its `filterCond` has been updated

### Directory Organization

Source Code

[client/](client/) - original frontend source code  
[server/](server/index.html) - original backend source code  
[scripts/](scripts/) - commands to run in the same environment as the server, on an as-needed basis  

Configuration

[.env](.env) - specify development environment variables  
[package.json](package.json) - specify server dependencies for installation with `npm`  
[bower.json](bower.json) - specify client dependencies for installation with `bower`  
[Cakefile](Cakefile) - run tasks in the specified environment with `cake`  
[config.coffee](config.coffee) - `brunch` configuration  
[generators/](generators/) - scaffolds for use with `scaffolt`  
[node_modules/](node_modules/) - automatically installed server dependencies  
[bower_components/](bower_components/) - automatically managed client dependencies  
[vendor/](vendor/) - manually managed client dependencies such as licensed fonts  
[build/](build/) - compiled client  

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
- [Backbone.stickit](http://nytimes.github.io/backbone.stickit/) - Two-way reactive data binding
- [Font Awesome](http://fortawesome.github.com/Font-Awesome/) - Icon font

### Language Reference

- [CoffeeScript](http://coffeescript.org/)
- [Stylus](http://learnboost.github.io/stylus/)
- [Dust](http://akdubya.github.io/dustjs/) - Asynchronous templates
- [HTTP/1.1](http://www.w3.org/Protocols/rfc2616/rfc2616.html) - [Header Fields](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html), [Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
