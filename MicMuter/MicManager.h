//
//  NSObject+MicManager.h
//  MicMuter
//
//  Created by Markus Kraus on 03.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

NS_ASSUME_NONNULL_BEGIN

@class MicManager;
@protocol MicManagerDelegate <NSObject>
- (void)onDefaultInputDeviceChanged:(AudioDeviceID)deviceId;
- (void)onDefaultInputDeviceMuted:(BOOL)muted;
- (void)onDefaultInputDeviceVolumeChanged:(Float32)volume;
@end

@interface MicManager : NSObject {
}
@property (nonatomic, weak) id <MicManagerDelegate> delegate;
- (BOOL)getDefaultInputDeviceMuted;
- (void)setDefaultInputDeviceMuted:(BOOL)muted;

- (BOOL)defaultInputDeviceIsValid;
- (AudioDeviceID)getDefaultInputDeviceId;

- (void)setDefaultInputDeviceVolume:(Float32)volume;
- (Float32)getDefaultInputDeviceVolume;
@end

NS_ASSUME_NONNULL_END
