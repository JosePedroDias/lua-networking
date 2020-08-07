local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix

local HOST = "127.0.0.1"
local PORT = 52225

local ipAddress = assert(socket.dns.toip(HOST))

local udp = socket.udp()
udp:settimeout(0)
udp:setpeername(ipAddress, PORT) -- setsockname ~> send

local running = true

local function onSignal()
  running = false
end

signal.signal(signal.SIGINT, onSignal)

socket.sleep(0.5)

-- print("hello")
udp:send("hello")

while running do
  socket.sleep(1 / 60) -- or update cycle
  local data = udp:receive()
  if data and data == "ping" then
    -- print("pong!")
    udp:send("pong")
  end
end
