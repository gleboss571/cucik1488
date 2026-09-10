local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote = ReplicatedStorage.Events.ItemPackageEvent

local equipped = false
local debounce = false

local function equipMask(maskName)

    local args = {
        [1] = "Equip",
        [2] = {
            ["Type"] = maskName,
            ["Category"] = "Accessory"
        }
    }

    Remote:InvokeServer(unpack(args))

    print("✅ Equipped:", maskName)
end

UserInputService.InputBegan:Connect(function(input, gp)

    if gp then
        return
    end

    if input.KeyCode == Enum.KeyCode.F then

        if debounce then
            return
        end

        debounce = true

        equipped = not equipped

        if equipped then
            equipMask("Gummy Mask")
        else
            equipMask("Demon Mask")
        end

        task.wait(0.2)

        debounce = false
    end
end)

print("✅ Mask switcher loaded")
print("Press F to switch masks")
