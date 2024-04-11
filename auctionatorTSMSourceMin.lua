-- TSM price source using Auctionator Min buyout price
local scriptID = "MinBuyoutSourceForTSM"

Auctionator.API.v1.RegisterForDBUpdate(scriptID, function() 
    --CustomPrice.OnSourceChange("AtrMinBuyout")
end)

-- material cost (current)
min(vendorbuy,  atrvalue, crafting, convert(atrvalue))

-- resulting craft price
max(vendorsell, atrvalue * 0.95)