# only run in a browser window
return unless window?

# provide remote class toggling functionality
# given a structure such as
#     <div class="dropdown">
#         <div data-toggle="dropdown" data-toggle-class="open"></div>
#     </div>
# clicking the inner div will add or remove the "open" class from the parent div
# it is also possible to target multiple parent divs by adding more words to data-toggle
$(document).on("click", "[data-toggle]", (event)->
    $toggler = $(this)
    classToToggle = $toggler.data("toggleClass") or "open"
    $parent = $toggler
    for type in $toggler.data("toggle").split(/\s/)
        continue if type is ''
        $parent = $parent.parents("."+type).eq(0)
        $parent.toggleClass(classToToggle)
)

# provide radio-button-style selection group functionality. e.g.:
#     <div data-selection-group="tabs"></div>
#     <div data-selection-group="tabs" class="selected"></div>
#     <div data-selection-group="tabs"></div>
#     <div data-selection-group="tabs"></div>
$(document).on("click", "[data-selection-group]", (event)->
    $selection = $(this)
    group = $selection.data("selectionGroup")
    classToSet = $selection.data("radioClass") or "selected"

    $group = $selection.siblings("[data-selection-group=#{group}]")
    $group.removeClass(classToSet)
    $selection.addClass(classToSet)
)
