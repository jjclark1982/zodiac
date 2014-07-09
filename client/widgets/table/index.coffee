BaseView = require("base/view")
TableRowView = require("./row")
require("toggles")

module.exports = class TableView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "table-view"

    tagName: "table"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    alwaysFetchCollection: true # TODO: pagination

    initialize: (options)->
        modelProto = @collection?.model?.prototype
        if modelProto
            idAttr = modelProto.idAttribute
            fields = modelProto.fields or []
            defaultColumns = (f for f in fields when f.name isnt idAttr)
        @columns = options.columns or defaultColumns or []
        if _.isString(@columns)
            @columns = JSON.parse(@columns)
        if window?
            @listenTo(@collection, "add", @orderRows)
            @listenTo(@collection, "remove", @orderRows)
            @listenTo(@collection, "reset", @orderRows)
            @listenToOnce(@collection, "sync", @firstSyncFinished)

    attributes: ->
        atts = super(arguments...)
        atts["data-columns"] = JSON.stringify(@columns)
        return atts

    firstSyncFinished: (object, xhr, options = {})->
        return unless object is @collection
        for cid, subview of @subviews
            # fill in the columns for each row so we don't have to serialize them more than once
            subview.columns = @columns
            subview.$el.attr("data-model-cid", subview.model.cid)
        @listenTo(@collection, "sort", @orderRows)

    events: {
        "click th.sortable": "setSort"
        "click .create-item": "createItem"
    }

    createItem: (event)->
        @collection.add({}, {at: 0})

    setSort: (event)->
        $th = $(event.currentTarget)
        sortKey = $th.data("column-name")
        reverse = false
        if ($th.hasClass("sort-key"))
            reverse = true

        @$("th").removeClass("sort-key").removeClass("sort-key-reverse")
        if reverse
            $th.addClass("sort-key-reverse")
        else
            $th.addClass("sort-key")

        @collection.comparator = (a, b)->
            aVal = a.get(sortKey)
            bVal = b.get(sortKey)
            if _.isNumber(aVal)
                if reverse then return bVal-aVal else return aVal-bVal
            else
                aVal = (aVal ? '').toString().toLocaleLowerCase()
                bVal = (bVal ? '').toString().toLocaleLowerCase()
                if reverse then return bVal>aVal else return aVal>bVal


        @collection.sort()

    orderRows: ->
        $tbody = @$("tbody")
        $rows = $tbody.children()
        rowsByCid = {}
        for row in $rows
            cid = $(row).data('model-cid')
            rowsByCid[cid] = row
        $rows.detach()

        for model in @collection.models
            row = rowsByCid[model.cid]
            delete rowsByCid[model.cid]
            if row
                $tbody.append(row)
            else
                rowView = new TableRowView({model: model, columns: @columns})
                @subviews[rowView.cid] = rowView
                rowView.render()
                rowView.$el.attr("data-model-cid", model.cid)
                $tbody.append(rowView.el)

        # remove subviews of deleted models
        for noCid, row of rowsByCid
            for vcid, subview of @subviews
                if subview.model.cid is noCid
                    subview.remove()
                    delete @subviews[vcid]
                    break
