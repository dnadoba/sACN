//
//  sACN.swift
//  
//
//  Created by David Nadoba on 17.11.19.
//

import Foundation
import Network

extension FixedWidthInteger {
    /// converts from host byte order to network byte order (big-endian)
    var networkByteOrder: Self { bigEndian }
}

extension UnsignedInteger {
    /// A collection containing the words of this value’s binary representation, in order of the host system.
    var data: Data {
        var copy = self
        return Data(bytes: &copy, count: MemoryLayout<Self>.size)
    }
}

extension UUID {
    /// Data of `self` in big-endian order.
    var data: Data {
        Data([
            uuid.0, uuid.1, uuid.2,  uuid.3,  uuid.4,  uuid.5,  uuid.6,  uuid.7,
            uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15,
        ])
    }
}

fileprivate let universeDiscovery: UInt16 = 64214

extension IPv4Address {
    /// The streaming Architecture for Control Networks (ACN) protocol IPv4 multicast address for the given `universe`.
    /// - Parameter universe: a sACN universe
    /// - Returns: an IPv6Address for the given `universe`
    public static func sACN(universe: UInt16) -> IPv4Address? {
        IPv4Address(Data([239, 255] + universe.networkByteOrder.data))
    }
    /// The streaming Architecture for Control Networks (ACN) protocol IPv4 multicast address for universe discovery (64214).
    public static var sACNUniverseDiscovery: IPv4Address { .sACN(universe: universeDiscovery)! }
}

extension IPv6Address {
    /// The streaming Architecture for Control Networks (ACN) protocol IPv6 multicast address for the given `universe`.
    /// - Parameter universe: a sACN universe
    /// - Returns: an IPv6Address for the given `universe`
    public static func sACN(universe: UInt16) -> IPv6Address? {
        IPv6Address(Data([
            0xFF, // 1
            0x18, // 2
            0x00, // 3
            0x00, // 4
            0x00, // 5
            0x00, // 6
            0x00, // 7
            0x00, // 8
            0x00, // 9
            0x00, // 10
            0x00, // 11
            0x00, // 12
            0x83, // 13
            0x00, // 14 - reserved
                  // 15 - Universe/Synchronization Address – Hi byte
                  // 16 - Universe/Synchronization Address – Lo byte
        ] + universe.networkByteOrder.data))
    }
    /// The streaming Architecture for Control Networks (ACN) protocol IPv6 multicast address for universe discovery (64214).
    public static var sACNUniverseDiscovery: IPv6Address { .sACN(universe: universeDiscovery)! }
}

extension NWEndpoint.Port {
    /// The streaming Architecture for Control Networks (ACN) protocol default port.
    public static let sACN: NWEndpoint.Port = 5568
}

let rootLayerTemplate = Data([
    // ---- Root Layer ------
    // Preamble Size
    0x00, 0x10,
    // Post-amble Size
    0x00, 0x00,
    // ACN Package Identifier - Identifies this packet as E1.17
    0x41, 0x53, 0x43, 0x2d, 0x45, 0x31, 0x2e, 0x31, 0x37, 0x00, 0x00, 0x00,
    // Flags and Length - not yet set
    0x00, 0x07,
    // Vector - Identifies RLP Data as 1.31 Protocol PDU
    0x00, 0x00, 0x00, 0x04,
    // Sender's CID (Component Identifier) - not yet set
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
])
fileprivate let uuidSize = 16


/// combines the first 12 bits of `length` with the first 4 bits of `flags` into a single Flags and Length Field (UInt16) according to the E1.31 specification..
/// - Parameters:
///   - length: The length. Only the first 12 bits are used. The last 4 bits are ignored.
///   - flags: The flags. Only the first 4 bis are used. The last 4 btis are ignored.
/// - Returns: Length and Flags field according to the E1.31 specification.
func flagsAndLength(length: UInt16, flags: UInt8 = 0x07) -> UInt16 {
    // Low 12 bits = PDU length
    let escapedLength = length              & 0b0000_1111_1111_1111
    // High 4 bits = 0x7
    let escapedFlags  = UInt16(flags) << 12 & 0b1111_0000_0000_0000
    return escapedFlags | escapedLength
}

