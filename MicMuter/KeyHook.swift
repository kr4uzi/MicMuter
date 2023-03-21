//
//  HotkeySolution.swift
//  MicMuter
//
//  Created by Markus Kraus on 02.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import Foundation
import ApplicationServices
import Cocoa
import Carbon

protocol KeyHookDelegate : AnyObject {
    func onKeyPress(key: Int64, flags: KeyFlags, state: KeyState)
}

struct KeyFlags: OptionSet {
    let rawValue: Int
    
    static let Shift = KeyFlags(rawValue: 1 << 0)
    static let Control = KeyFlags(rawValue: 1 << 1)
    static let Alternate = KeyFlags(rawValue: 1 << 2)
    static let Command = KeyFlags(rawValue: 1 << 3)
    static let Function = KeyFlags(rawValue: 1 << 4)
}

enum KeyState {
    case up
    case down
}

class KeyHook {
    weak var delegate: KeyHookDelegate?
    
    private let runLoop: CFRunLoop
    private var runLoopSource: CFRunLoopSource?
    private(set) var started = false
    private(set) var lastError = ""
    
    init(runLoop: CFRunLoop) {
        self.runLoop = runLoop
    }
    
    deinit {
        stop()
    }
    
    func start() {
        if started {
            return
        }
        
        func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, context: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
            if [.keyDown, .keyUp].contains(type) {
                let repeated = event.getIntegerValueField(.keyboardEventAutorepeat)
                if repeated == 0 {
                    let _self = Unmanaged<KeyHook>.fromOpaque(context!).takeUnretainedValue()
                    let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                    
                    let eventFlags = event.flags
                    
                    let fromFlags: [CGEventFlags] = [.maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn]
                    let toFlags: [KeyFlags] = [.Shift, .Control, .Alternate, .Command, .Function]
                    var mappedFlags: KeyFlags = []
                    
                    for (index, flag) in fromFlags.enumerated() {
                        if (eventFlags.rawValue & flag.rawValue) != 0 {
                            mappedFlags.insert(toFlags[index])
                        }
                    }
                    
                    _self.delegate?.onKeyPress(key: keycode, flags: mappedFlags, state: type == .keyUp ? .up : .down)
                }
            }
            
            return Unmanaged.passRetained(event)
        }
        
        let context = Unmanaged.passRetained(self).toOpaque()
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: eventMask, callback: eventCallback, userInfo: context) else {
            Unmanaged.passUnretained(self).release()
            
            print("failed to create event tap")
            started = false
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(runLoop, runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        started = true
    }
    
    func stop() {
        if started {
            CFRunLoopRemoveSource(runLoop, runLoopSource, .commonModes)
            Unmanaged.passUnretained(self).release()
            started = false
        }
    }
    
    static func keyToStr(_ keycode: Int64) -> String {
        let _keycode = CGKeyCode(keycode)
        let key = keyCodeDictionary[_keycode]
                
        if key != nil {
            return key!
        }
        
        let event = CGEvent(keyboardEventSource: .init(stateID: .privateState), virtualKey: _keycode, keyDown: true)
        var length = 0
        event!.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        var chars = [UniChar](repeating: 0, count: length)
        
        event!.keyboardGetUnicodeString(maxStringLength: chars.count, actualStringLength: &length, unicodeString: &chars)
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }
}

