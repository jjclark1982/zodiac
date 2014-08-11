BackgroundJobView = require("./index")
BackgroundJob = require("models/background-job")

describe("BackgroundJobView", ->
    beforeEach((done)->
        @model = new BackgroundJob()
        @view = new BackgroundJobView({model: @model})
        @view.render(done)
    )

    afterEach(->
        @view?.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )
)
