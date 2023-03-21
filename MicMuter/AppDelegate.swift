//
//  AppDelegate.swift
//  MicMuter
//
//  Created by Markus Kraus on 01.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Cocoa
import Carbon
import Combine
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MicManagerDelegate, HotkeyManagerDelegate, UIManagerDelegate {
    private var programaticToggleInProgress = false
    private var lastVolume: Float32 = 0
    private var lastInputDevice: AudioDeviceID = AudioDeviceID.max
    
    private var settings: Settings
    private var hotkeyManager: HotkeyManager
    private var configManager: ConfigManager
    private var micManager: MicManager
    private var menuManager: MenuManager
    private var watchers = Set<AnyCancellable>()
    
    var window: NSWindow!
    
    override init() {
        if AppDelegate.appAlreadyRunning() {
            exit(1)
        }
        
        micManager = MicManager()
        
        settings = Settings()
        hotkeyManager = HotkeyManager(runLoop: CFRunLoopGetCurrent())
        configManager = ConfigManager(settings: settings, hotkeyManager: hotkeyManager)
        menuManager = MenuManager(settings: settings)
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
        menuManager.delegate = self
        
        loadCurrentInputDeviceState()
        
        restoreLastVolume()
        
        DispatchQueue.global(qos: .background).async {
            CFRunLoopRun()
        }

        settings.$hotkeysEnabled
            .sink(receiveValue: { enabled in
                if enabled {
                    if !self.hotkeyManager.started() {
                        self.hotkeyManager.start()
                        if !self.hotkeyManager.started() {
                            // the user has to manually enable the "Input Monitoring"
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
                            
                            // as the hotkeymanager could not be started, we untoggle the checkbox
                            DispatchQueue.main.async {
                                self.settings.objectWillChange.send()
                                self.settings.hotkeysEnabled = false
                            }
                        }
                    }
                } else {
                    self.hotkeyManager.stop()
                }
            })
            .store(in: &self.watchers)
        
        settings.$hotkey.sink(receiveValue: { hotkey in
            self.hotkeyManager.hotkey = hotkey
        }).store(in: &self.watchers)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if lastInputDevice != UInt32.max && lastVolume > 0 {
            UserDefaults.standard.set(lastInputDevice, forKey: "lastInputDevice")
            UserDefaults.standard.set(lastVolume, forKey: "lastVolume")
        }
    }
    
    func restoreLastVolume() {
        if micManager.defaultInputDeviceIsValid() {
            let previousSavedInputDevice = AudioDeviceID(UserDefaults.standard.integer(forKey: "lastInputDevice"))
            if previousSavedInputDevice != AudioDeviceID.max && previousSavedInputDevice == micManager.getDefaultInputDeviceId() {
                lastVolume = UserDefaults.standard.float(forKey: "lastVolume")
                
                if lastVolume == 0 {
                    lastVolume = micManager.getDefaultInputDeviceVolume()
                }
            }
        }
    }
    
    func onDefaultInputDeviceChanged(_ deviceId: AudioDeviceID) {
        lastInputDevice = deviceId
        
        DispatchQueue.main.async {
            self.loadCurrentInputDeviceState()
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
            self.menuManager.setMutedState(muted: muted)
        }
    }
    
    func loadCurrentInputDeviceState() {
        if micManager.defaultInputDeviceIsValid() {
            programaticToggleInProgress = false
            
            lastInputDevice = micManager.getDefaultInputDeviceId()
            lastVolume = micManager.getDefaultInputDeviceVolume()
            
            let muted = micManager.getDefaultInputDeviceMuted()
            onDefaultInputDeviceMuted(muted)
        }
    }
    
    func toggleMute() {
        if micManager.defaultInputDeviceIsValid() {
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
        NSApp.activate(ignoringOtherApps: true)
    }
}
