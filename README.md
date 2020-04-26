# sACN (E1.31)

Swift Package for macOS, iOS and tvOS to send sACN (E1.31) DMX Data over UDP using `Network.framework`.

## Usage
You only need to initiate a `Connection` for a universe and you can start sending DMX Data.

```swift
let connection = Connection(universe: 1)
connection.sendDMXData(Data([0, 10, 255, 0, 0, 0, 255]))
```
If you want to use UDP Unicast instead of Multicast, you can simply sepcify an endpoint yourself:
```swift
let connection = Connection(endpoint: .hostPort(host: "192.168.2.102", .sACN), universe: 2)
connection.sendDMXData(Data([0, 10, 255, 0, 0, 0, 255]))
```

## Supported Features
- Sending DMX Data via UDP Multicast and Unicast on IPv4/IPv6
- sACN Package Priority
- Preview Data

## Advanced Usage

### Using IPv6
For Unicast, you need to specify an IPv6 Endpoint. For Multicast, you need to speicify the ipVersion:
```swift
let connection = Connection(universe: 1, ipVersion: .v6)
```

### Priority 
After you created a `connection`, you can set the priority per packet using the `sendDMXData(_:proprity:isPreviewData:)` method. Default priority is `100`.
```swift
connection.sendDMXData(data, priority: 200)
```
### Preview Data
After you created a `connection`, you can choose per packet if it is preview data or not using the  `sendDMXData(_:priority:isPreviewData:)` method. `isPreviewData` defaults to `false`.
```swift
connection.sendDMXData(data, isPreviewData: true)
```
### Other Connection Initialization Configuration
`Connection` does support customizing the port, component identifier (CID), source name, `DispatchQueue` and `NWConneciton.Parameter`. Look into the Documentaiton for more information.
```swift
public convenience init(
    universe: UInt16,
    ipVersion: IPVersion = .v4,
    port: NWEndpoint.Port = .sACN,
    cid: UUID = .init(),
    sourceName: String = getDeviceName(),
    queue: DispatchQueue? = nil,
    parameters: NWParameters? = nil
)
```



## Known Limitations
- Receiving DMX Data (have a look at this repository: https://github.com/jkmassel/ACNKit)
 
