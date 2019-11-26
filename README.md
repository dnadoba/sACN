# sACN

Swift Package for macOS, iOS and tvOS to send sACN (E1.31) DMX Data over UDP using `Network.framework`.

## Usage
You only need to initate a `MulticastConnection` for a universe and you can start sending DMX Data.

```swift
let client = MulticastConnection(universe: 1)
client.sendDMXData(Data([0, 10, 255, 0, 0, 0, 255]))
```

## Supported Features
- Sending DMX Data via UDP Multicast
- sACN Package Priority
- Preview Data

## Known Limitations
- Recieving DMX Data (have a look at this repository: https://github.com/jkmassel/ACNKit)
- can not send packages via UDP Unicast
- does only support IPv4 and not IPv6
