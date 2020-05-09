//
//  UIManager.swift
//  MicMuter
//
//  Created by Markus Kraus on 08.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Foundation

protocol UIManagerDelegate : AnyObject {
    func quitWasRequested()
    func muteWasRequested()
}

class UIManager {
    weak var delegate: UIManagerDelegate?
    
    var statusBarItem: NSStatusItem! // system tray icon + menu
    var muteMenuItem: NSMenuItem!    // mute button in system tray menu
    var touchBarButton: NSButton!
    
    let micOnImage = NSImage(named: "MicrophoneFilled_Normal")
    let micOffImage = NSImage(named: "MicrophoneStroke_Normal")
    let micOnImageTouchbar = NSImage(named: NSImage.touchBarAudioInputTemplateName)
    let micOffImageTouchbar = NSImage(named: NSImage.touchBarAudioInputMuteTemplateName)
    
    func start() {
        configureStatusBar()
        configureTouchbar()
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
    
    func configureTouchbar() {
        touchBarButton = NSButton(title: "", target: self, action: #selector(UIManager.requestMute))
        
        let touchBarItem = NSCustomTouchBarItem(identifier: NSTouchBarItem.Identifier("MicMuter"))
        touchBarItem.view = touchBarButton
        NSTouchBarItem.addSystemTrayItem(touchBarItem)
        DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItem.Identifier("MicMuter"), true)
    }
    
    func configureStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
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
