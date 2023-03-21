//
//  HotkeyManager.swift
//  MicMuter
//
//  Created by Markus Kraus on 07.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Foundation
import Combine

protocol HotkeyManagerDelegate : AnyObject {
    func hotkeyPressed()
}

struct KeyInfo {
    var key: Int64
    var flags: KeyFlags
    
    public var description: String {
        var desc = [String]()
        if flags.contains(.Function) {
            desc.append("fn")
        }
        
        if flags.contains(.Control) {
            desc.append("⌃")
        }
        
        if flags.contains(.Alternate) {
            desc.append("⌥")
        }
        
        if flags.contains(.Command) {
            desc.append("⌘")
        }
        
        if flags.contains(.Shift) {
            desc.append("⇧")
        }
        
        desc.append(KeyHook.keyToStr(key))
        return desc.joined(separator: " ")
    }
    
    static func == (lhs: KeyInfo, rhs: KeyInfo) -> Bool {
        return lhs.key == rhs.key && lhs.flags == rhs.flags
    }
}

class HotkeyManager: KeyHookDelegate {
    weak var delegate: HotkeyManagerDelegate?
    
    //var recordingCallBack: ((Set<UInt32>) -> Void)?
    var recordingCallBack: ((KeyInfo) -> Void)?
    
    private let keyHook: KeyHook
//    let hidKeyHook: HIDKeyHook
    var hotkey: KeyInfo?
    
    init(runLoop: CFRunLoop) {
        keyHook = KeyHook(runLoop: runLoop)
//        hidKeyHook = HIDKeyHook(runLoop: runLoop)
        keyHook.delegate = self
        //hidKeyHook.delegate = self
    }
    
    deinit {
        keyHook.delegate = nil
        keyHook.stop()
    }
    
    func start() {
        if !self.keyHook.started {
            self.keyHook.start()
        }
        
//        if !self.hidKeyHook.started {
//            self.hidKeyHook.start()
//        }
    }
    
    func stop() {
        keyHook.stop()
    }
    
    func started() -> Bool {
        return keyHook.started// && self.hidKeyHook.started
    }
    
    func stopHotkeyRecording() {
        //pressedKeys.removeAll()
        recordingCallBack = nil
    }
    
    func recordHotkey(callback: @escaping ((KeyInfo) -> Void)) {
        recordingCallBack = callback
    }
    
    func onKeyPress(key: Int64, flags: KeyFlags, state: KeyState) {
        let pressedKey = KeyInfo(key: key, flags: flags)
        
        if state == .down {
            if recordingCallBack != nil {
                let old = recordingCallBack
                recordingCallBack = nil
                old!(pressedKey)
            } else if self.hotkey != nil && pressedKey == self.hotkey! {
                self.delegate?.hotkeyPressed()
            }
        }
    }
}
