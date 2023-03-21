//
//  MenuManager.swift
//  MicMuter
//
//  Created by Markus Kraus on 08.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol UIManagerDelegate: AnyObject {
    func quitWasRequested()
    func muteWasRequested()
    func openConfigWasRequested()
}

fileprivate let micOnImageStatusBar = NSImage(named: "MicrophoneFilled_Template")
fileprivate let micOffImageStatusBar = NSImage(named: "MicrophoneStroke_Template")
fileprivate let micOnImageTouchBar = NSImage(named: NSImage.touchBarAudioInputTemplateName)
fileprivate let micOffImageTouchBar = NSImage(named: NSImage.touchBarAudioInputMuteTemplateName)

class MenuManager {
    weak var delegate: UIManagerDelegate?
    
    private static let touchbarId = NSTouchBarItem.Identifier(rawValue: Bundle.main.bundleIdentifier!)
    
    private var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength) // system tray icon + menu
    private var muteMenuItem = NSMenuItem(title: NSLocalizedString("Mute", comment: "System tray menu"), action: #selector(requestMute), keyEquivalent: "")
    
    private var touchBarButton = NSButton(title: "", target: nil, action: nil)
    
    private var watchers = Set<AnyCancellable>()
    
    init(settings: Settings) {
        configureTouchBar()
        configureStatusBar()
        
        settings.$showTouchBarButton.sink(receiveValue: { self.setTouchbarButtonVisible($0) }).store(in: &watchers)
    }
    
    func setMutedState(muted: Bool) {
        if muted {
            muteMenuItem.state = .on
            touchBarButton.image = micOffImageTouchBar
            statusBarItem.button!.image = micOffImageStatusBar
        }
        else {
            muteMenuItem.state = .off
            touchBarButton.image = micOnImageTouchBar
            statusBarItem.button!.image = micOnImageStatusBar
        }
    }
    
    func setTouchbarButtonVisible(_ visible: Bool) {
        DFRElementSetControlStripPresenceForIdentifier(MenuManager.touchbarId, visible)
    }
    
    func configureTouchBar() {
        touchBarButton.target = self
        touchBarButton.action = #selector(requestMute)
        
        let touchBarItem = NSCustomTouchBarItem(identifier: MenuManager.touchbarId)
        touchBarItem.view = touchBarButton
        
        NSTouchBarItem.addSystemTrayItem(touchBarItem)
    }
    
    func configureStatusBar() {
        let menu = NSMenu()
        
        muteMenuItem.action = #selector(requestMute)
        muteMenuItem.target = self
        
        menu.addItem(muteMenuItem)
        menu.addItem(withTitle: NSLocalizedString("Config", comment: "Systray config"), action: #selector(openConfigWindow), keyEquivalent: "").target = self
        menu.addItem(withTitle: NSLocalizedString("Quit", comment: "Systray quit"), action: #selector(requestQuit), keyEquivalent: "").target = self
        
        statusBarItem.menu = menu
    }
    
    @objc
    func openConfigWindow() {
        delegate?.openConfigWasRequested()
    }

    @objc
    func requestQuit() {
        delegate?.quitWasRequested()
    }
    
    @objc
    func requestMute() {
        delegate?.muteWasRequested()
    }
}
