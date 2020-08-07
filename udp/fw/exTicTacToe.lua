local M = {}

local function emptyBoard()
    return {
        {false, false, false},
        {false, false, false},
        {false, false, false}
    }
end
M.emptyBoard = emptyBoard

local function boardToString(board)
    local s = ''
    for y = 1, 3 do
        for x = 1, 3 do
            local c = board[y][x] or '.'
            s = s .. c
        end
        s = s .. '\n'
    end
    return s
end
M.boardToString = boardToString

local function isRow(board, y, piece)
    for x = 1, 3 do
        if board[y][x] ~= piece then
            return false
        end
    end
    return true
end

local function isColumn(board, x, piece)
    for y = 1, 3 do
        if board[y][x] ~= piece then
            return false
        end
    end
    return true
end

local function isDiagonal(board, idx, piece)
    local dy = 0
    local m = 1
    if idx == 2 then
        dy = 4
        m = -1
    end
    for i = 1, 3 do
        if board[dy + i*m][i] ~= piece then
            return false
        end
    end
    return true
end

local function isGameStuck(board)
    for y = 1, 3 do
        for x = 1, 3 do
            if board[y][x] ~= false then
                return false
            end
        end
    end
    return true
end
M.isGameStuck = isGameStuck

local function isGameWonByPiece(board, piece)
    for i = 1, 3 do
        if isRow(board, i, piece) then return true end
        if isColumn(board, i, piece) then return true end
    end
    for i = 1, 2 do
        if isDiagonal(board, i, piece) then return true end
    end
    return false
end
M.isGameWonByPiece = isGameWonByPiece

local function getNextPiece(piece)
    if piece == 'X' then
        return 'O'
    else
        return 'X'
    end
end
M.getNextPiece = getNextPiece

return M