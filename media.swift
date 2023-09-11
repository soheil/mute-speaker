import Cocoa
import Foundation
import CoreFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private let mediaRemoteFrameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework"
    private let getNowPlayingFunctionName = "MRMediaRemoteGetNowPlayingInfo" as CFString
    private let getBundleIdentifierFunctionName = "MRNowPlayingClientGetBundleIdentifier" as CFString
    private let objcLibPath = "/usr/lib/libobjc.A.dylib"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let bundle = loadFramework()
        
        guard let getNowPlayingFunctionPointer = CFBundleGetFunctionPointerForName(bundle, getNowPlayingFunctionName) else { return }
        typealias GetNowPlayingFunctionType = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let getNowPlayingFunction = unsafeBitCast(getNowPlayingFunctionPointer, to: GetNowPlayingFunctionType.self)
        
        guard let getBundleIdentifierFunctionPointer = CFBundleGetFunctionPointerForName(bundle, getBundleIdentifierFunctionName) else { return }
        typealias GetBundleIdentifierFunctionType = @convention(c) (AnyObject?) -> String
        let getBundleIdentifierFunction = unsafeBitCast(getBundleIdentifierFunctionPointer, to: GetBundleIdentifierFunctionType.self)
        
        getNowPlayingInformation(using: getNowPlayingFunction, andThen: getBundleIdentifierFunction)
    }
    
    private func loadFramework() -> CFBundle {
        CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: mediaRemoteFrameworkPath))
    }
    
    private func getNowPlayingInformation(using function: @escaping ((DispatchQueue, @escaping ([String: Any]) -> Void) -> Void),
                                          andThen getBundleIdentifierFunction: @convention(c) (AnyObject?) -> String) {
        function(DispatchQueue.main) { (information) in
            self.logInformation(information)
            self.getBundleIdentifier(fromInformation: information, withFunction: getBundleIdentifierFunction)
        }
    }
    
    private func logInformation(_ information: [String: Any]) {
        let infoArtist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String
        let infoTitle = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String
        let infoAlbum = information["kMRMediaRemoteNowPlayingInfoAlbum"] as? String
        
        NSLog("%@", infoArtist ?? "")
        NSLog("%@", infoTitle ?? "")
        NSLog("%@", infoAlbum ?? "")
    }
    
    private func getBundleIdentifier(fromInformation information: [String: Any],
                                     withFunction function: (AnyObject?) -> String) {
        let protobufClass: AnyClass? = NSClassFromString("_MRNowPlayingClientProtobuf")
        let handle: UnsafeMutableRawPointer! = dlopen(objcLibPath, RTLD_NOW)
        
        guard let object = initProtobufObject(withHandle: handle, class: protobufClass, andInformation: information) else { return }
        
        _ = function(object)
        
        dlclose(handle)
    }
    
    private func initProtobufObject(withHandle handle: UnsafeMutableRawPointer!, class protobufClass: AnyClass?, andInformation information: [String: Any]) -> AnyObject? {
        let objcMsgSendFunction = unsafeBitCast(dlsym(handle, "objc_msgSend"), 
                                                to:(@convention(c)(AnyClass?, Selector?) -> AnyObject).self)
        let object = objcMsgSendFunction(protobufClass, Selector("alloc"))
        
        let objcMsgSendWithDataFunction = unsafeBitCast(dlsym(handle, "objc_msgSend"), 
                                                        to:(@convention(c)(AnyObject?, Selector?, AnyObject?) -> Void).self)
        let infoPropertiesData = information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"]
        
        objcMsgSendWithDataFunction(object, Selector("initWithData:"), infoPropertiesData as AnyObject?)
        
        return object
    }
}

let app = NSApplication.shared
let appDelegate = AppDelegate()

app.delegate = appDelegate
app.run()
