//
//  AudioBarGraphWaveView.h
//  audioBarGraphWave
//
//  Created by lieyunye on 10/15/15.
//  Copyright © 2015 lieyunye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioBarGraphWaveView : UIView
@property (nonatomic, strong) NSURL* soundURL;
@property (nonatomic, strong) UIColor* waveColor;
@property (nonatomic, assign) NSInteger drawSpace;
@property (nonatomic, assign) NSInteger upperAndlowerSpace;
@end
