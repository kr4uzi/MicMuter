//
//  UIManager.swift
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

let micOnImage = NSImage(named: "MicrophoneFilled_Normal")
let micOffImage = NSImage(named: "MicrophoneStroke_Normal")
let micOnImageTouchbar = NSImage(named: NSImage.touchBarAudioInputTemplateName)
let micOffImageTouchbar = NSImage(named: NSImage.touchBarAudioInputMuteTemplateName)

class UIManager {
    weak var delegate: UIManagerDelegate?
    
    private static let touchbarId = NSTouchBarItem.Identifier(rawValue: Bundle.main.bundleIdentifier!)
    
    private var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength) // system tray icon + menu
    private var muteMenuItem: NSMenuItem!    // mute button in system tray menu
    
    private var touchBarButton: NSButton!    
    private var watchers = Set<AnyCancellable>()
    
    init(config: MicMuterConfig) {
        configureTouchBar()
        configureStatusBar()
        
        setTouchbarButtonVisible(config.showTouchBarButton)
        config.$showTouchBarButton.dropFirst().sink(receiveValue: { self.setTouchbarButtonVisible($0) }).store(in: &watchers)
    }
    
    func setMutedState(muted: Bool) {
        if muted {
            muteMenuItem.state = .on
            touchBarButton.image = micOffImageTouchbar
            statusBarItem.button!.image = micOffImage
        }
        else {
            muteMenuItem.state = .off
            touchBarButton.image = micOnImageTouchbar
            statusBarItem.button!.image = micOnImage
        }
    }
    
    func setTouchbarButtonVisible(_ visible: Bool) {
        DFRElementSetControlStripPresenceForIdentifier(UIManager.touchbarId, visible)
    }
    
    func configureTouchBar() {
        let touchBarItem = NSCustomTouchBarItem(identifier: UIManager.touchbarId)
        touchBarButton = NSButton(title: "", target: self, action: #selector(UIManager.requestMute))
        touchBarItem.view = touchBarButton
        NSTouchBarItem.addSystemTrayItem(touchBarItem)
    }
    
    func configureStatusBar() {
        statusBarItem.menu = NSMenu()
        
        muteMenuItem = addMenuItem(title: "Mute", translationComment: "Mute menu item title", action: #selector(UIManager.requestMute))
        addMenuItem(title: "Config", translationComment: "Config menu item title", action: #selector(UIManager.openConfigWindow))
        addMenuItem(title: "Quit", translationComment: "Quit menu item title", action: #selector(UIManager.requestQuit))
    }
    
    @discardableResult
    func addMenuItem(title: String, translationComment: String, action selector: Selector) -> NSMenuItem {
        let menuTitle = NSLocalizedString(title, comment: translationComment)
        let item = statusBarItem.menu!.addItem(withTitle: menuTitle, action: selector, keyEquivalent: "")
        item.target = self
        return item
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
