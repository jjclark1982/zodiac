StatusIndicatorView = require("./index")

describe("StatusIndicatorView", ->
    beforeEach((done)->
        @view = new StatusIndicatorView()
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )
)
