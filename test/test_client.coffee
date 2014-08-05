describe 'The testing environment', ->
    it 'should load without errors', ->
        expect(true).to.be.ok

tests = [
    './views/footer-view-test'
]

for test in tests
    describe test, ->
        it 'should compile without errors', ->
            expect(require(test)).to.be.ok
