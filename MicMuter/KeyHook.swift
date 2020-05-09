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

protocol KeyHookDelegate : AnyObject {
    func onKeyPress(keycode: UInt32, state: KeyState)
}

enum KeyState {
    case up
    case down
}

class KeyHook {
    weak var delegate: KeyHookDelegate?
    
    let device: [String: Int] = [
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard,
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop
    ]
    
    let filter: [String: Int] = [
        kIOHIDElementUsageMinKey: 3,
        kIOHIDElementUsageMaxKey: 231
    ]
    
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    var context: UnsafeMutableRawPointer?
    
    init(runLoop: CFRunLoop) {
        func hidKeyboardCallback(context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) {
            let _self = Unmanaged<KeyHook>.fromOpaque(context!).takeUnretainedValue()
            let elem = IOHIDValueGetElement(value)
            let scancode = IOHIDElementGetUsage(elem)
            let pressed = IOHIDValueGetIntegerValue(value)
            
            _self.delegate?.onKeyPress(keycode: scancode, state: pressed == 0 ? KeyState.up : KeyState.down)
        }
        
        context = Unmanaged.passUnretained(self).toOpaque()
        
        IOHIDManagerSetInputValueMatching(manager, filter as CFDictionary)
        IOHIDManagerSetDeviceMatching(manager, device as CFDictionary)
        
        IOHIDManagerRegisterInputValueCallback(manager, hidKeyboardCallback, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, runLoop, CFRunLoopMode.defaultMode.rawValue)
        
        let status = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        assert(status == kIOReturnSuccess)
    }
    
    deinit {
        IOHIDManagerRegisterInputValueCallback(manager, nil, context)
    }
    
