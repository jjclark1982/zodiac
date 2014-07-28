exports.config =
  # See http://brunch.io/#documentation for docs.

  server:
    path: 'server'
    port: process.env.PORT or 3333

  paths:
    watched: ["client", "test", "vendor"]
    public: "build"

  conventions:
    ignored: /^client\/layouts/

  modules:
    nameCleaner: (path)->
      path.replace(/^client\//, '')

  files:
    javascripts:
      joinTo:
        'javascripts/app.js': /^client/
        'javascripts/vendor.js': /^(bower_components|vendor)/
        'test/test.js': /^test/
      order:
        after: [
          'test/vendor/scripts/test-helper.js'
        ]

    stylesheets:
      joinTo:
        'stylesheets/app.css': /^(?!test)/
        'test/test.css': /^test/
      order:
        after: ['vendor/styles/helpers.css']

    templates:
      joinTo: 'javascripts/app.js'

  plugins:
    autoReload:
      persistent: (process.env.NODE_ENV isnt 'production')

    dust:
      retainWhitespace: !!process.env.DUST_RETAIN_WHITESPACE

    # see documentation at http://www.coffeelint.org/
    coffeelint:
      pattern: /^client\/.*\.coffee$/
      options:
        max_line_length:
          value: 120
        indentation:
          value: 4
        no_implicit_braces:
          level: "warn"
        no_implicit_parens:
          level: "warn"
        no_trailing_semicolons:
          level: "ignore"
        no_trailing_whitespace:
          level: "ignore"
