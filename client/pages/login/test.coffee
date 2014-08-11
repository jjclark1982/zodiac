LoginView = require("./index")

describe("LoginView", ->
    beforeEach((done)->
        @view = new LoginView()
        @view.render(done)
    )

    afterEach(->
        @view.remove()
    )

    it("should initialize and render without errors", ->
        expect(@view).to.be.ok
    )

    it("should show two forms", ->
        $forms = @view.$("form")
        expect($forms).to.have.length(2)
    )
)
