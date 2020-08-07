local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix

local HOST = "127.0.0.1"
local PORT = 52225

local ipAddress = assert(socket.dns.toip(HOST))

local udp = socket.udp()
udp:settimeout(0)
udp:setpeername(ipAddress, PORT) -- setsockname ~> send

math.randomseed(os.time())
local id = tostring(math.random(99999))

local i = 0
local t = 0
local dt = 1 / 60
local nextSend = t + 0.5
local running = true

local function onSignal()
  running = false
end

signal.signal(signal.SIGINT, onSignal)

socket.sleep(0.5)

while running do
  socket.sleep(dt) -- or update cycle
  t = t + dt

  local data = udp:receive()
  if data then print(id .. " received data [" .. data .. "]") end

  if t > nextSend then
    udp:send(id .. " says hello #" .. i)
    nextSend = t + 0.5
    i = i + 1
  end
end
