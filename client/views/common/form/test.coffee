FormView = require("./index")
BaseModel = require("lib/model")

describe("FormView", ->
    beforeEach((done)->
        dummyModel = new BaseModel()
        dummyModel.url = '/'
        @view = new FormView({model: dummyModel})
        @view.render(done)
    )

    afterEach(->
        @view.remove()
    )

    it("should render and re-render without errors", (done)->
        @view.render(done)
    )

    it("should render a form that posts to its model's url", ->
        action = @view.$("form").attr("action")
        url = _.result(@view.model, 'url')
        expect(action).to.equal(url)
    )
)
