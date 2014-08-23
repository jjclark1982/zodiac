LogoutView = require("./index")

describe("LogoutView", ->
    beforeEach((done)->
        @view = new LogoutView()
        @view.render(done)
    )

    afterEach(->
        @view.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )
)
