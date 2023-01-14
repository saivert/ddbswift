import Foundation
@_exported import Glibc
@_exported import ddbswift_C

func start() -> Int32 {
    0
}

func stop() -> Int32 {
    0
}

func message(id: UInt32, ctx: UInt, p1: UInt32, p2: UInt32) -> Int32 {
    0
}

enum Constants {
    static let id = NSString("someid")
    static let name = NSString("Swift DDB")
    static let descr = NSString("swift!!")
    static let copyright = NSString("gpl")
    static let x: StaticString = "https://saivert.com/"
    static let prefix: NSString = NSString("tone")
}

var plug = DB_plugin_t(
    type: Int32(DB_PLUGIN_DECODER),
    api_vmajor: Int16(DB_API_VERSION_MAJOR),
    api_vminor: Int16(DB_API_VERSION_MINOR),
    version_major: 0,
    version_minor: 1,
    flags: 0,
    reserved1: 0,
    reserved2: 0,
    reserved3: 0,
    id: Constants.id.utf8String,
    name: Constants.name.utf8String,
    descr: Constants.descr.utf8String,
    copyright: Constants.copyright.utf8String,
    website: UnsafePointer(OpaquePointer(Constants.x.utf8Start)),
    command: nil,
    start: start,
    stop: stop,
    connect: { () -> Int32 in
        print("Swift: Connect called!")
        return 0
    },
    disconnect: nil,
    exec_cmdline: nil,
    get_actions: nil,
    message: message,
    configdialog: nil
)

func allocToneFileInfo() -> UnsafeMutablePointer<toneFileInfo> {
    let ptr: UnsafeMutablePointer<toneFileInfo> = UnsafeMutablePointer<toneFileInfo>.allocate(
        capacity: 1)
    ptr.initialize(to: toneFileInfo())
    ptr.pointee.file = nil
    ptr.pointee.info.file = nil
    ptr.pointee.frequency = 440
    return ptr
}

func read(
    info: UnsafeMutablePointer<DB_fileinfo_t>?, bytes: UnsafeMutablePointer<CChar>?, size: Int32
) -> Int32 {
    // print("swift: read")
    let toneinfo = UnsafeMutablePointer<toneFileInfo>(OpaquePointer(info))!

    if size <= 0 {
        return 0
    }

    let freq = Float(toneinfo.pointee.frequency)
    let cap = Int(size) / MemoryLayout<Float>.size

    bytes!.withMemoryRebound(
        to: Float.self, capacity: cap,
        { (a) in
            for sample in 0..<cap {

                let samplevalue = sin(toneinfo.pointee.m_phase * Float.pi * 2)
                toneinfo.pointee.m_phase += freq / 48000 / 2
                toneinfo.pointee.m_phase -= floor(toneinfo.pointee.m_phase)

                a[sample] = Float(samplevalue * 0.5)
                a[sample + 1] = Float(samplevalue * 0.5)
            }
        })

    toneinfo.pointee.info.readpos += 1

    return size
}