    static private func usageToVirtualCode(_ usage: Int) -> UInt32
    {
        switch (usage) {
        case kHIDUsage_KeyboardErrorRollOver:       return 0xff;
        case kHIDUsage_KeyboardPOSTFail:            return 0xff;
        case kHIDUsage_KeyboardErrorUndefined:      return 0xff;

        case kHIDUsage_KeyboardA:                   return 0x00;
        case kHIDUsage_KeyboardB:                   return 0x0b;
        case kHIDUsage_KeyboardC:                   return 0x08;
        case kHIDUsage_KeyboardD:                   return 0x02;
        case kHIDUsage_KeyboardE:                   return 0x0e;
        case kHIDUsage_KeyboardF:                   return 0x03;
        case kHIDUsage_KeyboardG:                   return 0x05;
        case kHIDUsage_KeyboardH:                   return 0x04;
        case kHIDUsage_KeyboardI:                   return 0x22;
        case kHIDUsage_KeyboardJ:                   return 0x26;
        case kHIDUsage_KeyboardK:                   return 0x28;
        case kHIDUsage_KeyboardL:                   return 0x25;
        case kHIDUsage_KeyboardM:                   return 0x2e;
        case kHIDUsage_KeyboardN:                   return 0x2d;
        case kHIDUsage_KeyboardO:                   return 0x1f;
        case kHIDUsage_KeyboardP:                   return 0x23;
        case kHIDUsage_KeyboardQ:                   return 0x0c;
        case kHIDUsage_KeyboardR:                   return 0x0f;
        case kHIDUsage_KeyboardS:                   return 0x01;
        case kHIDUsage_KeyboardT:                   return 0x11;
        case kHIDUsage_KeyboardU:                   return 0x20;
        case kHIDUsage_KeyboardV:                   return 0x09;
        case kHIDUsage_KeyboardW:                   return 0x0d;
        case kHIDUsage_KeyboardX:                   return 0x07;
        case kHIDUsage_KeyboardY:                   return 0x10;
        case kHIDUsage_KeyboardZ:                   return 0x06;

        case kHIDUsage_Keyboard1:                   return 0x12;
        case kHIDUsage_Keyboard2:                   return 0x13;
        case kHIDUsage_Keyboard3:                   return 0x14;
        case kHIDUsage_Keyboard4:                   return 0x15;
        case kHIDUsage_Keyboard5:                   return 0x17;
        case kHIDUsage_Keyboard6:                   return 0x16;
        case kHIDUsage_Keyboard7:                   return 0x1a;
        case kHIDUsage_Keyboard8:                   return 0x1c;
        case kHIDUsage_Keyboard9:                   return 0x19;
        case kHIDUsage_Keyboard0:                   return 0x1d;

        case kHIDUsage_KeyboardReturnOrEnter:       return 0x24;
        case kHIDUsage_KeyboardEscape:              return 0x35;
        case kHIDUsage_KeyboardDeleteOrBackspace:   return 0x33;
        case kHIDUsage_KeyboardTab:                 return 0x30;
        case kHIDUsage_KeyboardSpacebar:            return 0x31;
        case kHIDUsage_KeyboardHyphen:              return 0x1b;
        case kHIDUsage_KeyboardEqualSign:           return 0x18;
        case kHIDUsage_KeyboardOpenBracket:         return 0x21;
        case kHIDUsage_KeyboardCloseBracket:        return 0x1e;
        case kHIDUsage_KeyboardBackslash:           return 0x2a;
        case kHIDUsage_KeyboardNonUSPound:          return 0xff;
        case kHIDUsage_KeyboardSemicolon:           return 0x29;
        case kHIDUsage_KeyboardQuote:               return 0x27;
        case kHIDUsage_KeyboardGraveAccentAndTilde: return 0x32;
        case kHIDUsage_KeyboardComma:               return 0x2b;
        case kHIDUsage_KeyboardPeriod:              return 0x2F;
        case kHIDUsage_KeyboardSlash:               return 0x2c;
        case kHIDUsage_KeyboardCapsLock:            return 0x39;

        case kHIDUsage_KeyboardF1:                  return 0x7a;
        case kHIDUsage_KeyboardF2:                  return 0x78;
        case kHIDUsage_KeyboardF3:                  return 0x63;
        case kHIDUsage_KeyboardF4:                  return 0x76;
        case kHIDUsage_KeyboardF5:                  return 0x60;
        case kHIDUsage_KeyboardF6:                  return 0x61;
        case kHIDUsage_KeyboardF7:                  return 0x62;
        case kHIDUsage_KeyboardF8:                  return 0x64;
        case kHIDUsage_KeyboardF9:                  return 0x65;
        case kHIDUsage_KeyboardF10:                 return 0x6d;
        case kHIDUsage_KeyboardF11:                 return 0x67;
        case kHIDUsage_KeyboardF12:                 return 0x6f;

        case kHIDUsage_KeyboardPrintScreen:         return 0xff;
        case kHIDUsage_KeyboardScrollLock:          return 0xff;
        case kHIDUsage_KeyboardPause:               return 0xff;
        case kHIDUsage_KeyboardInsert:              return 0x72;
        case kHIDUsage_KeyboardHome:                return 0x73;
        case kHIDUsage_KeyboardPageUp:              return 0x74;
        case kHIDUsage_KeyboardDeleteForward:       return 0x75;
        case kHIDUsage_KeyboardEnd:                 return 0x77;
        case kHIDUsage_KeyboardPageDown:            return 0x79;

        case kHIDUsage_KeyboardRightArrow:          return 0x7c;
        case kHIDUsage_KeyboardLeftArrow:           return 0x7b;
        case kHIDUsage_KeyboardDownArrow:           return 0x7d;
        case kHIDUsage_KeyboardUpArrow:             return 0x7e;

        case kHIDUsage_KeypadNumLock:               return 0x47;
        case kHIDUsage_KeypadSlash:                 return 0x4b;
        case kHIDUsage_KeypadAsterisk:              return 0x43;
        case kHIDUsage_KeypadHyphen:                return 0x4e;
        case kHIDUsage_KeypadPlus:                  return 0x45;
        case kHIDUsage_KeypadEnter:                 return 0x4c;

        case kHIDUsage_Keypad1:                     return 0x53;
        case kHIDUsage_Keypad2:                     return 0x54;
        case kHIDUsage_Keypad3:                     return 0x55;
        case kHIDUsage_Keypad4:                     return 0x56;
        case kHIDUsage_Keypad5:                     return 0x57;
        case kHIDUsage_Keypad6:                     return 0x58;
        case kHIDUsage_Keypad7:                     return 0x59;
        case kHIDUsage_Keypad8:                     return 0x5b;
        case kHIDUsage_Keypad9:                     return 0x5c;
        case kHIDUsage_Keypad0:                     return 0x52;

        case kHIDUsage_KeypadPeriod:                return 0x41;
        case kHIDUsage_KeyboardNonUSBackslash:      return 0xff;
        case kHIDUsage_KeyboardApplication:         return 0x6e;
        case kHIDUsage_KeyboardPower:               return 0xff;
        case kHIDUsage_KeypadEqualSign:             return 0x51;

        case kHIDUsage_KeyboardF13:                 return 0x69;
        case kHIDUsage_KeyboardF14:                 return 0x6b;
        case kHIDUsage_KeyboardF15:                 return 0x71;
        case kHIDUsage_KeyboardF16:                 return 0xff;
        case kHIDUsage_KeyboardF17:                 return 0xff;
        case kHIDUsage_KeyboardF18:                 return 0xff;
        case kHIDUsage_KeyboardF19:                 return 0xff;
        case kHIDUsage_KeyboardF20:                 return 0xff;
        case kHIDUsage_KeyboardF21:                 return 0xff;
        case kHIDUsage_KeyboardF22:                 return 0xff;
        case kHIDUsage_KeyboardF23:                 return 0xff;
        case kHIDUsage_KeyboardF24:                 return 0xff;

        case kHIDUsage_KeyboardExecute:             return 0xff;
        case kHIDUsage_KeyboardHelp:                return 0xff;
        case kHIDUsage_KeyboardMenu:                return 0x7F;
        case kHIDUsage_KeyboardSelect:              return 0x4c;
        case kHIDUsage_KeyboardStop:                return 0xff;
        case kHIDUsage_KeyboardAgain:               return 0xff;
        case kHIDUsage_KeyboardUndo:                return 0xff;
        case kHIDUsage_KeyboardCut:                 return 0xff;
        case kHIDUsage_KeyboardCopy:                return 0xff;
        case kHIDUsage_KeyboardPaste:               return 0xff;
        case kHIDUsage_KeyboardFind:                return 0xff;

        case kHIDUsage_KeyboardMute:                return 0xff;
        case kHIDUsage_KeyboardVolumeUp:            return 0xff;
        case kHIDUsage_KeyboardVolumeDown:          return 0xff;

        case kHIDUsage_KeyboardLockingCapsLock:     return 0xff;
        case kHIDUsage_KeyboardLockingNumLock:      return 0xff;
        case kHIDUsage_KeyboardLockingScrollLock:   return 0xff;

        case kHIDUsage_KeypadComma:                 return 0xff;
        case kHIDUsage_KeypadEqualSignAS400:        return 0xff;
        case kHIDUsage_KeyboardInternational1:      return 0xff;
        case kHIDUsage_KeyboardInternational2:      return 0xff;
        case kHIDUsage_KeyboardInternational3:      return 0xff;
        case kHIDUsage_KeyboardInternational4:      return 0xff;
        case kHIDUsage_KeyboardInternational5:      return 0xff;
        case kHIDUsage_KeyboardInternational6:      return 0xff;
        case kHIDUsage_KeyboardInternational7:      return 0xff;
        case kHIDUsage_KeyboardInternational8:      return 0xff;
        case kHIDUsage_KeyboardInternational9:      return 0xff;

        case kHIDUsage_KeyboardLANG1:               return 0xff;
        case kHIDUsage_KeyboardLANG2:               return 0xff;
        case kHIDUsage_KeyboardLANG3:               return 0xff;
        case kHIDUsage_KeyboardLANG4:               return 0xff;
        case kHIDUsage_KeyboardLANG5:               return 0xff;
        case kHIDUsage_KeyboardLANG6:               return 0xff;
        case kHIDUsage_KeyboardLANG7:               return 0xff;
        case kHIDUsage_KeyboardLANG8:               return 0xff;
        case kHIDUsage_KeyboardLANG9:               return 0xff;

        case kHIDUsage_KeyboardAlternateErase:      return 0xff;
        case kHIDUsage_KeyboardSysReqOrAttention:   return 0xff;
        case kHIDUsage_KeyboardCancel:              return 0xff;
        case kHIDUsage_KeyboardClear:               return 0xff;
        case kHIDUsage_KeyboardPrior:               return 0xff;
        case kHIDUsage_KeyboardReturn:              return 0xff;
        case kHIDUsage_KeyboardSeparator:           return 0xff;
        case kHIDUsage_KeyboardOut:                 return 0xff;
        case kHIDUsage_KeyboardOper:                return 0xff;
        case kHIDUsage_KeyboardClearOrAgain:        return 0xff;
        case kHIDUsage_KeyboardCrSelOrProps:        return 0xff;
        case kHIDUsage_KeyboardExSel:               return 0xff;

        case kHIDUsage_KeyboardLeftControl:         return 0x3b;
        case kHIDUsage_KeyboardLeftShift:           return 0x38;
        case kHIDUsage_KeyboardLeftAlt:             return 0x3a;
        case kHIDUsage_KeyboardLeftGUI:             return 0x37;
        case kHIDUsage_KeyboardRightControl:        return 0x3e;
        case kHIDUsage_KeyboardRightShift:          return 0x3c;
        case kHIDUsage_KeyboardRightAlt:            return 0x3d;
        case kHIDUsage_KeyboardRightGUI:            return 0x36;
        case kHIDUsage_Keyboard_Reserved:           return 0xff;
        default:                                    return 0xff;
        }
    }
}
