//
//  ContentView.swift
//  MicMuter
//
//  Created by Markus Kraus on 02.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Combine
import SwiftUI
import ServiceManagement

class ConfigWindow: NSObject, NSWindowDelegate, ConfigViewDelegate {
    var configWindow: NSWindow!
    var hotkeyManager: HotkeyManager
    var config: MicMuterConfig
    
    init(config: MicMuterConfig, hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
        self.config = config
        super.init()
        
        let configView = ConfigView(delegate: self).environmentObject(config)
        configWindow = NSWindow(contentViewController: NSHostingController(rootView: configView))
        configWindow.title = NSLocalizedString("Preferences", comment: "Preferences window")
        configWindow.delegate = self
    }
    
    func open() {
        configWindow.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        hotkeyManager.stopHotkeyRecording()
    }
    
    func shortcutButtonPressed() {
        if !KeyHook.hasPermission() {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
            return
        }
        
        let started = hotkeyManager.recordHotkeys(callback: { hotkeys in
            if !hotkeys.isEmpty {
                self.config.shortcutState = .ShortcutSet
                self.hotkeyManager.hotkeySequence = hotkeys
                self.config.shortcut = hotkeys
            } else {
                self.config.shortcutState = .ShortcutNotSet
            }
        })
        
        self.config.shortcutState = started ? .Recording : .Error
    }
}

enum ShortcutState {
    case ShortcutNotSet
    case ShortcutSet
    case Recording
    case PriviledgeRevoked
    case Error
}

final class MicMuterConfig: ObservableObject {
    @Published var startAtLogin: Bool
    @Published var showTouchBarButton: Bool
    @Published var shortcut: Set<UInt32>
    @Published var shortcutState: ShortcutState
    
    init(startAtLogin: Bool, showTouchBarButton: Bool, shortcut: Set<UInt32>, shortcutState: ShortcutState) {
        self.startAtLogin = startAtLogin
        self.showTouchBarButton = showTouchBarButton
        self.shortcut = shortcut
        self.shortcutState = shortcutState
    }
}

class ConfigManager {
    private var hotkeyManager: HotkeyManager
    private var configWindow: ConfigWindow!

    private(set) var config: MicMuterConfig!
    private var watchers = Set<AnyCancellable>()
    
    init(hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
        
        let shortcut = ConfigManager.loadHotkeys()
        config = MicMuterConfig(startAtLogin: ConfigManager.getStartAtLoginEnabled(),
                                     showTouchBarButton: ConfigManager.loadShowTouchBarButton(showButtonDefault: true),
                                     shortcut: shortcut,
                                     shortcutState: ConfigManager.getShortCutState(shortcut: shortcut))
        
        
        configWindow = ConfigWindow(config: config, hotkeyManager: hotkeyManager)
        
        config.$startAtLogin.dropFirst().sink(receiveValue: { enabled in
            let currentValue = ConfigManager.getStartAtLoginEnabled()
            if enabled != currentValue {
                let success = ConfigManager.setStartAtLoginEnabled(enabled: enabled)
                if !success {
                    print("failed to set startAtLoginEnabled \(enabled)")
                    
                    DispatchQueue.main.async {
                        self.config.objectWillChange.send()
                        self.config.startAtLogin = currentValue
                    }
                }
            }
            
            print("start at login: \(self.config.startAtLogin)")
        }).store(in: &watchers)
        
        config.$showTouchBarButton.dropFirst().sink(receiveValue: { enabled in
            UserDefaults.standard.set(enabled, forKey: "showTouchBarButton")
        }).store(in: &watchers)
        
        config.$shortcut.dropFirst().sink(receiveValue: { shortcut in
            UserDefaults.standard.set(shortcut, forKey: "shortcut")
        }).store(in: &watchers)
    }
    
    func openConfigWindow() {
        config.shortcutState = ConfigManager.getShortCutState(shortcut: config.shortcut)
        configWindow.open()
    }
    
    static private func getShortCutState(shortcut: Set<UInt32>) -> ShortcutState {
        if !KeyHook.hasPermission() {
            return .PriviledgeRevoked
        } else if shortcut.isEmpty {
            return .ShortcutNotSet
        }
        
        return .ShortcutSet
    }
    
    static private func getStartAtLoginEnabled() -> Bool {
        guard let jobs = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]) else {
            return false
        }
        
        let job = jobs.first { $0["Label"] as! String == Bundle.main.bundleIdentifier! }
        return job?["OnDemand"] as? Bool ?? false
    }
    
    static private func setStartAtLoginEnabled(enabled: Bool) -> Bool {
        if !SMLoginItemSetEnabled("\(Bundle.main.bundleIdentifier!)" as CFString, enabled) {
            return false
        }
        
        return true
    }
    
    static private func loadHotkeys() -> Set<UInt32> {
        if let storedHotkeys = UserDefaults.standard.array(forKey: "hotkeys") as? Array<UInt32> {
            return Set(storedHotkeys)
        }
        
        return Set<UInt32>()
    }
    
    static private func loadShowTouchBarButton(showButtonDefault: Bool) -> Bool {
        let showButton = UserDefaults.standard.object(forKey: "showTouchBarButton")
        if showButton == nil {
            return showButtonDefault
        }
        
        return showButton as! Bool
    }
}

protocol ConfigViewDelegate {
    func shortcutButtonPressed()
}

struct ConfigView: View {
    var buttonText = ""
    
    @EnvironmentObject
    var config: MicMuterConfig
    
    var delegate: ConfigViewDelegate?
    
    var body: some View {
        TabView {
            VStack(alignment: .leading) {
                Toggle(isOn: $config.startAtLogin, label: {
                    Text("Start at login")
                })
                Toggle(isOn: $config.showTouchBarButton, label: {
                    Text("Show Touchbar Button")
                })
                HStack {
                    Text("Shortcut")
                    Button(action: {
                        self.delegate?.shortcutButtonPressed()
                    }, label: {
                        if config.shortcutState == ShortcutState.ShortcutSet {
                            Text("\(config.shortcut.map({ KeyHook.usageToKey(Int($0)) }).joined(separator: " "))")
                        }
                        else if config.shortcutState == ShortcutState.ShortcutNotSet {
                            Text("Set Shortcut ...")
                        }
                        else if config.shortcutState == ShortcutState.Recording {
                            Text("Recording ...")
                        }
                        else if config.shortcutState == ShortcutState.PriviledgeRevoked {
                            Text("Enable Shortcut")
                        }
                        else if config.shortcutState == ShortcutState.Error {
                            Text("<Error>")
                        }
                        else {
                            Text("<Unknown>")
                        }
                    })
                }
            }.tabItem {
                Text("Config")
            }
            
            VStack {
                Text("Version \(Bundle.version())")
                VStack {
                    Text("Copyright © 2020 Markus Kraus.")
                    Text("All rights reserved.")
                }.padding(5)
            }.tabItem {
                Text("About")
            }
        }
        .padding(15)
        .frame(width: 250, height: 150, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
            .environmentObject(MicMuterConfig(startAtLogin: false, showTouchBarButton: false, shortcut: Set<UInt32>(), shortcutState: .PriviledgeRevoked))
    }
}
