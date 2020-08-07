local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix

-- improvements:
-- - clients should not need to send a message to get considered...
-- - what's the maximum dgram size? 1472 data bytes for ipv4 (https://stackoverflow.com/questions/38723393/can-udp-packet-be-fragmented-to-several-smaller-ones)
-- - logic to identify skipped received messages? (dgram sending last ok rest from 100, server caching last 100 and replaying them?)
-- - detect dropped client?

local function isInt(n)
    return type(n) == 'number' and n == math.floor(n)
end

local function generateServer(opts)
    -- required
    assert(opts.port and isInt(opts.port), 'port must be defined as a number')
    assert(opts.fps  and isInt(opts.fps),  'fps must be defined as a number')
    assert(opts.api  and type(opts.api) == 'table',  'api must be defined as an object')

    -- optional
    if opts.onUpdate then
        assert(type(opts.onUpdate) == 'function', 'onUpdate should be a function')
    end
    if opts.onNewClient then
        assert(type(opts.onNewClient) == 'function', 'onNewClient should be a function')
    end
    if opts.onReceive then
        assert(type(opts.onReceive) == 'function', 'onReceive should be a function')
    end
    if opts.onEnd then
        assert(type(opts.onEnd) == 'function', 'onEnd should be a function')
    end

    local udp = socket.udp()

    udp:settimeout(0)
    udp:setsockname("*", opts.port) -- setsockname ~> sendto

    local clients = {}
    local running = true
    local dt =  1 / opts.fps
    local t = 0
    local reading = {udp}

    local function send(data, clientId)
        local pair = clients[clientId]
        local ip = pair[1]
        local port = pair[2]
        udp:sendto(data, ip, port)
    end

    local function broadcast(data)
        for _, pair in pairs(clients) do
            udp:sendto(data, pair[1], pair[2])
        end
    end

    local function broadcastExcept(data, exceptClientId)
        local pair = clients[exceptClientId]
        local exceptIp = pair[1]
        local exceptPort = pair[2]
        for _, pair in pairs(clients) do
            if pair[1] ~= exceptIp or pair[2] ~= exceptPort then
                udp:sendto(data, pair[1], pair[2])
            end
        end
    end

    local function getClients()
        return clients
    end

    local function stopRunning()
        if opts.onEnd then
            opts.onEnd()
        end
        running = false
    end

    signal.signal(signal.SIGINT, stopRunning)

    opts.api.broadcast = broadcast
    opts.api.broadcastExcept = broadcastExcept
    opts.api.getClients = getClients
    opts.api.send = send
    opts.api.stopRunning = stopRunning

    while running do
        if opts.onUpdate then
            opts.onUpdate(t)
        end

        socket.sleep(dt)
        t = t + dt
        local input = socket.select(reading, nil, 0)
        for _, skt in ipairs(input) do
            local data, msg_or_ip, port_or_nil = skt:receivefrom()
            local clientId = msg_or_ip .. ':' .. port_or_nil
            if clients[clientId] == nil then
                if opts.debug then
                    print("server: new client " .. clientId)
                end
                clients[clientId] = {msg_or_ip, port_or_nil}
                if opts.onNewClient then
                    opts.onNewClient(clientId, t)
                end
            end
            if data then
                if opts.debug then
                    print("server: received [" .. data .. '] from ' .. clientId)
                end
                if data and opts.onReceive then
                    opts.onReceive(data, clientId, t)
                end
            elseif msg_or_ip ~= "timeout" then
                error("server: network error - " .. tostring(msg_or_ip))
            end
        end
    end
end

return generateServer