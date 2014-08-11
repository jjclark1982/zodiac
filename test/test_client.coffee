unitTests = _.select(global.require.list(), (name)->
    name.match(/^(?!test).*test$/)
)
integrationTests = [
    # put relative filenames of tests here
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
