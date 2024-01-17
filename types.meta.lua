---@meta

---Inverts a table, swapping keys and values.
---@generic K, V
---@param t table<K, V>
---@return table<V, K>
function tInvert(t) end

C_Seasons = {
    ---@return number? seasonID # `Enum.SeasonID` for the currently active season.
    GetActiveSeason = function() end,
    ---@return boolean # `true` if player is logged into a server with an active season.
    HasActiveSeason = function() end,
}
C_Engraving = {

}
DevTool = {
    ---@param data any
    ---@param name string?
    AddData = function(self, data, name) end,
}
ViragDevTool = DevTool
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


---@class WA.CustomConditions : { [string]: WA.CustomConditions.Type|WA.CustomConditions.ComplexCondition }
---@field expirationTime boolean?
---@field duration boolean?
---@field value boolean?
---@field total boolean?
---@field stacks boolean?

---Custom function to decide the condition's state
---@param state WA.State State table of the state to be evaluated
---@param needle any The key for **selected** (from ui) value from the defined `values` table.
---@return boolean
local _WA_ConditionTest = function(state, needle) end

---@alias WA.CustomConditions.Type "bool"|"string"|"number"|"timer"

---@class WA.CustomConditions.ComplexCondition
---@field display string # Display name in conditions tab.
---@field type WA.CustomConditions.Type
---@field values table<any, string>? # Optional. Only used for `"select"` type. The keys are the possible values for this variable from the TSU. The values are the display names in the conditions tab.
---@field test (fun(state: WA.State, needle: any): boolean?)? # Custom function to decide the condition's state
---@field events string[]? # Additional event to test the condition on. Optional.


---@param button Button
---@param quality integer
---@param itemIDOrLink string|number|nil
---@param suppressOverlays any
function SetItemButtonQuality(button, quality, itemIDOrLink, suppressOverlays) end

---@class EngravingData
---@field skillLineAbilityID number
---@field itemEnchantmentID number
---@field name string
---@field iconTexture number
---@field equipmentSlot number
---@field level number
---@field learnedAbilitySpellIDs number[]

C_Engraving = {
    ---@param category number
    AddCategoryFilter = function(category) end,

    ---@param category number
    AddExclusiveCategoryFilter = function(category) end,

    ---@param skillLineAbilityID number
    CastRune = function(skillLineAbilityID) end,

    ClearAllCategoryFilters = function() end,

    ---@param category number
    ClearCategoryFilter = function(category) end,

    ClearExclusiveCategoryFilter = function() end,

    ---@param enabled boolean
    EnableEquippedFilter = function(enabled) end,

    ---@return EngravingData engravingInfo
    GetCurrentRuneCast = function() end,

    ---@return boolean enabled
    GetEngravingModeEnabled = function() end,

    ---@return number category
    GetExclusiveCategoryFilter = function() end,

    ---@param equipmentSlot number
    ---@return number known, number max
    GetNumRunesKnown = function(equipmentSlot) end,

    ---@param shouldFilter boolean
    ---@param ownedOnly boolean
    ---@return table categories
    GetRuneCategories = function(shouldFilter, ownedOnly) end,

    ---@param equipmentSlot number
    ---@return EngravingData engravingInfo
    GetRuneForEquipmentSlot = function(equipmentSlot) end,

    ---@param containerIndex number
    ---@param slotIndex number
    ---@return EngravingData engravingInfo
    GetRuneForInventorySlot = function(containerIndex, slotIndex) end,

    ---@param category number
    ---@param ownedOnly boolean
    ---@return table engravingInfo
    GetRunesForCategory = function(category, ownedOnly) end,

    ---@param category number
    ---@return boolean result
    HasCategoryFilter = function(category) end,

    ---@return boolean value
    IsEngravingEnabled = function() end,

    ---@param equipmentSlot number
    ---@return boolean result
    IsEquipmentSlotEngravable = function(equipmentSlot) end,

    ---@return boolean enabled
    IsEquippedFilterEnabled = function() end,

    ---@param containerIndex number
    ---@param slotIndex number
    ---@return boolean result
    IsInventorySlotEngravable = function(containerIndex, slotIndex) end,

    ---@param containerIndex number
    ---@param slotIndex number
    ---@return boolean result
    IsInventorySlotEngravableByCurrentRuneCast = function(containerIndex, slotIndex) end,

    ---@param spellID number
    ---@return boolean result
    IsKnownRuneSpell = function(spellID) end,

    ---@param skillLineAbilityID number
    ---@return boolean result
    IsRuneEquipped = function(skillLineAbilityID) end,

    RefreshRunesList = function() end,

    ---@param enabled boolean
    SetEngravingModeEnabled = function(enabled) end,

    ---@param filter string
    SetSearchFilter = function(filter) end,
}