// Is this from karabiner elements? I dont remember anymore
// -> Source unknown...
let keyCodeDictionary: Dictionary<CGKeyCode, String> = [
    0: "A",
    1: "S",
    2: "D",
    3: "F",
    4: "H",
    5: "G",
    6: "Z",
    7: "X",
    8: "C",
    9: "V",
    10: "DANISH_DOLLAR",
    11: "B",
    12: "Q",
    13: "W",
    14: "E",
    15: "R",
    16: "Y",
    17: "T",
    18: "1",
    19: "2",
    20: "3",
    21: "4",
    22: "6",
    23: "5",
    24: "=",
    25: "9",
    26: "7",
    27: "-",
    28: "8",
    29: "0",
    30: "]",
    31: "O",
    32: "U",
    33: "[",
    34: "I",
    35: "P",
    36: "⏎",
    37: "L",
    38: "J",
    39: "'",
    40: "K",
    41: ";",
    42: "\\",
    43: ",",
    44: "/",
    45: "N",
    46: "M",
    47: ".",
    48: "⇥",
    49: "Space",
    50: "`",
    51: "⌫",
    52: "Enter_POWERBOOK",
    53: "⎋",
    54: "Command_R",
    55: "Command_L",
    56: "Shift_L",
    57: "CapsLock",
    58: "Option_L",
    59: "Control_L",
    60: "Shift_R",
    61: "Option_R",
    62: "Control_R",
    63: "Fn",
    64: "F17",
    65: "Keypad_Dot",
    67: "Keypad_Multiply",
    69: "Keypad_Plus",
    71: "Keypad_Clear",
    75: "Keypad_Slash",
    76: "⌤",
    78: "Keypad_Minus",
    79: "F18",
    80: "F19",
    81: "Keypad_Equal",
    82: "Keypad_0",
    83: "Keypad_1",
    84: "Keypad_2",
    85: "Keypad_3",
    86: "Keypad_4",
    87: "Keypad_5",
    88: "Keypad_6",
    89: "Keypad_7",
    90: "F20",
    91: "Keypad_8",
    92: "Keypad_9",
    93: "¥",
    94: "_",
    95: "Keypad_Comma",
    96: "F5",
    97: "F6",
    98: "F7",
    99: "F3",
    100: "F8",
    101: "F9",
    102: "英数",
    103: "F11",
    104: "かな",
    105: "F13",
    106: "F16",
    107: "F14",
    109: "F10",
    110: "App",
    111: "F12",
    113: "F15",
    114: "Help",
    115: "Home", // "↖",
    116: "PgUp",
    117: "⌦",
    118: "F4",
    119: "End", // "↘",
    120: "F2",
    121: "PgDn",
    122: "F1",
    123: "←",
    124: "→",
    125: "↓",
    126: "↑",
    127: "PC_POWER",
    128: "GERMAN_PC_LESS_THAN",
    130: "DASHBOARD",
    131: "Launchpad",
    144: "BRIGHTNESS_UP",
    145: "BRIGHTNESS_DOWN",
    160: "Expose_All",
    
    // media key (bata)
    999: "Disable",
    1000 + UInt16(NX_KEYTYPE_SOUND_UP): "Sound_up",
    1000 + UInt16(NX_KEYTYPE_SOUND_DOWN): "Sound_down",
    1000 + UInt16(NX_KEYTYPE_BRIGHTNESS_UP): "Brightness_up",
    1000 + UInt16(NX_KEYTYPE_BRIGHTNESS_DOWN): "Brightness_down",
    1000 + UInt16(NX_KEYTYPE_CAPS_LOCK): "CapsLock",
    1000 + UInt16(NX_KEYTYPE_HELP): "HELP",
    1000 + UInt16(NX_POWER_KEY): "PowerKey",
    1000 + UInt16(NX_KEYTYPE_MUTE): "mute",
    1000 + UInt16(NX_KEYTYPE_NUM_LOCK): "NUM_LOCK",
    1000 + UInt16(NX_KEYTYPE_CONTRAST_UP): "CONTRAST_UP",
    1000 + UInt16(NX_KEYTYPE_CONTRAST_DOWN): "CONTRAST_DOWN",
    1000 + UInt16(NX_KEYTYPE_LAUNCH_PANEL): "LAUNCH_PANEL",
    1000 + UInt16(NX_KEYTYPE_EJECT): "EJECT",
    1000 + UInt16(NX_KEYTYPE_VIDMIRROR): "VIDMIRROR",
    1000 + UInt16(NX_KEYTYPE_PLAY): "Play",
    1000 + UInt16(NX_KEYTYPE_NEXT): "NEXT",
    1000 + UInt16(NX_KEYTYPE_PREVIOUS): "PREVIOUS",
    1000 + UInt16(NX_KEYTYPE_FAST): "Fast",
    1000 + UInt16(NX_KEYTYPE_REWIND): "Rewind",
    1000 + UInt16(NX_KEYTYPE_ILLUMINATION_UP): "Illumination_up",
    1000 + UInt16(NX_KEYTYPE_ILLUMINATION_DOWN): "Illumination_down",
    1000 + UInt16(NX_KEYTYPE_ILLUMINATION_TOGGLE): "ILLUMINATION_TOGGLE"
]