struct RootLayer {
    private static let lengthStartingByte: UInt16 = 16
    private static let cidRange = 22...37
    private static let flagsAndLengthRange = 16...17
    
    private let cidData: Data
    init(cid: UUID) {
        self.cidData = cid.data
    }
    var count: Int { rootLayerTemplate.count }
    func write(to data: inout Data, fullPacketLength: UInt16) {
        data[0..<rootLayerTemplate.count] = rootLayerTemplate
        data[RootLayer.cidRange] = cidData
        let pduLength = fullPacketLength - (Self.lengthStartingByte - 1)
        data[RootLayer.flagsAndLengthRange] = flagsAndLength(length: pduLength).networkByteOrder.data
    }
}

let dmxDataFramingLayerTemplate = Data([
    // ---- E1.31 Framing Layer ------
    // Flags and Length - not yet set
    0x00, 0x07,
    // Vector - Identifies 1.31 data as DMP Protocol PDU
    0x00, 0x00, 0x00, 0x02,
    // Source Name - Userassigned Name of Source - not yet set
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    // Priority - Data priority if multiple sources
    100,
    // Synchronization Address - Universe address on which sync packets will be sent - not yet set
    0x00, 0x00,
    // Sequence Number - To detect duplicate or out of order packets - not yet set
    0x00,
    // Options Flags
    // Bit 7 = Preview_Data
    // Bit 6 = Stream_Terminated
    // Bit 5 = Force_Synchronization
    0x00,
    // Universe Number - Identifier for a distinct stream of DMX512-A [DMX] Data - not yet set
    0x00, 0x00,
])

struct DMXDataFramingOptions: OptionSet, RawRepresentable {
    static let previewData = DMXDataFramingOptions(rawValue: 0b0100_0000)
    static let streamTerminatd = DMXDataFramingOptions(rawValue: 0b0010_0000)
    static let forceSynchronization = DMXDataFramingOptions(rawValue: 0b0001_0000)
    static let none: DMXDataFramingOptions = []
    var rawValue: UInt8
}


struct DMXDataFramingLayer {
    private static let lengthStartingByte: UInt16 = 48
    static let flagsAndLengthRange = 38...39
    static let sourceNameRange = 44...107
    static let priorityRange = 108..<109
    static let synchronizationUniverseRange = 109...110
    static let sequenceNumberRange = 111...111
    static let optionsRange = 112...112
    static let universeRange = 113...114
    
    
    var sourceNameData: Data
    var universe: UInt16
    var priority: UInt8 = 100
    var synchronizationUniverse: UInt16 = 0
    var options: DMXDataFramingOptions = .none
    var count: Int { dmxDataFramingLayerTemplate.count }
    
    init(
       sourceName: String,
       universe: UInt16,
       priority: UInt8 = 100,
       synchronizationUniverse: UInt16 = 0,
       options: DMXDataFramingOptions = .none
    ) {
        self.universe = universe
        self.priority = priority
        self.synchronizationUniverse = synchronizationUniverse
        self.options = options
        sourceNameData = String(
            sourceName.utf8.prefix(DMXDataFramingLayer.sourceNameRange.count - 1)
        )?.data(using: .utf8) ?? Data()
    }
    
    func write(to data: inout Data, fullPacketLength: UInt16, sequenceNumber: UInt8) {
        data[38...114] = dmxDataFramingLayerTemplate
        let pduLength = fullPacketLength - (Self.lengthStartingByte - 1)
        data[DMXDataFramingLayer.flagsAndLengthRange] = flagsAndLength(length: pduLength).networkByteOrder.data
        
        
        let sourceNameRange = DMXDataFramingLayer.sourceNameRange.lowerBound..<(DMXDataFramingLayer.sourceNameRange.lowerBound + sourceNameData.count)
        data[sourceNameRange] = sourceNameData
        
        data[DMXDataFramingLayer.priorityRange] = priority.networkByteOrder.data
        data[DMXDataFramingLayer.synchronizationUniverseRange] = synchronizationUniverse.networkByteOrder.data
        data[DMXDataFramingLayer.sequenceNumberRange] = sequenceNumber.networkByteOrder.data
        data[DMXDataFramingLayer.optionsRange] = options.rawValue.networkByteOrder.data
        data[DMXDataFramingLayer.universeRange] = universe.networkByteOrder.data
    }
}

