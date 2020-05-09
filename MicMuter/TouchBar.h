//
//  TouchBar.h
//  MicMuter
//
//  Created by Markus Kraus on 03.05.20.
//  Copyright © 2020 Markus Kraus. All rights reserved.
//


#import <AppKit/AppKit.h>

extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier, BOOL);

@interface NSTouchBarItem ()

+ (void)addSystemTrayItem:(NSTouchBarItem *)item;

@end
