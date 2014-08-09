unitTests = _.select(global.require.list(), (name)->
    name.match(/^(?!test).*test$/)
)
integrationTests = [
    './views/footer-view-test'
]

describe 'The testing environment', ->
    it 'should load without errors', ->
        expect(true).to.be.ok

    describe 'should compile unit tests without errors', ->
        for name in unitTests then do (name)->
            it name, ->
                require(name)

    describe 'should compile integration tests without errors', ->
        for name in integrationTests then do (name)->
            it name, ->
                require(name)
