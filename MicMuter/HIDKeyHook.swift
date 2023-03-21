//
//  HotkeySolution.swift
//  MicMuter
//
//  Created by Markus Kraus on 02.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

import IOKit
import IOKit.usb
import IOKit.hid
import Foundation
import ApplicationServices
import Cocoa
import Carbon

protocol HIDKeyHookDelegate : AnyObject {
    func onKeyPress(keycode: UInt32, state: KeyState)
}

let device: [String: Int] = [
    kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard,
    kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop
]

let filter: [String: Int] = [
    kIOHIDElementUsageMinKey: 3,
    kIOHIDElementUsageMaxKey: 231
]

class HIDKeyHook {
    weak var delegate: HIDKeyHookDelegate?
    
    let runLoop: CFRunLoop
    var started = false
    var lastError = ""
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    var context: UnsafeMutableRawPointer!
    
    init(runLoop: CFRunLoop) {
        self.runLoop = runLoop
        self.context = Unmanaged.passUnretained(self).toOpaque()
    }
    
    deinit {
        stop()
    }
    
    static func hasPermission() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, device as CFDictionary)
        
        let status = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        return status == kIOReturnSuccess
    }
    
    func start() {
        if started {
            return
        }
        
        func hidKeyboardCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) {
//            let _self = Unmanaged<HIDKeyHook>.fromOpaque(context!).takeUnretainedValue()
//            let elem = IOHIDValueGetElement(value)
//            let usage = Int(IOHIDElementGetUsagePage(elem))
//            
//            let scancode = IOHIDElementGetUsage(elem)
//            let pressed = IOHIDValueGetIntegerValue(value)
//            if scancode == UInt32.max || scancode == kHIDUsage_KeyboardErrorRollOver {
//                return
//            }
//            
//            if usage == 0xFF && scancode == 3 {
//                // fn key
//            }
//            
//            if usage != kHIDPage_GenericDesktop && usage != kHIDPage_KeyboardOrKeypad && usage != kHIDPage_Consumer {
//                print("!= \(scancode) -> \(pressed) \(usage)")
//                return
//            }
//
//            if (pressed == 1) {
//                print("HIDKeyHook: \(scancode) -> (\(HIDKeyHook.HIDKeycodeToStr(Int(scancode))))")
//            }
            //_self.delegate?.onKeyPress(keycode: scancode, state: pressed == 0 ? KeyState.up : KeyState.down)
        }
        
        //IOHIDManagerSetInputValueMatching(manager, filter as CFDictionary)
        IOHIDManagerSetDeviceMatching(manager, device as CFDictionary)

        IOHIDManagerRegisterInputValueCallback(manager, hidKeyboardCallback, context)

        IOHIDManagerScheduleWithRunLoop(manager, runLoop, CFRunLoopMode.defaultMode.rawValue)

        let status = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if status == kIOReturnSuccess {
            started = true
            return
        }

        if let cStr = mach_error_string(status) {
            lastError = String (cString: cStr)
        } else {
            lastError = "\(status)"
        }

        print("failed to start HID manager \(lastError)")
        started = false
    }
    
    func stop() {
        if started {
            IOHIDManagerRegisterInputValueCallback(manager, nil, context)
            started = false
        }
    }
    
    static func HIDKeycodeToStr(_ usage: Int) -> String
    {
        let keyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutPointer = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData) else { fatalError("Failed to get layout data.") }
        let layoutData = Unmanaged<CFData>.fromOpaque(layoutPointer).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var stringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 255)
        var status = layoutData.withUnsafeBytes {
            UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, UInt16(usage), UInt16(kUCKeyActionDown), 0, UInt32(LMGetKbdType()), 0, &deadKeyState, 255, &stringLength, &unicodeString)
        }
        
        if status != noErr {
            fatalError("Translation process failed.")
        }

        if (stringLength == 0 && deadKeyState != 0) {
           status = layoutData.withUnsafeBytes {
                UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, UInt16(kVK_Space), UInt16(kUCKeyActionDown), 0, UInt32(LMGetKbdType()), 0, &deadKeyState, 255, &stringLength, &unicodeString);
            }
        }
        
        return NSString(characters: unicodeString, length: stringLength) as String
        
        
        switch (usage) {
        case kHIDUsage_KeyboardErrorRollOver:       return "err_roll_over"
        case kHIDUsage_KeyboardPOSTFail:            return "post_fail";
        case kHIDUsage_KeyboardErrorUndefined:      return "undefined";

        case kHIDUsage_KeyboardA:                   return "A";
        case kHIDUsage_KeyboardB:                   return "B";
        case kHIDUsage_KeyboardC:                   return "C";
        case kHIDUsage_KeyboardD:                   return "D";
        case kHIDUsage_KeyboardE:                   return "E";
        case kHIDUsage_KeyboardF:                   return "F";
        case kHIDUsage_KeyboardG:                   return "G";
        case kHIDUsage_KeyboardH:                   return "H";
        case kHIDUsage_KeyboardI:                   return "I";
        case kHIDUsage_KeyboardJ:                   return "J";
        case kHIDUsage_KeyboardK:                   return "K";
        case kHIDUsage_KeyboardL:                   return "L";
        case kHIDUsage_KeyboardM:                   return "M";
        case kHIDUsage_KeyboardN:                   return "N";
        case kHIDUsage_KeyboardO:                   return "O";
        case kHIDUsage_KeyboardP:                   return "P";
        case kHIDUsage_KeyboardQ:                   return "Q";
        case kHIDUsage_KeyboardR:                   return "R";
        case kHIDUsage_KeyboardS:                   return "S";
        case kHIDUsage_KeyboardT:                   return "T";
        case kHIDUsage_KeyboardU:                   return "U";
        case kHIDUsage_KeyboardV:                   return "V";
        case kHIDUsage_KeyboardW:                   return "W";
        case kHIDUsage_KeyboardX:                   return "X";
        case kHIDUsage_KeyboardY:                   return "Y";
        case kHIDUsage_KeyboardZ:                   return "Z";

        case kHIDUsage_Keyboard1:                   return "1";
        case kHIDUsage_Keyboard2:                   return "2";
        case kHIDUsage_Keyboard3:                   return "3";
        case kHIDUsage_Keyboard4:                   return "4";
        case kHIDUsage_Keyboard5:                   return "5";
        case kHIDUsage_Keyboard6:                   return "6";
        case kHIDUsage_Keyboard7:                   return "7";
        case kHIDUsage_Keyboard8:                   return "8";
        case kHIDUsage_Keyboard9:                   return "9";
        case kHIDUsage_Keyboard0:                   return "0";

        case kHIDUsage_KeyboardReturnOrEnter:       return "⏎"
        case kHIDUsage_KeyboardEscape:              return "␛"
        case kHIDUsage_KeyboardDeleteOrBackspace:   return "⌫"
        case kHIDUsage_KeyboardTab:                 return "⇥"
        case kHIDUsage_KeyboardSpacebar:            return "␣"
        case kHIDUsage_KeyboardHyphen:              return "-";
        case kHIDUsage_KeyboardEqualSign:           return "=";
        case kHIDUsage_KeyboardOpenBracket:         return "(";
        case kHIDUsage_KeyboardCloseBracket:        return ")";
        case kHIDUsage_KeyboardBackslash:           return "\\";
        case kHIDUsage_KeyboardNonUSPound:          return "non_us_pound";
        case kHIDUsage_KeyboardSemicolon:           return ";";
        case kHIDUsage_KeyboardQuote:               return "\"";
        case kHIDUsage_KeyboardGraveAccentAndTilde: return "^";
        case kHIDUsage_KeyboardComma:               return ",";
        case kHIDUsage_KeyboardPeriod:              return ".";
        case kHIDUsage_KeyboardSlash:               return "/";
        case kHIDUsage_KeyboardCapsLock:            return "⇪"

        case kHIDUsage_KeyboardF1:                  return "F1";
        case kHIDUsage_KeyboardF2:                  return "F2";
        case kHIDUsage_KeyboardF3:                  return "F3";
        case kHIDUsage_KeyboardF4:                  return "F4";
        case kHIDUsage_KeyboardF5:                  return "F5";
        case kHIDUsage_KeyboardF6:                  return "F6";
        case kHIDUsage_KeyboardF7:                  return "F7";
        case kHIDUsage_KeyboardF8:                  return "F8";
        case kHIDUsage_KeyboardF9:                  return "F9";
        case kHIDUsage_KeyboardF10:                 return "F10";
        case kHIDUsage_KeyboardF11:                 return "F11";
        case kHIDUsage_KeyboardF12:                 return "F12";

        case kHIDUsage_KeyboardPrintScreen:         return "print_screen";
        case kHIDUsage_KeyboardScrollLock:          return "scroll_lock";
        case kHIDUsage_KeyboardPause:               return "pause";
        case kHIDUsage_KeyboardInsert:              return "ins";
        case kHIDUsage_KeyboardHome:                return "home";
        case kHIDUsage_KeyboardPageUp:              return "page_up";
        case kHIDUsage_KeyboardDeleteForward:       return "⌦";
        case kHIDUsage_KeyboardEnd:                 return "end";
        case kHIDUsage_KeyboardPageDown:            return "page_down";

        case kHIDUsage_KeyboardRightArrow:          return "→";
        case kHIDUsage_KeyboardLeftArrow:           return "←";
        case kHIDUsage_KeyboardDownArrow:           return "↓";
        case kHIDUsage_KeyboardUpArrow:             return "↑";

        case kHIDUsage_KeypadNumLock:               return "num_lock";
        case kHIDUsage_KeypadSlash:                 return "/ (keypad)";
        case kHIDUsage_KeypadAsterisk:              return "* (keypad)";
        case kHIDUsage_KeypadHyphen:                return "- (keypad)";
        case kHIDUsage_KeypadPlus:                  return "+ (keypad)";
        case kHIDUsage_KeypadEnter:                 return "⏎ (keypad)";

        case kHIDUsage_Keypad1:                     return "1 (keypad)";
        case kHIDUsage_Keypad2:                     return "2 (keypad)";
        case kHIDUsage_Keypad3:                     return "3 (keypad)";
        case kHIDUsage_Keypad4:                     return "4 (keypad)";
        case kHIDUsage_Keypad5:                     return "5 (keypad)";
        case kHIDUsage_Keypad6:                     return "6 (keypad)";
        case kHIDUsage_Keypad7:                     return "7 (keypad)";
        case kHIDUsage_Keypad8:                     return "8 (keypad)";
        case kHIDUsage_Keypad9:                     return "9 (keypad)";
        case kHIDUsage_Keypad0:                     return "0 (keypad)";

        case kHIDUsage_KeypadPeriod:                return ". (keypad)";
        case kHIDUsage_KeyboardNonUSBackslash:      return "non_us_backslash";
        case kHIDUsage_KeyboardApplication:         return "application";
        case kHIDUsage_KeyboardPower:               return "power";
        case kHIDUsage_KeypadEqualSign:             return "=";

        case kHIDUsage_KeyboardF13:                 return "F13";
        case kHIDUsage_KeyboardF14:                 return "F14";
        case kHIDUsage_KeyboardF15:                 return "F15";
        case kHIDUsage_KeyboardF16:                 return "F16";
        case kHIDUsage_KeyboardF17:                 return "F17";
        case kHIDUsage_KeyboardF18:                 return "F18";
        case kHIDUsage_KeyboardF19:                 return "F19";
        case kHIDUsage_KeyboardF20:                 return "F20";
        case kHIDUsage_KeyboardF21:                 return "F21";
        case kHIDUsage_KeyboardF22:                 return "F22";
        case kHIDUsage_KeyboardF23:                 return "F23";
        case kHIDUsage_KeyboardF24:                 return "F24";

        case kHIDUsage_KeyboardExecute:             return "exec";
        case kHIDUsage_KeyboardHelp:                return "help";
        case kHIDUsage_KeyboardMenu:                return "menu";
        case kHIDUsage_KeyboardSelect:              return "select";
        case kHIDUsage_KeyboardStop:                return "stop";
        case kHIDUsage_KeyboardAgain:               return "again";
        case kHIDUsage_KeyboardUndo:                return "undo";
        case kHIDUsage_KeyboardCut:                 return "cut";
        case kHIDUsage_KeyboardCopy:                return "copy";
        case kHIDUsage_KeyboardPaste:               return "paste";
        case kHIDUsage_KeyboardFind:                return "find";

        case kHIDUsage_KeyboardMute:                return "mute";
        case kHIDUsage_KeyboardVolumeUp:            return "volume up";
        case kHIDUsage_KeyboardVolumeDown:          return "volume down";

        case kHIDUsage_KeyboardLockingCapsLock:     return "locking_caps_lock"
        case kHIDUsage_KeyboardLockingNumLock:      return "locking_num_lock";
        case kHIDUsage_KeyboardLockingScrollLock:   return "locking_scroll_lock";

        case kHIDUsage_KeypadComma:                 return ", (keypad)";
        case kHIDUsage_KeypadEqualSignAS400:        return "AS400 (keypad)";
        case kHIDUsage_KeyboardInternational1:      return "int1";
        case kHIDUsage_KeyboardInternational2:      return "int2";
        case kHIDUsage_KeyboardInternational3:      return "int3";
        case kHIDUsage_KeyboardInternational4:      return "int4";
        case kHIDUsage_KeyboardInternational5:      return "int5";
        case kHIDUsage_KeyboardInternational6:      return "int6";
        case kHIDUsage_KeyboardInternational7:      return "int7";
        case kHIDUsage_KeyboardInternational8:      return "int8";
        case kHIDUsage_KeyboardInternational9:      return "int9";

        case kHIDUsage_KeyboardLANG1:               return "lang1";
        case kHIDUsage_KeyboardLANG2:               return "lang2";
        case kHIDUsage_KeyboardLANG3:               return "lang3";
        case kHIDUsage_KeyboardLANG4:               return "lang4";
        case kHIDUsage_KeyboardLANG5:               return "lang5";
        case kHIDUsage_KeyboardLANG6:               return "lang6";
        case kHIDUsage_KeyboardLANG7:               return "lang7";
        case kHIDUsage_KeyboardLANG8:               return "lang8";
        case kHIDUsage_KeyboardLANG9:               return "lang9";

        case kHIDUsage_KeyboardAlternateErase:      return "alt_erase";
        case kHIDUsage_KeyboardSysReqOrAttention:   return "attention";
        case kHIDUsage_KeyboardCancel:              return "cancel";
        case kHIDUsage_KeyboardClear:               return "clear";
        case kHIDUsage_KeyboardPrior:               return "prior";
        case kHIDUsage_KeyboardReturn:              return "⏎";
        case kHIDUsage_KeyboardSeparator:           return "seperator";
        case kHIDUsage_KeyboardOut:                 return "out";
        case kHIDUsage_KeyboardOper:                return "oper";
        case kHIDUsage_KeyboardClearOrAgain:        return "clear_or_again";
        case kHIDUsage_KeyboardCrSelOrProps:        return "sel_or_props";
        case kHIDUsage_KeyboardExSel:               return "ex_sel";

        case kHIDUsage_KeyboardLeftControl:         return "⌃";
        case kHIDUsage_KeyboardLeftShift:           return "⇧";
        case kHIDUsage_KeyboardLeftAlt:             return "⌥";
        case kHIDUsage_KeyboardLeftGUI:             return "⌘";
        case kHIDUsage_KeyboardRightControl:        return "⌃";
        case kHIDUsage_KeyboardRightShift:          return "⇧";
        case kHIDUsage_KeyboardRightAlt:            return "⌥";
        case kHIDUsage_KeyboardRightGUI:            return "⌘";
        case kHIDUsage_Keyboard_Reserved:           return "reserved";
        default:                                    return "unknown";
        }
    }
}
