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

class ConfigManager: NSObject, NSWindowDelegate, ObservableObject {
    private var watchers = Set<AnyCancellable>()
    
    private var configWindow: NSWindow!
    private let hotkeyManager: HotkeyManager
    
    @Published
    var settings: Settings
    
    @Published
    var hotkeyButtonText = ""
    
    @Published
    var showRestartRequiredMessage = false

    func windowWillClose(_ notification: Notification) {
        hotkeyManager.stopHotkeyRecording()
    }
    
    init(settings: Settings, hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
        self.settings = settings
        super.init()

        settings.$hotkey.sink(receiveValue: { hotkey in
            if (settings.hotkey != nil) {
                self.hotkeyButtonText = hotkey!.description
            } else {
                self.hotkeyButtonText = "No hotkey set"
            }
        }).store(in: &watchers)
        
        configWindow = NSWindow(contentViewController: NSHostingController(rootView: ConfigView().environmentObject(self)))
        configWindow.title = NSLocalizedString("Preferences", comment: "Preferences window title")
        configWindow.delegate = self
        configWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        configWindow.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    func openConfigWindow() {
        configWindow.makeKeyAndOrderFront(nil)
    }
    
    func hotkeyButtonPressed() {
        if self.hotkeyManager.started() {
            self.hotkeyButtonText = "       "
            self.hotkeyManager.recordHotkey(callback: { hotkey in
                self.settings.hotkey = hotkey
            })
        }
    }
}

struct ConfigView: View {
    @EnvironmentObject
    var manager: ConfigManager
    
    var body: some View {
        TabView {
            VStack(alignment: .leading) {
                Toggle(isOn: $manager.settings.startAtLogin, label: {
                    Text("Start at login")
                })
                Toggle(isOn: $manager.settings.showTouchBarButton, label: {
                    Text("Show Touchbar Button")
                })
                Toggle(isOn: $manager.settings.hotkeysEnabled, label: { Text("Enable Hotkeys")
                })
                HStack {
                    Button(manager.hotkeyButtonText) {
                        self.manager.hotkeyButtonPressed()
                    }.disabled(!manager.settings.hotkeysEnabled)
                }
            }.tabItem {
                Text("Config")
            }.padding(5)
            
            VStack {
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
                VStack {
                    Text("Copyright © 2021 Markus Kraus.")
                    Text("All rights reserved.")
                }.padding(5)
            }.tabItem {
                Text("About")
            }
        }
        .padding(15)
        .frame(width: 300, height: 200, alignment: .center)
        .alert("Restart required", isPresented: $manager.showRestartRequiredMessage) {
        } message: {
            Text("This change only takes affect after the next launch of this app")
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigView()
//            .environmentObject(
//                ConfigViewProperties(startAtLogin: false, showTouchBarButton: false, hotkeysEnabled: false, hotkeyButtonText: "")
//            )
//    }
//}
