if window?
    $(document).on("click", "[data-toggle]", (event)->
        $toggler = $(@)
        $parent = $toggler
        for type in $toggler.data("toggle").split(/\s/)
            $parent = $parent.parents("."+type).eq(0)
            $parent.toggleClass("open")
    )
