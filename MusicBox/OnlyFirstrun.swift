//
//  OnlyFirstrun.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/11/20.
//

import Foundation
import AppTrackingTransparency

let configStore = UserDefaults.standard

func checkAppUpgrade(firstrun: () -> (), updated: () -> (), nothingChanged: () -> ()) {
    let currentVersion = Bundle.main.object(forInfoDictionaryKey:     "CFBundleShortVersionString") as? String
    let versionOfLastRun = UserDefaults.standard.object(forKey: "VersionOfLastRun") as? String

    if versionOfLastRun == nil {
        // First start after installing the app
        firstrun()

    } else if versionOfLastRun != currentVersion {
        // App was updated since last run
        updated()

    } else {
        // nothing changed
        nothingChanged()
    }

    UserDefaults.standard.set(currentVersion, forKey: "VersionOfLastRun")
    UserDefaults.standard.synchronize()
}


func OnlyOnceAfterInstall() {
    // config 초기 세팅
    configStore.set("Paper: White paper with fibers", forKey: .cfgPaperTextureName)
    configStore.set("Background: Melamine-wood-2", forKey: .cfgBackgroundTextureName)
    configStore.set(8, forKey: .cfgDurationOfNoteSound)
    configStore.set(10, forKey: .cfgInstrumentPatch)
    configStore.set(true, forKey: .cfgPlayInSilentMode)
    configStore.set(10, forKey: .cfgAutosaveInterval)
    
}

func TrackingTransparencyPermissionRequest() {
    
    if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
            
        })
    }
}
