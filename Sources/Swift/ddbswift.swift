@_exported import Glibc
@_exported import ddbswift_C
import Foundation

public struct plugin {

    public init() {
    }

    public func start() -> Int32 {
        return 0
    }

    public func stop() -> Int32 {
        return 0
    }

    public func message(id: UInt32, ctx: UInt, p1: UInt32, p2: UInt32) -> Int32 {
        if id == DB_EV_SONGCHANGED {
            seek(1000)
            _ = deadbeef.sendmessage(UInt32(DB_EV_SEEK), 0, 10000, 0)
        }
        return 0
    }
}

func start() -> Int32 {
    plginstance.start()
}

func stop() -> Int32 {
    plginstance.stop()
}

func message(id: UInt32, ctx: UInt, p1: UInt32, p2: UInt32) -> Int32 {
    plginstance.message(id: id, ctx: ctx, p1: p1, p2: p2)
}

enum Constants {
static let name = NSString("Swift DDB")
static let descr = NSString("swift!!")
static let copyright = NSString("gpl")
static let x: StaticString = "https://saivert.com/"
}

var plug = DB_plugin_t(
    type: Int32(DB_PLUGIN_MISC),
    api_vmajor: Int16(DB_API_VERSION_MAJOR),
    api_vminor: Int16(DB_API_VERSION_MINOR),
    version_major: 0,
    version_minor: 1,
    flags: 0,
    reserved1: 0,
    reserved2: 0,
    reserved3: 0,
    id: strdup("someid"),
    name: Constants.name.utf8String,
    descr: Constants.descr.utf8String,
    copyright: Constants.copyright.utf8String,
    website: UnsafePointer(OpaquePointer(Constants.x.utf8Start)),
    command: nil,
    start: start,
    stop: stop,
    connect: nil,
    disconnect: nil,
    exec_cmdline: nil,
    get_actions: nil,
    message: message,
    configdialog: nil
)

var deadbeef : DB_functions_t!
var plginstance : plugin!

@_cdecl("libddbswift_load") func libddbswift_load(api: UnsafePointer<DB_functions_t>) -> UnsafeMutablePointer<DB_plugin_t> {

    deadbeef = api.pointee
    plginstance = plugin()

    return UnsafeMutablePointer<DB_plugin_t>(&plug)
}