var inputplg = DB_decoder_t(
    plugin: plug,
    open: { (hints: UInt32) -> UnsafeMutablePointer<DB_fileinfo_t>? in
        print("swift: open")
        let ptr = allocToneFileInfo()
        return UnsafeMutablePointer<DB_fileinfo_t>(OpaquePointer(ptr))
    },
    init: {
        (info: UnsafeMutablePointer<DB_fileinfo_t>?, it: UnsafeMutablePointer<DB_playItem_t>?)
            -> Int32 in
        print("swift: init")
        let toneinfo = UnsafeMutablePointer<toneFileInfo>(OpaquePointer(info))!

        if toneinfo.pointee.file == nil {
            deadbeef.pl_lock()
            let uri = String(cString: deadbeef.pl_find_meta(it, ":URI")!)
            deadbeef.pl_unlock()

            toneinfo.pointee.file = deadbeef.fopen(uri)

            toneinfo.pointee.frequency = deadbeef.pl_find_meta_int(it, "frequency", 440)

            if toneinfo.pointee.file == nil {
                print("failed to open file ", uri)
                return -1
            }
        }

        toneinfo.pointee.info.plugin = UnsafeMutablePointer<DB_decoder_t>(&inputplg)

        toneinfo.pointee.info.readpos = 0

        toneinfo.pointee.info.fmt = ddb_waveformat_t(
            bps: 32,
            channels: 2,
            samplerate: 48000,
            channelmask: 3,
            is_float: 1,
            is_bigendian: 0)

        return 0
    },
    free: { (info: UnsafeMutablePointer<DB_fileinfo_t>?) -> Void in
        print("swift: free")
        if let toneinfo = UnsafeMutablePointer<toneFileInfo>(OpaquePointer(info)) {
            if toneinfo.pointee.file != nil {
                deadbeef.fclose(toneinfo.pointee.file)
            }
            toneinfo.deinitialize(count: 1)
            toneinfo.deallocate()
        }
    },
    read: read,
    seek: { (info: UnsafeMutablePointer<DB_fileinfo_t>?, time: Float) -> Int32 in
        print("swift: seek")
        return -1
    },
    seek_sample: { (info: UnsafeMutablePointer<DB_fileinfo_t>?, sample: Int32) -> Int32 in
        print("swift: seek sample")
        return -1
    },
    insert: {
        (
            plt: UnsafeMutablePointer<ddb_playlist_t>?, after: UnsafeMutablePointer<DB_playItem_t>?,
            fname: UnsafePointer<CChar>?
        ) -> UnsafeMutablePointer<DB_playItem_t>? in
        let fname_string = fname.map { String(cString: $0) } ?? ""
        print("swift: insert" + (fname.map { " " + String(cString: $0) } ?? ""))

        do {
            var contents = try String(contentsOfFile: fname_string, encoding: String.Encoding.utf8)
            let freq = contents.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            let it = deadbeef.pl_item_alloc_init(fname, plug.id)!
            // deadbeef.pl_add_meta (it, ":FILE_SIZE", "10000")
            deadbeef.pl_add_meta(it, ":FILETYPE", "tone")
            deadbeef.pl_add_meta(it, ":CHANNELS", "2")
            deadbeef.pl_add_meta(it, ":BPS", "16")
            deadbeef.pl_add_meta(it, ":SAMPLERATE", "48000")
            deadbeef.pl_add_meta(it, "artist", "the tone generators")
            deadbeef.pl_add_meta(it, "title", "Frequency \(freq)")
            deadbeef.pl_add_meta(it, "frequency", freq)
            // deadbeef.pl_set_meta_int (it, ":BITRATE", 705600)
            let after = deadbeef.plt_insert_item(plt, after, it)
            deadbeef.pl_item_unref(it)
            return after

        } catch {
            return nil
        }

    },
    numvoices: nil,
    mutevoice: nil,
    read_metadata: { (it: UnsafeMutablePointer<DB_playItem_t>?) -> Int32 in
        print("swift: read metadata")
        return 0
    },
    write_metadata: { (it: UnsafeMutablePointer<DB_playItem_t>?) -> Int32 in
        print("swift: write metadata")
        return 0
    },
    exts: nil,
    prefixes: nil,
    open2: nil
        // open2: {(hints: UInt32, it: UnsafeMutablePointer<DB_playItem_t>?) -> UnsafeMutablePointer<DB_fileinfo_t>? in
        //         print("swift: open2")
        //         let ptr = allocToneFileInfo()
        //         return UnsafeMutablePointer(OpaquePointer(ptr))
        //     }
)

var deadbeef: DB_functions_t!

var exts = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 2)

@_cdecl("libddbswift_load") func libddbswift_load(api: UnsafePointer<DB_functions_t>)
    -> UnsafeMutablePointer<DB_decoder_t>
{

    deadbeef = api.pointee

    exts.initialize(repeating: nil, count: 2)
    exts[0] = Constants.prefix.utf8String
    inputplg.exts = exts

    return UnsafeMutablePointer<DB_decoder_t>(&inputplg)
}
