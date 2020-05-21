//
//  AppDelegate.swift
//  MicMuter
//
//  Created by Markus Kraus on 01.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Cocoa
import Carbon
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MicManagerDelegate, HotkeyManagerDelegate, UIManagerDelegate {
    var programaticToggleInProgress = false
    var lastVolume: Float32 = 0
    var lastInputDevice: AudioDeviceID = AudioDeviceID.max
    
    
    var hotkeyManager: HotkeyManager!
    var configManager: ConfigManager!
    var micManager: MicManager!
    var uiManager: UIManager!
    
    var window: NSWindow!
    
    override init() {
        if AppDelegate.appAlreadyRunning() {
            exit(1)
        }
        
        micManager = MicManager()
        
        hotkeyManager = HotkeyManager(runLoop: CFRunLoopGetCurrent())
        configManager = ConfigManager(hotkeyManager: hotkeyManager)
        uiManager = UIManager(config: configManager.config)
    }
    
    static func appAlreadyRunning() -> Bool {
        let currentApplication = NSRunningApplication.current
        for app in NSWorkspace.shared.runningApplications {
            if app != currentApplication && app.bundleIdentifier == currentApplication.bundleIdentifier {
                return true
            }
        }
        
        return false
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        micManager.delegate = self
        hotkeyManager.delegate = self
        uiManager.delegate = self
        
        setInitialState()
        
        restoreLastVolume()
        
        DispatchQueue.global(qos: .background).async {
            CFRunLoopRun()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if lastInputDevice != UInt32.max {
            UserDefaults.standard.set(lastInputDevice, forKey: "lastInputDevice")
            UserDefaults.standard.set(lastVolume, forKey: "lastVolume")
        }
    }
    
    func restoreLastVolume() {
        if micManager.defaultInputDeviceIsValid() {
            let previousSavedInputDevice = AudioDeviceID(UserDefaults.standard.integer(forKey: "lastInputDevice"))
            if previousSavedInputDevice != AudioDeviceID.max && previousSavedInputDevice ==  micManager.getDefaultInputDeviceId() {
                lastVolume = UserDefaults.standard.float(forKey: "lastVolume")
            }
        }
    }
    
    func onDefaultInputDeviceChanged(_ deviceId: AudioDeviceID) {
        lastInputDevice = deviceId
        
        DispatchQueue.main.async {
            self.setInitialState()
        }
    }
    
    func onDefaultInputDeviceVolumeChanged(_ volume: Float32) {
        if (!programaticToggleInProgress) {
            lastVolume = volume
        }
    }
    
    func onDefaultInputDeviceMuted(_ muted: Bool) {
        // muting the device sets the volume to 0 and then mutes it
        // we do not want to save the volume in this case
        // by setting programaticToggleInProgress to false,
        // we activate the VolumeChanged Listener again
        if (programaticToggleInProgress) {
            programaticToggleInProgress = false
        }
        
        DispatchQueue.main.async {
            self.uiManager.setMutedState(muted: muted)
        }
    }
    
    func setInitialState() {
        if micManager.defaultInputDeviceIsValid() {
            lastInputDevice = micManager.getDefaultInputDeviceId()
            lastVolume = micManager.getDefaultInputDeviceVolume()
            
            let muted = micManager.getDefaultInputDeviceMuted()
            onDefaultInputDeviceMuted(muted)
        }
    }
    
    func toggleMute() {
        if lastInputDevice != UInt32.max {
            let currentlyMuted = micManager.getDefaultInputDeviceMuted()
            if (!currentlyMuted) {
                programaticToggleInProgress = true
                micManager.setDefaultInputDeviceVolume(0)
                micManager.setDefaultInputDeviceMuted(true)
            } else if (lastVolume > 0) {
                programaticToggleInProgress = true
                micManager.setDefaultInputDeviceVolume(lastVolume)
                micManager.setDefaultInputDeviceMuted(false)
            }
        }
    }
    
    func quitWasRequested() {
        NSApplication.shared.terminate(self)
    }
    
    func muteWasRequested() {
        toggleMute()
    }
    
    func hotkeyPressed() {
        toggleMute()
    }
    
    func openConfigWasRequested() {
        configManager.openConfigWindow()
    }
}
