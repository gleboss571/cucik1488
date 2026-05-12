local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage:WaitForChild("Events"))

local ItemPackageEvent =
    ReplicatedStorage.Events:WaitForChild("ItemPackageEvent")

--// CONFIG

local MIN_COMBO = 30
local MAX_COMBO = 39

local FIRST_BELT = "Petal Belt"
local SECOND_BELT = "Coconut Belt"

local SWITCH_DELAY = 0.5

--// STATE

local switching = false

--// EQUIP

local function equipAccessory(name)

    local success,err = pcall(function()

        ItemPackageEvent:InvokeServer(
            "Equip",
            {
                Category = "Accessory",
                Type = name,
            }
        )
    end)

    if success then
        print("[EQUIPPED]",name)
    else
        warn("[FAILED]",name,err)
    end
end

--// LISTENER

Events.ClientListen("PlayerAbilityEvent",function(data)

    if switching then
        return
    end

    for tag,info in pairs(data) do

        if tag == "Combo Coconuts"
        or tag == "ComboCoconuts" then

            if type(info) == "table"
            and info.Action == "Update" then

                local value =
                    info.Values
                    and info.Values[1]
                    or 0

                if value >= MIN_COMBO
                and value <= MAX_COMBO then

                    switching = true

                    task.spawn(function()

                        print("[COMBO]",value)

                        equipAccessory(FIRST_BELT)

                        task.wait(SWITCH_DELAY)

                        equipAccessory(SECOND_BELT)

                        task.wait(1)

                        switching = false
                    end)
                end
            end
        end
    end
end)

print("Combo Coconut Belt Switch Loaded")
print("Active Range:",MIN_COMBO.."-"..MAX_COMBO)
