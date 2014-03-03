BaseView = require("base/view")

module.exports = class TableView extends BaseView
    # A view that provides its requirePath can be re-instantiated after serialization
    requirePath: module.id

    # The CSS class for this view
    className: "table-view"

    tagName: "table"

    # BaseView's `render()` function uses the subclass's provided template
    template: require("./template")

    initialize: (options)->
        @columns = options.columns or @collection?.model?.prototype.fields or []
        if _.isString(@columns)
            @columns = JSON.parse(@columns)
        @columns = _.clone(@columns)
        @listenTo(@collection, "add", @render)
        @listenTo(@collection, "remove", @render)
        @listenTo(@collection, "sort", @orderRows)
        @listenTo(@collection, "reset", @render)
        @listenTo(@collection, "request", @syncStarted)
        @listenTo(@collection, "sync", @syncFinished)
        @listenTo(@collection, "error", @syncError)

    attributes: ->
        atts = super(arguments...)
        atts["data-columns"] = JSON.stringify(@columns)
        return atts

    syncStarted: (collection, xhr, options = {})->
        @$el.addClass("loading")
        xhr.always(=>
            @syncFinished(collection, xhr, options)
        )

    syncFinished: (collection, xhr, options = {})->
        @$el.removeClass("loading")
        @render()

    syncError: (collection, xhr, options = {})->
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")


    events: {
        "click th": "setSort"
        "change input": "changeInput"
    }

    changeInput: (event)->
        $input = $(event.currentTarget)
        $row = $input.parents("tr").first()
        modelCid = $row.data("model-cid")
        model = @collection.get(modelCid)
        name = $input.attr("name")
        value = $input.val()
        model.set(name, value)
        if model.changedAttributes()
            $row.find(".save-item").removeAttr("disabled")
            $row.find(".fetch-item").removeAttr("disabled")
        if @collection.comparator
            @collection.sort()

    setSort: (event)->
        $th = $(event.currentTarget)
        sortKey = $th.data("sortKey")
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
            $tbody.append(row)

        for noCid, row of rowsByCid
            $tbody.append(row)
