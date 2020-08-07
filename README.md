# lua networking

A set of small apps to solve gamedev networking scenarios. WIP!

## setup

    eval (luarocks --lua-dir=/usr/local/opt/lua@5.1 path --bin)
    luarocks --lua-dir=/usr/local/opt/lua@5.1 install luasocket
    luarocks --lua-dir=/usr/local/opt/lua@5.1 install luaposix
    brew install enet
    luarocks --lua-dir=/usr/local/opt/lua@5.1 install enet

    lua5.1 server.lua
    lua5.1 client.lua

## scenarios

### udp

- very raw server and client
- fw has a modularized server (UdpServer) and example pairs:
  - ping
  - tic tac toe
- rewritten UdpServer for it to be based on enet. so this way i get reliability and order back

### udp hole punching

TODO

### tcp

TODO
