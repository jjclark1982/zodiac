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

### Anatomy of a component

This engine is built around components. A typical component is a folder with all the code, markup, and style needed for a feature. For example

    views/example/
        index.coffee - module that exports the ExampleView class constructor
        template.dust - template 
        style.styl
        test.coffee - unit tests for this component


### Directory Organization

Source Code

- [client/](client/) - Original frontend source code. Everything in this folder gets compiled into a a web client in `build/`. All source code in this directory runs in a web browser, and much of it also gets loaded by the server. Calling `require(filename)` from anywhere in the app will look in this folder first.

    - [models/](client/models/) - Backbone models for use in this app. Models that have a `urlRoot` property defined will be automatically routed by the server and displayed with their `defaultView` and `defaultListView` as appropriate.

    - [views/](client/views/) - Backbone views for use in this app. Using the dust partial syntax `{>viewName /}` will look in this folder first, for `views/

    - [pages/](client/pages/) - Backbone views that do not need any model data from the router. Ones that have a `mountPoint` property defined will be mounted at that url. 

- [server/](server/index.html) - Original backend source code. Everything in this directory should only expect to run in a server environment.

- [scripts/](scripts/) - Commands to run in the same environment as the server, on an as-needed basis. Adding a script to this folder automatically makes it runnable by `cake`.

- [test/](test/) - Server-side tests to be run with `cake test`, and the main entry point for client-side tests that are run by navigating to `/test/`.

Configuration

[.env](.env) - specify development environment variables to be loaded by `cake` or `foreman`  
[Cakefile](Cakefile) - run tasks in the specified environment with `cake`  
[package.json](package.json) - specify server dependencies for installation with `npm`  
[node_modules/](node_modules/) - automatically installed server dependencies  
[bower.json](bower.json) - specify client dependencies for installation with `bower`  
[bower_components/](bower_components/) - automatically managed client dependencies  
[vendor/](vendor/) - manually managed client dependencies such as licensed fonts  
[config.coffee](config.coffee) - `brunch` configuration  
[generators/](generators/) - scaffolds for use with `scaffolt`  
[build/](build/) - compiled web client and assets  

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
- [Mocha](http://mochajs.org/) - Unit testing
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
