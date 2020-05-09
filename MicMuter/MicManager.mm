//
//  AudioInputManager.m
//  MicMuter
//
//  Created by Markus Kraus on 03.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

#import "MicManager.h"
#include <functional>
#include <memory>
#include <limits>

NSString *NSStringFromOSStatus(OSStatus errCode)
{
    if (errCode == noErr)
        return @"noErr";
    char message[5] = {0};
    *(UInt32*) message = CFSwapInt32HostToBig(errCode);
    return [NSString stringWithCString:message encoding:NSASCIIStringEncoding];
}

namespace micMuter {
    class AudioObjectPropertyListener {
        const AudioObjectPropertyAddress *addr;
        std::function<void()> handler;
        AudioObjectID object;
        
    public:
        AudioObjectPropertyListener(AudioObjectID object, const AudioObjectPropertyAddress *addr, std::function<void()> handler)
        : object(object), addr(addr), handler(handler) {
            auto status = ::AudioObjectAddPropertyListener(object, addr, listenerProc, this);
            
            if (status != noErr) {
                NSLog(@"AudioObjectAddPropertyListener returned %@\n", NSStringFromOSStatus(status));
            }
        }
        
        ~AudioObjectPropertyListener() {
            auto status = ::AudioObjectRemovePropertyListener(object, addr, listenerProc, this);
            
            if (status != noErr) {
                NSLog(@"AudioObjectRemovePropertyListener returned %@\n", NSStringFromOSStatus(status));
            }
        }
        
    private:
        static OSStatus listenerProc(AudioObjectID object, UInt32 numAddrs, const AudioObjectPropertyAddress addrs[], void *ctx) {
            auto _this = static_cast<AudioObjectPropertyListener *>(ctx);
            if (object != _this->object) {
                return noErr;
            }
            
            for (UInt32 i = 0; i < numAddrs; ++i) {
                auto addr = addrs[i];
                if (addr.mSelector == _this->addr->mSelector && addr.mScope == _this->addr->mScope && addr.mElement == _this->addr->mElement) {
                    _this->handler();
                    break;
                }
            }
            
            return noErr;
        }
    };

    class AudioObjectDevice {
        static constexpr AudioObjectPropertyAddress volumeAddr = {
            .mSelector = kAudioDevicePropertyVolumeScalar,
            .mScope = kAudioDevicePropertyScopeInput
        };
        
        static constexpr AudioObjectPropertyAddress mutedAddr = {
            .mSelector = kAudioDevicePropertyMute,
            .mScope = kAudioDevicePropertyScopeInput
        };
        
        AudioObjectID deviceId;
        
    public:
        AudioObjectDevice(AudioObjectID deviceId)
        : deviceId(deviceId) {
        }
        
        ~AudioObjectDevice() {
        }
        
        Float32 getVolume() const {
            Float32 volume = 0.0;
            UInt32 volumeSize = sizeof(volume);

            auto error = AudioObjectGetPropertyData(deviceId, &volumeAddr, 0, nullptr, &volumeSize, &volume);
            if (error != noErr) {
                NSLog(@"getVolume returned %@\n", NSStringFromOSStatus(error));
            }

            return volume;
        }
        
        void setVolume(Float32 volume) {
            auto error = AudioObjectSetPropertyData(deviceId, &volumeAddr, 0, nullptr, sizeof(volume), &volume);
            if (error != noErr) {
                NSLog(@"setVolume returned %@\n", NSStringFromOSStatus(error));
            }
        }
        
        bool isMuted() const {
            UInt32 muted = 0;
            UInt32 mutedSize = sizeof(muted);
            
            auto error = AudioObjectGetPropertyData(deviceId, &mutedAddr, 0, nullptr, &mutedSize, &muted);
            if (error != noErr) {
                NSLog(@"isMuted returned %@\n", NSStringFromOSStatus(error));
            }
            
            return muted;
        }
        
        void setMuted(bool muted) {
            UInt32 _muted = muted;
            auto error = AudioObjectSetPropertyData(deviceId, &mutedAddr, 0, nullptr, sizeof(_muted), &_muted);
            if (error != noErr) {
                NSLog(@"setMuted returned %@\n", NSStringFromOSStatus(error));
            }
        }
    };
}

class DefaultInputDeviceListener : micMuter::AudioObjectPropertyListener {
    static constexpr AudioObjectPropertyAddress addr = {
        .mSelector = kAudioHardwarePropertyDefaultInputDevice,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement = kAudioObjectPropertyElementMaster
    };
    
public:
    DefaultInputDeviceListener(std::function<void()> defaultDeviceChangedHandler)
    : micMuter::AudioObjectPropertyListener(kAudioObjectSystemObject, &addr, defaultDeviceChangedHandler) {
    }
    
