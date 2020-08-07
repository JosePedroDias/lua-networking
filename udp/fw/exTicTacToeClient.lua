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
  if data then
    if data == "get" then
      print("row (y)?")
      local y = io.read("*n")
      print("column (x)?")
      local x = io.read("*n")
      udp:send("play " .. y .. "," .. x)
    elseif data:sub(1, 3) == "end" then
      print(data:sub(5))
      running = false
    else
      print(data)
    end
  end
end

print("done")
