local component = require("component")
local sides = require("sides")
local thread = require("thread")
local event = require("event")

Distiller = {}

function tankInfoToString(percentage)
    return string.format("%i%%", percentage)
end

function Distiller:new(address)
    self.__index = self
    setmetatable({
        address = address,
        proxy = component.proxy(address)
    }, self)
    return o
end

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

Turbine = {}

function Turbine:new(address)
    self.__index = self
    return setmetatable({
        address = address,
        proxy = component.proxy(address),
        throttle = {
            speed = 0,
            proxy = "",
            side = sides.top
        }
    }, self)
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
    self.throttle.proxy = component.proxy(address)
    self.throttle.side = side or sides.top
end

function Turbine:monitor()
    self.monitorThread = thread.create(function()
        while true do
            local speed = self.proxy.getSpeed()
            local output = math.floor((self.throttle.speed - speed) / 200 * 8)
            self.throttle.proxy.setOutput(self.throttle.side, output)
            print(self.address, speed, output)
            os.sleep(1)
        end
    end)
end

function Turbine:stopMonitor()
    self.monitorThread:kill()
end

Light = {}

function Light:new(address)
    self.__index = self
    return setmetatable({
        address = address,
        proxy = component.proxy(address),
        side = sides.top
    }, self)
end

function Light:setEnabled(enabled)
    if enabled then
        self.proxy.setOutput(self.side, 15)
    else
        self.proxy.setOutput(self.side, 15)
    end
end

local st2 = Turbine:new("79524afe-0aed-4d7e-8361-92804d89f576")
local st1 = Turbine:new("2b7b198a-7baf-4d40-bece-84952440c15a")

lights = Light:new("f96dbeb0-e24c-490b-ad68-87b08bde5e81")
lights:setEnabled(true)

st1:setValveAddress("78920de6-827a-4a0a-ae90-6d010bc793af")
st2:setValveAddress("c0e8ad2a-6bd7-4721-b60d-79aa07202fed")

st2:monitor()
os.sleep(0.2)
st1:monitor()

for k,v in pairs(Turbine) do
    print(k, v)
end

st1:setThrottle(1700)
st2:setThrottle(0)

print("doing things..")
event.pull("key_down")
st1:setThrottle(0)
st2:setThrottle(0)
os.sleep(1)
st1:stopMonitor()
st2:stopMonitor()



