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

    initialize: (options)->
        @columns = options.columns or @collection?.model?.prototype.fields or []
        if _.isString(@columns)
            @columns = JSON.parse(@columns)
        @columns = _.clone(@columns)
        if window?
            @listenTo(@collection, "add", @orderRows)
            @listenTo(@collection, "remove", @orderRows)
            @listenTo(@collection, "reset", @orderRows)
            @listenTo(@collection, "request", @syncStarted)
            @listenTo(@collection, "error", @syncError)
            @listenTo(@collection, "sync", @syncFinished)
            @listenToOnce(@collection, "sync", @firstSyncFinished)

    attributes: ->
        atts = super(arguments...)
        atts["data-columns"] = JSON.stringify(@columns)
        return atts

    syncStarted: (collection, xhr, options = {})->
        @$el.addClass("loading")
        xhr.always(=>
            @syncFinished(collection, xhr, options)
        )

    syncError: (collection, xhr, options = {})->
        @$el.addClass("error").attr("data-error", "#{xhr.status} #{xhr.statusText}")

    syncFinished: (collection, xhr, options = {})->
        @$el.removeClass("loading")

    firstSyncFinished: (collection, xhr, options = {})->
        for cid, subview of @subviews
            subview.render()
            subview.$el.attr("data-model-cid", subview.model.cid)
        @listenTo(@collection, "sort", @orderRows)

    events: {
        "click th.sortable": "setSort"
        "keyup input": "typeInput"
        "change input": "changeInput"
        "click .save-item": "saveItem"
        "click .fetch-item": "fetchItem"
        "click .destroy-item": "destroyItem"
        "click .create-item": "createItem"
    }

    createItem: (event)->
        @collection.add({}, {at: 0})

    clickedModel: (event)->
        $input = $(event.currentTarget)
        $row = $input.parents("tr").first()
        rowView = @subviews[$row.data("cid")]
        model = rowView.model
        return model

    saveItem: (event)->
        model = @clickedModel(event)
        model.save()
        $(event.currentTarget).attr("disabled", true)
        # TODO: loading indicator

    fetchItem: (event)->
        model = @clickedModel(event)
        for key in model.keys() when key isnt (model.idAttribute or 'id')
            model.unset(key, {silent: true})
        model.fetch().then(->
            $row = $(event.currentTarget).parents("tr").first()
            $inputs = $row.find("input")
            for input in $inputs
                $(input).val(model.get(input.name))
        )
        $(event.currentTarget).attr("disabled", true)
        # TODO: loading indicator

    destroyItem: (event)->
        model = @clickedModel(event)
        model.destroy()
        # TODO: loading indicator, re-add if destroy fails

    typeInput: (event)->
        $input = $(event.currentTarget)
        $row = $input.parents("tr").first()
        rowView = @subviews[$row.data("cid")]
        model = rowView.model
        name = $input.attr("name")
        value = $input.val()
        model.set($input.attr("name"), $input.val())

        if model.changedAttributes()
            $row.find(".save-item").removeAttr("disabled")
            $row.find(".fetch-item").removeAttr("disabled")

    changeInput: (event)->
        if @collection.comparator
            @collection.sort()

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

        for noCid, row of rowsByCid
            $tbody.append(row)
