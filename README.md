# stacktest

Experimental [Express](http://expressjs.com/) server with [Brunch](http://brunch.io) frontend and [Riak](http://basho.com/riak/) backend

## Usage

    npm install
    echo NODE_ENV=development > .env
    cake develop

## Directory Organization

[.env](.env) - specify development environment variables  
[Cakefile](Cakefile) - run tasks in the specified environment  
[Procfile](Procfile) - define production tasks  
[scripts/](scripts/) - tasks that don't fit in the Cakefile  
[generators/](generators/) - scaffolds for use with `scaffolt`  

[package.json](package.json) - specify server libraries for installation with `npm`  
[node_modules/](node_modules/) - installed server libraries  
[server/](server/) - original backend source code  

[config.coffee](config.coffee) - `brunch` configuration  
[bower.json](bower.json) - specify client libraries for installation with `bower`  
[bower_components/](bower_components/) - installed client libraries  
[client/](client/) - original frontend source code  
[build/](build/) - compiled frontend  

## TODO

- include basic test script that verifies compilation and has room for expansion
- add precommit hook to recompile docs so they can be browsable on github
- switch from handlebars to dust

- make a @view helper or >onLoad handler that can connect subviews to their superview asynchronously

- switch from sass to stylus unless specifically requested otherwise

## Documentation

### Language Reference

- [CoffeeScript](http://coffeescript.org/)
- [Sass](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html)
- [HTTP/1.1](http://www.w3.org/Protocols/rfc2616/rfc2616.html) - [Header Fields](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html), [Status Codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)

### Backend Frameworks (installed in `node_modules/`)

- [Express](http://expressjs.com/) - Middleware-oriented asynchronous web server
based on [Connect](http://www.senchalabs.org/connect/)
- [Mocha](http://visionmedia.github.com/mocha/) - Unit testing
- [Bower](http://twitter.github.com/bower/) - Web component manager
- [Brunch](http://brunch.io/) - Build tool

### Frontend Frameworks (installed in `bower_components/`)
- [jQuery](http://api.jquery.com/) - DOM manipulation and AJAX
- [Lodash](http://lodash.com/docs) - Functional programming utilities
- [Backbone](http://backbonejs.org/) - Data transport modeling and event binding
- [Dust](http://akdubya.github.io/dustjs/) - Asynchronous templates
- [Rivets](http://rivetsjs.com/) - Reactive data binding, used for declaratively specifying behavior of view elements
- [Font Awesome](http://fortawesome.github.com/Font-Awesome/) - Icon font
- [Bourbon Neat](http://neat.bourbon.io/) - Semantic grid framework
