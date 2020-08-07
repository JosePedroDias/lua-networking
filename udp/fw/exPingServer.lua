local generateServer = require("udpserver")

local pingInterval = 5
local maxAllowedPing = 0.5

local lastPingEndT
local nextPingT = pingInterval
local lastPingT = 0
local pingResults
local srv = {}

generateServer({
  api = srv,
  port = 52225,
  fps = 120,
  -- debug = true,
  update = function(t)
    if lastPingEndT and t > lastPingEndT then
      local clients = srv.getClients()

      if next(clients) == nil then return end

      local didNotPingBack = {}
      for clientId, _ in pairs(clients) do didNotPingBack[clientId] = true end

      print("")

      if next(pingResults) ~= nil then
        print("PING RESULTS:")
        for clientId, ping in pairs(pingResults) do
          print("  " .. clientId .. " - " .. math.floor(ping * 1000) .. " ms")
          didNotPingBack[clientId] = nil
        end
        print("")
      end

      if next(didNotPingBack) ~= nil then
        print("DID NOT PING BACK:")
        for clientId, _ in pairs(didNotPingBack) do
          print("  " .. clientId)
        end
        print("")
      end

      lastPingEndT = false
    end

    if t > nextPingT then
      local clients = srv.getClients()
      if next(clients) ~= nil then
        nextPingT = t + pingInterval
      else
        pingResults = {}
        lastPingT = nextPingT
        lastPingEndT = lastPingT + maxAllowedPing
        nextPingT = t + pingInterval
        -- print("ping!")
        srv.broadcast("ping")
      end
    end
  end,
  onReceive = function(data, clientId, t)
    if data == "pong" then
      pingResults[clientId] = t - lastPingT
      print(clientId .. ": pong!")
    else
      print(clientId .. " sent " .. data)
    end
  end
})

