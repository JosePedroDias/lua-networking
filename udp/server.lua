local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix

local PORT = 52225

local udp = socket.udp()

udp:settimeout(0)
udp:setsockname("*", PORT) -- setsockname ~> sendto

local clients = {}
local running = true
local dt =  1 / 60
local t = 0
local reading = {udp}

local function broadcast(data)
    for _, pair in pairs(clients) do
        udp:sendto(data, pair[1], pair[2])
    end
end

local function broadcastExcept(data, exceptIp, exceptPort)
    for _, pair in pairs(clients) do
        if pair[1] ~= exceptIp or pair[2] ~= exceptPort then
            udp:sendto(data, pair[1], pair[2])
        end
    end
end

local function onSignal()
    running = false
end

signal.signal(signal.SIGINT, onSignal)

while running do
    socket.sleep(dt)
    t = t + dt
  local input = socket.select(reading, nil, 0)
  for _, skt in ipairs(input) do
    local data, msg_or_ip, port_or_nil = skt:receivefrom()
    local clientId = msg_or_ip .. ':' .. port_or_nil
    if clients[clientId] == nil then
        print("server: new client " .. clientId)
        clients[clientId] = {msg_or_ip, port_or_nil}
    end
    if data then
        print("server: received [" .. data .. '] from ' .. clientId)
        -- udp:sendto(data, msg_or_ip, port_or_nil) -- echo
        -- broadcast(data)
        broadcastExcept(data, msg_or_ip, port_or_nil)
    elseif msg_or_ip ~= "timeout" then
        error("server: network error - " .. tostring(msg_or_ip))
    end
  end
end

print('done')