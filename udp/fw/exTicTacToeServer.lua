local generateServer = require("UdpServer")
local ttt = require("exTicTacToe")

local srv = {}

-- [y][x]
local board = ttt.emptyBoard()

local pieces = {"X", "O"}
local nextPiece = "X"
local clientIdToPiece = {}
local pieceToClientId = {}
local sendDefaultReasonToLeave = true

local function askNext()
  srv.broadcast(ttt.boardToString(board))
  local clientId = pieceToClientId[nextPiece]
  srv.send("it is your turn to play with the " .. nextPiece, clientId)
  srv.send("get", clientId)
end

local function isInt(n)
  return type(n) == 'number' and n == math.floor(n)
end

generateServer({
  api = srv,
  port = 52225,
  fps = 60,
  -- debug = true,
  onEnd = function()
    if sendDefaultReasonToLeave then srv.broadcast("end served exiting") end
  end,
  onNewClient = function()
    print("new client")
    local clients = srv.getClients()
    local count = 0
    for clientId, _ in pairs(clients) do
      count = count + 1
      local piece = pieces[count]

      if count > 2 then error("too many players!") end

      clientIdToPiece[clientId] = piece
      pieceToClientId[piece] = clientId

      if count == 2 then
        srv.send("you play first with piece X", pieceToClientId["X"])
        srv.send("you play second with piece O", pieceToClientId["O"])
        askNext()
      end
    end
    print("client count: " .. count)
  end,
  onReceive = function(data, clientId, t)
    if data == "hello" then
    elseif data:sub(1, 4) == "play" then
      local y = tonumber(data:sub(6, 6))
      local x = tonumber(data:sub(8, 8))

      if not isInt(y) or y < 1 or y > 3 then
        srv.send("y must be an integer between 1 and 3", clientId)
        askNext()
        return
      elseif not isInt(x) or x < 1 or x > 3 then
        srv.send("x must be an integer between 1 and 3", clientId)
        askNext()
        return
      elseif board[y][x] ~= false then
        srv.send("position was already taken", clientId)
        askNext()
        return
      end

      board[y][x] = nextPiece

      if ttt.isGameWonByPiece(board, nextPiece) then
        srv.broadcast("end game won by " .. nextPiece)
        sendDefaultReasonToLeave = false
        srv.stopRunning()
      elseif ttt.isGameStuck(board) then
        srv.broadcast("end game got stuck")
        sendDefaultReasonToLeave = false
        srv.stopRunning()
      else
        nextPiece = ttt.getNextPiece(nextPiece)
        askNext()
      end
    else
      print("unsupported action [" .. data .. "]. ignored.")
    end
  end
})

