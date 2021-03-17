local component = require("component")
local sides = require("sides")

Distiller = {}

function tankInfoToString(percentage)
    return string.format("%i%%", percentage)
end

function Distiller:new(address)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.address = address
    self.proxy = component.proxy(self.address)
    self.proxy.enableComputerControl(true)
    return o
end

d1 = Distiller:new("9bb9c575-8189-4924-babf-4037c4a19480")

function Distiller:setEnabled(enabled) self.proxy.setEnabled() end

function Distiller:getEnergyPercentage()
    local value = math.floor(self.proxy.getEnergyStored() / self.proxy.getMaxEnergyStored()) * 100
    return string.format("%i%%", value)
end

function Distiller:getInputPercentage()
    local tankInfo = self.proxy.getInputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Distiller:getOutputPercentage()
    local tankInfo = self.proxy.getOutputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Turbine:new(address)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.address = address
    self.proxy = component.proxy(self.address)
    self.proxy.enableComputerControl(true)
    self.throttle = {
        speed = 0
        address = ""
        side = sides.top
    }
    return o
end

function Turbine:getInputPercentage()
    local tankInfo = self.proxy.getTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Turbine:getOutputPercentage()
    local tankInfo = self.proxy.getOutputTankInfo()
    return math.floor(tankInfo.amount / tankInfo.capacity) * 100
end

function Turbine:getSpeed()
    return self.proxy.getSpeed()
end

function Turbine:setThrottle(rpm)
    self.throttle.speed = rpm
end

function Turbine:setValveAddress(address, side)
    self.throttle.address = address
    self.throttle.side = side or sides.top
end

function Turbine:monitor()
    while true do
        

