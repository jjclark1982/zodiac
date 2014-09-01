describe "The frontend testing engine", ->
    it "should load in a browser environment", ->
        expect(window?).to.be.true

    it "should use a mock Backbone.sync method", ->
        require("./backbone-sync-mock")

    describe "should compile unit tests without errors", ->
        unitTests = []
        for name in (window.require.list() or []) when name.match(/^(?!test).*test$/)
            unitTests.push(name)
        for name in unitTests then do (name)->
            it name, ->
                require(name)

    describe "should compile integration tests without errors", ->
        integrationTests = [
            # put relative filenames of tests here
        ]
        for name in integrationTests then do (name)->
            it name, ->
                require(name)
