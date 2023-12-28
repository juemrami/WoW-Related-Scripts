---@meta

---Inverts a table, swapping keys and values.
---@generic K, V
---@param t table<K, V>
---@return table<V, K>
function tInvert(t) end

---@class WA.State
---@field changed boolean? # Informs WeakAuras that the states values have changed. Always set this to true for states that were changed.
---@field show boolean  # Controls whether the display is visible. Note, that states that have show set to false are automatically removed.
---@field unit string? # Associated unit. Used for unit anchors.
---@field name string? # The name, returned by `%n`
---@field stacks number? # The stacks, returned by `%s`
---@field index string|number? #  Sets the order the output will display in a dynamic group. Do not mix string and number indexes
---@field icon string|number? # Icon ID or texture path (for icons and progress bar auras)
---@field texture string|number? # Icon ID or texture path (for texture auras)
---@field progressType "static" | "timed"?
---@field expirationTime number? # Relative to `GetTime()` when used with "timed" progressType.
---@field duration number? # Total aura duration in seconds when used with "timed" progressType.
---@field value number? # Current progress value when used with "static" progressType.
---@field total number? # Total progress value when Used with "static" progressType.
---@field autoHide boolean? # Set to `true` to make the display automatically hide at the end of the "timed" progress. `autoHide` can also be used along with the `"static"` progressType by defining a `duration` and `expirationTime` along with the static `value` and `total`. While the static values will be displayed, the timed values will set the Hide time for the clone.
---@field paused boolean? # Set to `true` along with a `remaining` value to pause a "timed" progress. Set to `false` (and recalculate the expirationTime value) to resume.
---@field remaining number? # Remaining time of a pause in seconds when used with `paused` and "timed" progressType.
---@field additionalProgress WA.State.AdditionalProgressInfo[]? # This is a more complex field than the others but allows you to create "Overlays" on bars that you make using TSU. This table can have as many index-keyed subTables as you like. Each of those subTables contains the positional info for that overlay.  
---@field spellId number? Used for spell tooltip if set along with "Tooltip on Mouseover" aura option.
---@field itemId number? Can be used for item tooltip info.
---@field tooltip string? # Used for tooltip if set along with "Tooltip on Mouseover" aura option.
---@field tooltipWrap boolean? # `true` to make the text on the tooltip wrap to new lines, `false | nil` to let it make the tooltip as wide as needed to fit the text given.
---@class WA.State.AdditionalProgressInfo
---@field min number? # The minimum value of the overlay. Defined along with `max`.
---@field max number? # The maximum value of the overlay. Defined along with `min`.
---@field direction "forward"|"backward"? # The direction of the overlay progress. Defined with `width`
---@field width number? # The width of growing bar ie its moving edge offset from start. Defined with `direction`
---@field offset number? # Optionally defined with `direction` to offset moving edge.

---TSU triggers have the "Tooltip on Mouseover" option available by default in the Display tab. 
---However you need to provide specific information in the state in order for the tooltip you want to show. With that option ticked you need to use:
