//
//  HotkeyManager.swift
//  MicMuter
//
//  Created by Markus Kraus on 07.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Foundation

protocol HotkeyManagerDelegate : AnyObject {
    func hotkeyPressed()
}

class HotkeyManager: KeyHookDelegate {
    weak var delegate: HotkeyManagerDelegate?
    
    var recordingCallBack: ((Set<UInt32>) -> Void)?
    
    let keyHook: KeyHook!
    var pressedKeys = Set<UInt32>()
    var hotkeySequence: Set<UInt32> = []
    
    init(runLoop: CFRunLoop) {
        keyHook = KeyHook(runLoop: runLoop)
        keyHook.delegate = self
    }
    
    deinit {
        keyHook.delegate = nil
        keyHook.stop()
    }
    
    func start() -> Bool {
        if !started() {
            return keyHook.start()
        }
        
        return true
    }
    
    func stop() {
        keyHook.stop()
    }
    
    func started() -> Bool {
        return keyHook.started
    }
    
    func stopHotkeyRecording() {
        pressedKeys.removeAll()
        recordingCallBack = nil
    }
    
    func recordHotkeys(callback: @escaping (Set<UInt32>) -> Void) -> Bool {
        pressedKeys.removeAll()
        recordingCallBack = callback
        
        if !started() {
            return keyHook.start()
        }
        
        return true
    }
    
    func onKeyPress(keycode: UInt32, state: KeyState) {
        if state == .down {
            pressedKeys.insert(keycode)
        } else {
            pressedKeys.remove(keycode)
        }
        
        if recordingCallBack != nil {
            // pressedKeys.count > 0 because you could start recording hotkeys with one key already down
            // if this key is released the, the recording will end
            if pressedKeys.count > 0 && state == .up {
                // the first keyup marks the end of the hotkey sequence
                // this key is still part of the hotkey sequence and
                // because .up keycodes are removed from pressedKeys (see above),
                // we have to insert the key again
                pressedKeys.insert(keycode)
                recordingCallBack!(pressedKeys)
                recordingCallBack = nil
            }
        } else if hotkeySequence.count > 0 {
            if hotkeySequence.isSubset(of: pressedKeys) {
                self.delegate?.hotkeyPressed()
            }
        }
    }
}
