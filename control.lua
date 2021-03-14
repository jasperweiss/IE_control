component = require("component")
sides = require("sides")
term = require("term")
toboolean = require("toboolean")

function splitcommand (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

components = {
    ["distillers"] = {},
    ["turbines"] = {},
    ["solar"] = {},
    ["redstone"] = {},
}

function align(text)
    spaces = ""
    padding = 18 - string.len(tostring(text))
    for i = 0, padding, 1 do
        spaces = spaces .. " "
    end
    return text .. spaces
end

function status(group)
    if group == "distillers" then
        print(align("distiller") .. align("energy status") .. align("input tank") .. align("output tank") .. align("address"))
        for k, v in pairs(components[group]) do
            inputTankInfo = v.object.getInputTankInfo()
            outputTankInfo = v.object.getOutputTankInfo()
            energyPercentage = tostring(v.object.getEnergyStored()/v.object.getMaxEnergyStored()*100) .. "%"
            inputTankFill = tostring(math.floor(inputTankInfo.amount / inputTankInfo.capacity*100)) .. "%"
            outputTankFill = tostring(math.floor(outputTankInfo.amount / outputTankInfo.capacity*100)) .. "%"
            inputTankContents = tostring(inputTankInfo.name)
            outputTankContents = tostring(outputTankInfo.name)
            print(align(k) .. align(energyPercentage) .. align(inputTankContents .. " (" .. inputTankFill .. ")") .. align(outputTankContents .. " (" .. outputTankFill .. ")") .. align(v.address))
        end
    elseif group == "turbines" then
        print(align("turbine") .. align("speed") .. align("input tank") .. align("output tank") .. align("address"))
        for k, v in pairs(components[group]) do
            tankInfo = v.object.getTankInfo()
            outputTankInfo = v.object.getOutputTankInfo()
            inputTankFill = tostring(math.floor(tankInfo.amount / tankInfo.capacity*100)) .. "%"
            outputTankFill = tostring(math.floor(outputTankInfo.amount / outputTankInfo.capacity*100)) .. "%"
            inputTankContents = tostring(tankInfo.name)
            outputTankContents = tostring(outputTankInfo.name)
            speed = tostring(v.object.getSpeed()) .. " RPM"
            print(align(k) .. align(speed) .. align(inputTankContents .. " (" .. inputTankFill .. ")") .. align(outputTankContents .. " (" .. outputTankFill .. ")") .. align(v.address))
        end
    end
end

for k, v in pairs(component.list()) do
    if v == "it_distiller" then
        components["distillers"][#components["distillers"]+1] = {
            address = k,
            object = component.proxy(k)
        }
    end
    if v == "it_steam_turbine" then
        components["turbines"][#components["turbines"]+1] = {
            address = k,
            object = component.proxy(k)
        }
    end
    if v == "it_solar_tower" then
        components["solar"][#components["solar"]+1] = {
            address = k,
            object = component.proxy(k)
        }
    end
    if v == "redstone" then
        components["redstone"][#components["redstone"]+1] = {
            address = k,
            object = component.proxy(k)
        }
    end
end


while true do
    io.write("> ")
    command = splitcommand(io.read())
    if command[1] == "status" then
        status(command[2])
    elseif command[1] == "exit" then
        os.exit()

    elseif command[1] == "enable" then
        components[command[2]][tonumber(command[3])].object.setEnabled(true)
    elseif command[1] == "disable" then
        components[command[2]][tonumber(command[3])].object.setEnabled(false)
    end
end
