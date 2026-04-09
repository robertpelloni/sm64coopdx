-- Helper to safely request saves across the codebase
_G.SafeSave = function(systemStr)
    if _G.SaveManager then
        SaveManager.request_save()
    else
        if systemStr == "Mail" and _G.Mail then Mail.save() end
        if systemStr == "AuctionHouse" and _G.AuctionHouse then AuctionHouse.save() end
        if systemStr == "Housing" and _G.Housing then Housing.save() end
        if systemStr == "Inventory" and _G.Inventory then Inventory.save() end
    end
end
