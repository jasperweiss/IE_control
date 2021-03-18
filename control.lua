local component = require("component")
local thread = require("thread")
local event = require("event")
local sides = require("sides")
local term = require("term")

function align(text)
    spaces = ""
    padding = 16 - string.len(tostring(text))
    for i = 0, padding, 1 do
        spaces = spaces .. " "
    end
    return text .. spaces
end

function tankInfoToString(percentage)
    return string.format("%i%%", percentage)
end

Distiller = {}

function Distiller:new(address)
    self.__index = self
    component.proxy(address).enableComputerControl(true)
    return setmetatable({
        address = address,
        proxy = component.proxy(address)
    }, self)
end

function Distiller:setEnabled(enabled) self.proxy.setEnabled() end

function Distiller:getEnergyPercentage()
    return math.floor(self.proxy.getEnergyStored() / self.proxy.getMaxEnergyStored() * 100)
end

function Distiller:getInputPercentage()
    local tankInfo = self.proxy.getInputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity * 100)
end

function Distiller:getOutputPercentage()
    local tankInfo = self.proxy.getOutputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity * 100)
end

Turbine = {}

function Turbine:new(address)
    self.__index = self
    component.proxy(address).enableComputerControl(true)
    return setmetatable({
        address = address,
        proxy = component.proxy(address),
        throttle = {
            proxy = "",
            speed = 0,
            output = 0,
        },
        alternator = {
            proxy = 0,
            storedEnergy = 0,
        },
        status = {
            speed = 0
        }
    }, self)
end

function Turbine:getInputPercentage()
    local tankInfo = self.proxy.getTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity * 100)
end

function Turbine:getOutputPercentage()
    local tankInfo = self.proxy.getOutputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity * 100)
end

function Turbine:setThrottle(rpm)
    self.throttle.speed = rpm
end

function Turbine:setValveAddress(address)
    self.throttle.proxy = component.proxy(address)
end

function Turbine:setAlternatorAddress(address)
    self.alternator.proxy = component.proxy(address)
end

function Turbine:monitor()
    self.monitorThread = thread.create(function()
        while true do
            self.status.speed = self.proxy.getSpeed()
            self.throttle.output = math.floor((self.throttle.speed - self.status.speed) / 200 * 8) 
            self.throttle.proxy.setOutput({self.throttle.output})
            os.sleep(1)
        end
    end)
end

function Turbine:stopMonitor()
    self.monitorThread:kill()
end

function Turbine:PowerMonitor()
    self.powerMonitorThread = thread.create(function()
        local interval = 2
        while true do
            self.alternator.storedEnergy = self.alternator.proxy.getInput(sides.top)
            self.throttle.speed = ((12 - self.alternator.storedEnergy) / 10) * 1700
            os.sleep(interval)
        end
    end)
end

function Turbine:stopPowerMonitor()
    self.powerMonitorThread:kill()
end

Light = {}

function Light:new(address)
    self.__index = self
    return setmetatable({
        address = address,
        proxy = component.proxy(address),
    }, self)
end

function Light:setEnabled(enabled)
    if enabled then
        self.proxy.setOutput({5})
    else
        self.proxy.setOutput({15})
    end
end

Solar = {}

function Solar:new(address)
    self.__index = self
    component.proxy(address).enableComputerControl(true)
    return setmetatable({
        address = address,
        proxy = component.proxy(address)
    }, self)
end

function Solar:getInputPercentage()
    local tankInfo = self.proxy.getInputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Solar:getOutputPercentage()
    local tankInfo = self.proxy.getOutputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Solar:getReflectors()
    local reflectors = self.proxy.getReflectors()
    local list = ""
    for i = 1, 4, 1 do
        list = list .. reflectors[i] .. " "
    end
    return list
end

function status(devices)
    statusMonitorThread = thread.create(function()
        local interval = 3
        while true do

            local statusTable = {}

            --- Turbines
            table.insert(statusTable, align("turbine") .. align("speed") .. align("throttle") .. align("energy") .. align("throttle svc") .. align("power svc"))
            for k,v in pairs(devices.turbines) do
                table.insert(statusTable, align(k) .. align(v.status.speed) .. align(v.throttle.speed) .. align(v.alternator.storedEnergy) .. align(v.monitorThread:status()) .. align(v.powerMonitorThread:status()))
            end
            table.insert(statusTable,"")

            --- Solar
            table.insert(statusTable, align("solar") .. align("reflectors") .. align("input") .. align("output"))
            for k,v in pairs(devices.solars) do
                table.insert(statusTable, align(k) .. align(v:getReflectors()) .. align(string.format("%i%%", v:getInputPercentage())) .. align(string.format("%i%%", v:getOutputPercentage())))
            end
            table.insert(statusTable,"")
            
            --- Distillers
            table.insert(statusTable, align("distiller") .. align("energy") .. align("input") .. align("output"))
            for k,v in pairs(devices.distillers) do
                table.insert(statusTable, align(k) .. align(string.format("%i%%", v:getEnergyPercentage())) .. align(string.format("%i%%", v:getInputPercentage())) .. align(string.format("%i%%", v:getOutputPercentage())))
            end
            table.insert(statusTable,"")

            term.clear()
            for k,v in pairs(statusTable) do
                print(v)
            end
            os.sleep(interval)    
        end
    end)
end

print("setting up devices..")

devices = {
    turbines = {
        t2 = Turbine:new("79524afe-0aed-4d7e-8361-92804d89f576"),
        t1 = Turbine:new("2b7b198a-7baf-4d40-bece-84952440c15a"),
    },
    solars = {
        s1 = Solar:new("7b2377e8-fc13-430e-87ac-4d27b07bcbaf"),
        s2 = Solar:new("20cdaafe-bbe7-4c83-a78c-b3a45b52ce1c"),
        s3 = Solar:new("f2e9f642-d84e-4ca5-b33d-4999f8ff6b5b"),
    },
    distillers = {
        d1 = Distiller:new("9bb9c575-8189-4924-babf-4037c4a19480"),
        d2 = Distiller:new("f6417697-6196-4819-8045-e22b076d544a"),
    },
    lights = Light:new("f96dbeb0-e24c-490b-ad68-87b08bde5e81"),
}

devices.turbines.t1:setAlternatorAddress("db6223b0-080a-48cd-b0f5-a944e92bff31")
devices.turbines.t2:setAlternatorAddress("8e44cd3d-eb6c-4e7b-9b78-ed66fd10896f")

devices.turbines.t1:setValveAddress("78920de6-827a-4a0a-ae90-6d010bc793af")
devices.turbines.t2:setValveAddress("c0e8ad2a-6bd7-4721-b60d-79aa07202fed")

devices.lights:setEnabled(true)

for k,v in pairs(devices.turbines) do
    print(string.format("starting power monitor service for %s..", k))
    v:PowerMonitor()
    print(string.format("starting throttle monitor service for %s..", k))
    v:monitor()
    os.sleep(0.2)
end

status(devices)
event.pull("key_down")

for k,v in pairs(devices.turbines) do
    v:stopPowerMonitor()
    v:setThrottle(0)
    os.sleep(2)
    v:stopMonitor()
end

os.sleep(1)
statusMonitorThread:kill()
print("services stopped.")
os.exit()