let dmpLayerTemplate = Data([
    // ----- Device Management Protocol Layer -----
    // Flags and Length - not yet set
    0x00, 0x07,
    // Vector - Identifies DMP Set Property Message PDU
    0x02,
    // Address Type & Data Type - Identifies format of address and data
    0xa1,
    // First Property Address - Indicates DMX512-A START Code is at DMP address 0
    // Receivers shall discard the packet if the received value is not 0x0000.
    0x00, 0x00,
    // Address Increment - Indicates each property is 1 octet
    0x00, 0x01,
    // Property value count - 0x0001 -- 0x0201
    0x00, 0x01,
    // Property values - DMX512-A START Code + data
    0x00,
])
/// Device Management Protocol Layer
struct DMPLayer {
    private static let lengthStartingByte: UInt16 = 115
    static let propertyValueCountRange = 123...124
    static let flagsAndLengthRange = 115...116
    
    var dmxData: Data
    var count: Int {
        dmpLayerTemplate.count + dmxData.count
    }
    func write(
        to data: inout Data,
        fullPacketLength: UInt16
    ) {
        assert(dmxData.count <= 512)
        data[115...125] = dmpLayerTemplate
        let pduLength = fullPacketLength - (Self.lengthStartingByte - 1)
        data[DMPLayer.flagsAndLengthRange] = flagsAndLength(length: pduLength).networkByteOrder.data
        data[DMPLayer.propertyValueCountRange] = UInt16(1 + dmxData.count).networkByteOrder.data
        data[126..<(126 + dmxData.count)] = dmxData
    }
}

struct DataPacket {
    var rootLayer: RootLayer
    var framingLayer: DMXDataFramingLayer
    var dmpLayer: DMPLayer
    
    var count: Int {
        rootLayer.count + framingLayer.count + dmpLayer.count
    }
    func getData(sequenceNumber: UInt8) -> Data {
        let count = self.count
        var data = Data(count: count)
        rootLayer.write(to: &data, fullPacketLength: UInt16(count))
        framingLayer.write(to: &data, fullPacketLength: UInt16(count), sequenceNumber: sequenceNumber)
        dmpLayer.write(to: &data, fullPacketLength: UInt16(count))
        return data
    }
}
#if os(iOS) || os(tvOS)
import UIKit
#endif
public func getDeviceName() -> String {
    #if os(iOS) || os(tvOS)
    return UIDevice.current.name
    #elseif os(macOS)
    return Host.current().localizedName!
    #endif
}
/// IPv4/IPv6 UDP Connection to send DMX Data to a given Universe
/// Note: this class is not threadsafe
public final class Connection {
    public enum IPVersion {
        case v4
        case v6
        func hostForUnvierse(_ universe: UInt16) -> NWEndpoint.Host? {
            switch self {
            case .v4: return IPv4Address.sACN(universe: universe).map(NWEndpoint.Host.ipv4(_:))
            case .v6: return IPv6Address.sACN(universe: universe).map(NWEndpoint.Host.ipv6(_:))
            }
        }
    }
    public static let defaultParameters: NWParameters = {
        let defaultParameter = NWParameters.udp
        defaultParameter.serviceClass = .responsiveData
        return defaultParameter
    }()
    public let connection: NWConnection
    public let queue: DispatchQueue
    
    /// Sender's Component Identifier
    public let cid: UUID
    /// Source Name - Userassigned Name of Source
    public let sourceName: String
    
    private let rootLayer: RootLayer
    private let dataFramginLayer: DMXDataFramingLayer
    public private(set) var sequenceNumber: UInt8 = 0
    
