FooterView = require 'views/footer'

class FooterViewTest extends FooterView
  renderTimes: 0

  render: ->
    @renderTimes += 1
    super()

describe 'FooterView', ->
  beforeEach ->
    @view = new FooterViewTest()
    @view.render()

  afterEach ->
    @view.remove()

  it 'should display 9 links', ->
    expect(@view.$el.find 'a').to.have.length 9
