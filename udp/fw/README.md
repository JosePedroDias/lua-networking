# UdpServer

## caveats

- keep in mind a single datagram package in ipv4 should not be longer than MTU. keep it about 1500 bytes (with metadata I would aim at 90% of that to be safe). one can eventually deal with datagram fragmentation but I prefer KISS.

- with UDP you don't really know when clients drop so either have them periodically signal you for liveliness

- so far no mechanism is in place to identify dropped datagrams. some ideas:
  - have both server and clients keep the last n (ex 100) messages
    - data would be prefixed with the known number both in and out
    - receiving an out of order message....?
    - receiving a newer message than expected would trigger logic to request a resync?
  - clients and server have each other msg nr
    - hold out of order messages for deltaTime
      - if the ordered gap is filled timely, pass the ordered messages upwards
      - if it is not, ask for replay of the ones missing
      - have a second time recoverTime, to wait for replays as well

## potential problems is-game about the caveats above

in an authority game server

- if a msg is dropped from client to server, it will look to everyone as if the event was not performed and player can correct manually
- if a message appears out of sync, that may:
  - a) not be a problem (if ops order has no impact),
  - b) incurr in inconsistent server state (if not filtered out)
  - c) have the server ignore all out of order events
- if