    /// Starts a UDP Unicast or Multicast Connection, depending on the given `endpoint`, for the given `endpoint`
    /// - Parameters:
    ///   - endpoint: sACN endpoint.
    ///   - universe: valid DMX Universe. 1 - 64000.
    ///   - cid: Sender's Component Identifier - should be uninque for each device. Default will generate a random UUID.
    ///   - sourceName: Source Name - Userassigned Name of Source. Default is the device name.
    ///   - queue: DispatchQueue used for NWConnection.
    ///   - parameters: custom parameters for NWConnection. Must be UDP. Defaults to UDP with `serviceClass` set to `.responsiveData`.
    public init(
        endpoint: NWEndpoint,
        universe: UInt16,
        cid: UUID = .init(),
        sourceName: String = getDeviceName(),
        queue: DispatchQueue? = nil,
        parameters: NWParameters? = nil
    ) {
        self.queue = queue ?? DispatchQueue(label: "sACN.udp-send-queue-for-universe-\(universe)")
        self.cid = cid
        self.sourceName = sourceName
        rootLayer = RootLayer(cid: cid)
        dataFramginLayer = .init(sourceName: sourceName, universe: universe)
        
        let parameters = parameters ?? Connection.defaultParameters
        
        // could not find a better way to detect if `NWParameters` is configured for UDP
        assert(parameters.debugDescription.lowercased().contains("udp"), "parameters must be for a UDP connection")
        
        self.connection = NWConnection(
            to: endpoint,
            using: parameters
        )
        
        connection.start(queue: self.queue)
    }
    
    /// Starts a IPv4/IPv6 UDP Multicast Connection for a given `universe`
    /// - Parameters:
    ///   - universe: valid DMX Universe. 1 - 64000. will crash if the universe can not be converted to a IPv4/IPv6 Address
    ///   - ipVersion: version of the Internet Protocol to use. Default is `.v4`.
    ///   - port: UPD port of the connection. Default is 5568 wich is the sACN default port.
    ///   - cid: Sender's Component Identifier - should be uninque for each device. Default will generate a random UUID.
    ///   - sourceName: Source Name - Userassigned Name of Source. Default is the device name.
    ///   - queue: DispatchQueue used for NWConnection/
    ///   - parameters: custom parameters for NWConnection. Must be UDP. Defaults to UDP with `serviceClass` set to `.responsiveData`.
    public convenience init(
        universe: UInt16,
        ipVersion: IPVersion = .v4,
        port: NWEndpoint.Port = .sACN,
        cid: UUID = .init(),
        sourceName: String = getDeviceName(),
        queue: DispatchQueue? = nil,
        parameters: NWParameters? = nil
    ) {
        guard let host = ipVersion.hostForUnvierse(universe) else {
            fatalError("could not create ip address for universe \(universe) IP \(ipVersion)")
        }
        self.init(
            endpoint: .hostPort(host: host, port: .sACN),
            universe: universe,
            cid: cid,
            sourceName: sourceName,
            queue: queue,
            parameters: parameters
        )
    }
    
    private func getNextSequenceNumber() -> UInt8 {
        defer { sequenceNumber &+= 1 }
        return sequenceNumber
    }
    /// Send the given DMX Data to `universe`
    /// - Parameter
    ///   - data: DMX data. data count must be smaller or euqal to 512
    ///   - priority:  sACN Package Priority beteween 1 and 200. Default is 100
    ///   - isPreviewData:  default is false
    public func sendDMXData(_ data: Data, priority: UInt8 = 100, isPreviewData: Bool = false) {
        assert(data.count <= 512, "DMX data count must be smaller or equal to 512")
        let dmpLayer = DMPLayer(dmxData: data)
        var framingLayer = dataFramginLayer
        framingLayer.priority = priority
        if isPreviewData {
            framingLayer.options.insert(.previewData)
        } else {
            framingLayer.options.remove(.previewData)
        }
        let packet = DataPacket(rootLayer: rootLayer, framingLayer: framingLayer, dmpLayer: dmpLayer)
        let packetData = packet.getData(sequenceNumber: getNextSequenceNumber())
        connection.send(content: packetData, completion: .idempotent)
    }
    deinit {
        connection.cancel()
    }
}
