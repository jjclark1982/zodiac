HomeView = require("./index")

describe("HomeView", ->
    beforeEach((done)->
        @view = new HomeView()
        @view.render(done)
    )

    afterEach(->
        @view.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )
)
