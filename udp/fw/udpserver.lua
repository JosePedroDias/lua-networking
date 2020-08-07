local socket = require "socket" -- luarocks install luasocket
local signal = require("posix.signal") -- luarocks install luaposix

local function generateServer(opts)
    assert(opts.port, 'port must be defined as a number')
    assert(opts.fps, 'fps must be defined as a number')
    assert(opts.api, 'api must be defined as an object')

    local udp = socket.udp()

    udp:settimeout(0)
    udp:setsockname("*", opts.port) -- setsockname ~> sendto

    local clients = {}
    local running = true
    local dt =  1 / opts.fps
    local t = 0
    local reading = {udp}

    local function send(data, ip, port)
        udp:sendto(data, ip, port)
    end

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

    local function getClients()
        return clients
    end

    local function onSignal()
        running = false
    end

    signal.signal(signal.SIGINT, onSignal)

    opts.api.broadcast = broadcast
    opts.api.broadcastExcept = broadcastExcept
    opts.api.getClients = getClients
    opts.api.send = send

    while running do
        if opts.update then
            opts.update(t)
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
                if opts.onNewClient then
                    opts.onNewClient(clientId, t)
                end
                clients[clientId] = {msg_or_ip, port_or_nil}
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