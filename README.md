# stacktest

Experimental [Express](http://expressjs.com/) server with [Brunch](http://brunch.io) frontend and [Riak](http://basho.com/riak/) backend

## Usage

    npm install
    echo NODE_ENV=development > .env
    cake develop


## TODO

- include basic test script that verifies compilation and has room for expansion
- add precommit hook to recompile docs so they can be browsable on github


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
- [Handlebars](http://handlebarsjs.com/) - Logicless templates, used for filling in initial content of a view
- [Rivets](http://rivetsjs.com/) - [Reactive](http://en.wikipedia.org/wiki/Reactive_programming) data binding, used for declaratively specifying behavior of view elements
- [Font Awesome](http://fortawesome.github.com/Font-Awesome/) - Icon font
- [Bourbon Neat](http://neat.bourbon.io/) - Semantic grid framework