---@class ItemButtonTemplate : Button
---@field IconBorder Texture
---@field IconQuestTexture Texture?
---@field JunkIcon Texture?
---@field IconOverlay Texture?
---@field icon Texture
---@field Count FontString
---@field searchOverlay Texture
---@field subicon Texture

---@alias itemInfoData  { useLinkForItemInfo: boolean?, link: string?, name: string?, color: table?, texture: string?, count: number?} # A table of data to passed to the popup with `StaticPopup_Show()` accessed by `self.data`

---@generic UserData
---@alias ThisPopup StaticPopupDialog<UserData> 
---@class StaticPopupInfo<UserData>
---@field OnAccept fun(self: ThisPopup, data1: any, data2: any) # Function to call when button1 is clicked
local StaticPopupInfo = {
    text = nil, ---@type string # The text to display in the popup
    button1 = nil, ---@type string # The text of the first button or the button object when accessed with `self.button1`
    button2 = nil, ---@type string # The text of the second button
    button3 = nil, ---@type string # The text of the third button
        
    ---Function to call when the second button is clicked
    ---@param data1 any
    ---@param data2 any
    OnCancel = function(self, data1, data2) end,
    
    ---Function to call when the third button is clicked
    ---@param self ThisPopup
    ---@param data1 any
    ---@param data2 any
    OnAlt = function(self, data1, data2) end,
    
    ---Function to call when the popup is shown
    ---@generic UserData
    ---@param self StaticPopupDialog<`UserData`>
    OnShow = function(self) end,
    
    ---Function to call when the popup is hidden
    ---@param self StaticPopupDialog<`UserData`>
    OnHide = function(self) end,
    
    ---Callback called every frame the popup is visible
    ---@param self StaticPopupDialog<`UserData`>
    OnUpdate = function(self) end,
    
    ---Function callback for when a hyperlink is clicked
    ---@param self StaticPopupDialog<`UserData`>
    ---@param link string?
    ---@param text string?
    ---@param button "LeftButton"|"RightButton"?
    OnHyperlinkClick = function(self, link, text, button) end,
    
    ---Function to call when the mouse enters a hyperlink
    ---@param self StaticPopupDialog<`UserData`>
    ---@param link string?
    ---@param text string?
    ---@param region Region?
    ---@param boundsLeft number?
    ---@param boundsBottom number?
    ---@param boundsWidth number?
    ---@param boundsHeight number?
    OnHyperlinkEnter = function(self, link, text, region, boundsLeft, boundsBottom, boundsWidth, boundsHeight) end,

    timeout = nil, ---@type number? # The time in seconds before the dialog automatically hides itself
    whileDead = nil, ---@type boolean? # If true, allows the dialog to be shown while the player is dead
    exclusive = nil, ---@type boolean? # If true, causes the dialog to hide all other dialogs when it is shown
    hideOnEscape = nil, ---@type boolean? # If true, hides the dialog when the escape key is pressed
    enterClicksFirstButton = nil, ---@type boolean? # If true, simulates a click on the first button when the enter key is pressed
    hasEditBox = nil, ---@type boolean? # If true, adds an edit box to the dialog
    maxLetters = nil, ---@type number? # The maximum number of characters that can be entered into the edit box
    maxBytes = nil, ---@type number? # The maximum number of bytes that can be entered into the edit box
    editBoxWidth = nil, ---@type number? # The width of the edit box
    editBoxInstructions = nil, ---@type string? # The text to display (in|ontop of?) the edit box (when it is empty?)
    
    ---Function to call when the text in the edit box changes
    ---@param self StaticPopupEditBox
    EditBoxOnTextChanged = function(self) end,
    ---Function to call when the escape key is pressed while the edit box has focus
    ---@param self StaticPopupEditBox
    EditBoxOnEscapePressed = function(self) end,
    ---Function to call when the enter key is pressed while the edit box has focus
    ---@param data any
    EditBoxOnEnterPressed = function(self, data) end,

    wide = nil, ---@type boolean? # If true, makes the dialog wider than normal
    showAlert = nil, ---@type boolean? # If true, shows an alert icon on the dialog
    startDelay = nil, ---@type number? # The number of seconds to wait before the dialog is shown
    displayDelay = nil, ---@type number? # The number of seconds to wait before the dialog is displayed
    sound = nil, ---@type string? # The sound to play when the dialog is shown
    interstitial = nil, ---@type boolean? # If true, shows the dialog as an interstitial popup
    cover = nil, ---@type boolean? # If true, shows a fullscreen cover behind the dialog
    interruptCinematic = nil, ---@type boolean? # If true, interrupts the current cinematic when the dialog is shown
    cancels = nil, ---@type string[]? # A list of other dialog names to hide when this dialog is shown
    notClosableByLogout = nil, ---@type boolean? # If true, prevents the dialog from being closed by logging out
    noCancelOnReuse = nil, ---@type boolean? # If true, prevents the dialog from being closed (when it is shown again? | when StaticPopup1 is reused?)
    preferredIndex = nil, ---@type number? # The preferred index for this dialog in `[1, STATICPOPUP_NUMDIALOGS]`
    fullScreenCover = nil, ---@type boolean? # If true, shows a fullscreen cover behind the popup
    subText = nil, ---@type string? # The text to display in the subtext area of the dialog
    verticalButtonLayout = nil, ---@type boolean? # If true, lays out the buttons vertically instead of horizontally
    showAlertGear = nil, ---@type boolean? # If true, shows an cog/alert icon on the dialog.
    autoCompleteSource = nil, ---@type any[]? # List of tables which can be parsed in `AutoCompleteEditBox_SetAutoCompleteSource`
    autoCompleteArgs = nil, ---@type any[]? # List of Autocomplete Flags/masks from `AUTOCOMPLETE_LIST` in `AutoComplete.lua`
    closeButton = nil, ---@type boolean? # If true, adds a close button at the corner of the dialog.
    hasMoneyFrame = nil, ---@type boolean? # If true, adds a money frame to the dialog.
    hasMoneyInputFrame = nil, ---@type boolean? # If true, adds a money input frame to the dialog.
    hasItemFrame = nil, ---@type boolean? # If true, adds an item button to the dialog.
    timeoutInformationalOnly = nil, ---@type boolean? # If true, the dialog will not be hidden when the timeout expires only the informations.
}
---@class StaticPopupButtonTemplate : Button
---@field PulseAnim AnimationGroup
---@field Flash Texture

