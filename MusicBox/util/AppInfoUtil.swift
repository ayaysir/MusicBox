//
//  AppInfoUtil.swift
//  MusicBox
//
//  Created by 윤범태 on 3/1/24.
//

import Foundation

struct AppInfoUtil {
    private init() {}
    
    static func appVersionAndBuild() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return version + "(" + build + ")"
    }
    
    static func appName() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    static func osInfo() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
}