    ~DefaultInputDeviceListener() {
    }
    
    AudioObjectID getDefaultInputDevice() const {
        auto deviceId = std::numeric_limits<AudioObjectID>::max();
        UInt32 deviceIdSize = sizeof(deviceId);
        
        auto error = ::AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, nullptr, &deviceIdSize, &deviceId);
        if (error != noErr) {
            NSLog(@"getDefaultInput returned %@\n", NSStringFromOSStatus(error));
        }
        
        return deviceId;
    }
};

class VolumeChangedListener : micMuter::AudioObjectPropertyListener {
    static constexpr AudioObjectPropertyAddress addr = {
        .mSelector = kAudioDevicePropertyVolumeScalar,
        .mScope = kAudioDevicePropertyScopeInput
    };
    
public:
    VolumeChangedListener(AudioDeviceID deviceId, std::function<void()> volumeChangedHandler)
    : micMuter::AudioObjectPropertyListener(deviceId, &addr, volumeChangedHandler) {
    }
    
    ~VolumeChangedListener() {
    }
};

class MutedListener : micMuter::AudioObjectPropertyListener {
    static constexpr AudioObjectPropertyAddress addr = {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = kAudioDevicePropertyScopeInput
    };
    
public:
    MutedListener(AudioDeviceID deviceId, std::function<void()> volumeChangedHandler)
    : micMuter::AudioObjectPropertyListener(deviceId, &addr, volumeChangedHandler) {
    }
    
    ~MutedListener() {
    }
};

@implementation MicManager {
    std::unique_ptr<DefaultInputDeviceListener> defaultInputDeviceListener;
    std::unique_ptr<micMuter::AudioObjectDevice> defaultAudioDevice;
    std::unique_ptr<VolumeChangedListener> volumeChangedListener;
    std::unique_ptr<MutedListener> mutedListener;
}

@synthesize delegate;

- (instancetype)init {
    if (self = [super init]) {
        defaultInputDeviceListener = std::make_unique<DefaultInputDeviceListener>([self]() {
            auto deviceId = self->defaultInputDeviceListener->getDefaultInputDevice();
            [self updateDefaultDevice:deviceId];
            [self.delegate onDefaultInputDeviceChanged:deviceId];
        });
        
        auto deviceId = self->defaultInputDeviceListener->getDefaultInputDevice();
        [self updateDefaultDevice:deviceId];
    }
    
    return self;
}

- (BOOL)getDefaultInputDeviceMuted {
    if (self->defaultAudioDevice) {
        return self->defaultAudioDevice->isMuted();
    }
    
    return YES;
}

- (void)setDefaultInputDeviceMuted:(BOOL)muted {
    if (self->defaultAudioDevice) {
        self->defaultAudioDevice->setMuted(muted);
    }
}

- (BOOL)defaultInputDeviceIsValid {
    return !!self->defaultAudioDevice;
}

- (AudioDeviceID)getDefaultInputDeviceId {
    return self->defaultInputDeviceListener->getDefaultInputDevice();
}

- (void)setDefaultInputDeviceVolume:(Float32)volume {
    if (self->defaultAudioDevice) {
        self->defaultAudioDevice->setVolume(volume);
    }
}

- (Float32)getDefaultInputDeviceVolume {
    if (self->defaultAudioDevice) {
        return self->defaultAudioDevice->getVolume();
    }
    
    return 0;
}

- (void)updateDefaultDevice:(AudioDeviceID)deviceId {
    if (deviceId == std::numeric_limits<AudioDeviceID>::max()) {
        defaultAudioDevice.reset();
        volumeChangedListener.reset();
        mutedListener.reset();
    }
    else {
        defaultAudioDevice = std::make_unique<micMuter::AudioObjectDevice>(deviceId);
        
        volumeChangedListener = std::make_unique<VolumeChangedListener>(deviceId, [self]() {
            auto volume = self->defaultAudioDevice->getVolume();
            [self.delegate onDefaultInputDeviceVolumeChanged:volume];
        });
        
        mutedListener = std::make_unique<MutedListener>(deviceId, [self]() {
            if (self.delegate) {
                auto muted = self->defaultAudioDevice->isMuted();
                [self.delegate onDefaultInputDeviceMuted:muted];
            }
        });
    }
}

@end