---@class StaticPopupEditBox : EditBox
---@field Instructions FontString

---@class MoneyInputEditBox : EditBox
---@field texture Texture
---@field label FontString

---@class MoneyInputFrame : Frame
---@field gold MoneyInputEditBox
---@field silver MoneyInputEditBox
---@field copper MoneyInputEditBox

---@class StaticPopupChildFrames
---@field text FontString
---@field button1 StaticPopupButtonTemplate
---@field button2 StaticPopupButtonTemplate
---@field button3 StaticPopupButtonTemplate
---@field button4 StaticPopupButtonTemplate
---@field editBox StaticPopupEditBox
---@field SubText FontString
---@field ItemFrame ItemButtonTemplate
---@field itemFrame ItemButtonTemplate
---@field Separator Texture
---@field extraButton StaticPopupButtonTemplate
---@field CoverFrame Frame
---@field icon Texture
---@field moneyInputFrame MoneyInputFrame
---@field moneyFrame Frame

-- -@field data `UserData`|itemInfoData # The data passed to the popup with `StaticPopup_Show()` accessed by `self.data`

---@class StaticPopupDialog<UserData> : BackdropTemplate, StaticPopupChildFrames, Frame, {data: UserData|itemInfoData}
local StaticPopupDialog = {
    which = nil, ---@type string # The key of the popup to show (from `StaticPopupDialogs` table)
    timeLeft = 0, ---@type number # The time left before the dialog automatically hides itself from `StaticPopupDialogs.timeout`. Updated `StaticPopup_OnUpdate()`.
    hideOnEscape = nil, ---@type boolean? # inherited from `StaticPopupDialogs.hideOnEscape`
    exclusive = nil, ---@type boolean? # inherited from `StaticPopupDialogs.exclusive`
    enterClicksFirstButton = nil, ---@type boolean? # inherited from `StaticPopupDialogs.enterClicksFirstButton`
    insertedFrame = nil, ---@type Frame? # Frame passed into `StaticPopup_Show()`.
    startDelay = nil, ---@type number? # The number of seconds to wait before the dialog button1 is enabled. Value set by `StaticPopupInfo.StartDelay` if defined. 
    numButtons = nil, ---@type number # The number of buttons to display. Value set by `StaticPopupInfo.numButtons`.
    maxHeightSoFar = nil, ---@type number # The maximum height of the dialog so far.
    maxWidthSoFar = nil, ---@type number # The maximum width of the dialog so far.
    backdropInfo = {
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
        edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
        edgeSize = 32,
        insets = {
            bottom = 11,
            left = 11,
            right = 12,
            top = 12,
        },
        tile = true,
        tileEdge = true,
        tileSize = 32,
    }, --- # Global table shared by all dialogs.
}

---@generic T
---@param which string # The key of the popup to show (from `StaticPopupDialogs`table)
---@param text_arg1 string? # Text argument to pass to the popup's `text` field replacing the first `%s` in the string
---@param text_arg2 string? # Text argument to pass to the popup's `text` field replacing the second `%s` in the string
---@param data `T` # Assigned to the popup's `data` field
---@return StaticPopupDialog<T> dialog
function StaticPopup_Show(which, text_arg1, text_arg2, data, insertedFrame)  end