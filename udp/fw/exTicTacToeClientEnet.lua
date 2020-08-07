local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix
local enet = require "enet"

local HOST = "127.0.0.1"
local PORT = 52225

local host = enet.host_create()
host:connect(HOST .. ":" .. PORT)

local running = true

local function onSignal()
  running = false
end

signal.signal(signal.SIGINT, onSignal)

while running do
  socket.sleep(1 / 60) -- or update cycle

  local event
  while true do
    event = host:service()
    if not event then break end
    if event.type == "receive" then
      local data = event.data
      if data == "get" then
        print("row (y)?")
        local y = io.read("*n")
        print("column (x)?")
        local x = io.read("*n")
        host:broadcast("play " .. y .. "," .. x)
      elseif data:sub(1, 3) == "end" then
        print(data:sub(5))
        running = false
      else
        print(data)
      end
    elseif event.type == "disconnect" then
      running = false
    end
  end
end

print("done")
