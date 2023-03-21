//
//  Settings.swift
//  MicMuter
//
//  Created by Markus Kraus on 19.03.23.
//  Copyright © 2023 Markus Kraus. All rights reserved.
//
// While almost all the logic is handled in AppDelegate, we handle persisting of the settings/preferences in this class

import Foundation
import Combine
import ServiceManagement

struct JSONHotkey : Codable {
    var keycode: Int64
    var flags: Int
}

class Settings : ObservableObject {
    @Published var hotkey: KeyInfo? = nil
    @Published var startAtLogin = UserDefaults.standard.object(forKey: "startAtLogin") as? Bool ?? false
    @Published var hotkeysEnabled = UserDefaults.standard.object(forKey: "hotkeysEnabled") as? Bool ?? false
    @Published var showTouchBarButton = UserDefaults.standard.object(forKey: "showTouchBarButton") as? Bool ?? false
    private var watchers = Set<AnyCancellable>()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "hotkey") {
            do {
                let decoder = JSONDecoder()
                let d = try decoder.decode(JSONHotkey.self, from: data)
                self.hotkey = KeyInfo(key: d.keycode, flags: KeyFlags(rawValue: d.flags))
            } catch {
                print("invalid hotkey decode: \(error)")
            }
        }
        
        $hotkey
            .dropFirst()
            .sink(receiveValue: { newValue in
                if newValue != nil {
                    do {
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(JSONHotkey(keycode: newValue!.key, flags: newValue!.flags.rawValue))
                        UserDefaults.standard.set(data, forKey: "hotkey")
                    } catch {
                        print("invalid hotkey encode: \(error)")
                    }
                } else {
                    UserDefaults.standard.set(nil, forKey: "hotkey")
                }
            })
            .store(in: &watchers)
        
        $startAtLogin
            .dropFirst()
            .sink(receiveValue: { enabled in
                let currentValue = Settings.getStartAtLoginEnabled()
                if enabled != currentValue {
                    let success = Settings.setStartAtLoginEnabled(enabled: enabled)
                    if !success {
                        print("failed to set startAtLoginEnabled \(enabled)")
                        
                        DispatchQueue.main.async {
                            self.objectWillChange.send()
                            self.startAtLogin = currentValue
                        }
                    }
                }
            })
            .store(in: &watchers)
        
        $hotkeysEnabled
            .dropFirst()
            .sink(receiveValue: { UserDefaults.standard.set($0, forKey: "hotkeysEnabled") })
            .store(in: &watchers)
        
        $showTouchBarButton
            .dropFirst()
            .sink(receiveValue: { UserDefaults.standard.set($0, forKey: "showTouchBarButton") })
            .store(in: &watchers)
    }
    
    static private func getStartAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    static private func setStartAtLoginEnabled(enabled: Bool) -> Bool {
        do {
            if (enabled) {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            
            return true
        } catch {
            print("setStartAtLoginEnabled(\(enabled)) failed: \(error)")
            return false
        }
    }
}
