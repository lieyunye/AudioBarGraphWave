//
//  AudioBarGraphWaveView.m
//  audioBarGraphWave
//
//  Created by lieyunye on 10/15/15.
//  Copyright © 2015 lieyunye. All rights reserved.
//

#import "AudioBarGraphWaveView.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Geometry.h"

@implementation AudioBarGraphWaveView
{
    UIImageView* _waveImageView;
}

- (id) initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        _drawSpace = 2;
        
        _upperAndlowerSpace = 1;
        
        _waveColor = [[UIColor whiteColor] colorWithAlphaComponent:.8];
        _waveImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        
        _waveImageView.contentMode = UIViewContentModeLeft;
        _waveImageView.clipsToBounds = YES;
        
        [self addSubview:_waveImageView];
    }
    return self;
}

- (void) render {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_soundURL options:nil];
    UIImage *renderedImage = [self renderWaveImageFromAudioAsset:asset];
    
    _waveImageView.image = renderedImage;
    
    _waveImageView.width = renderedImage.size.width;
    _waveImageView.left = (self.width - renderedImage.size.width) / 2;
}

- (UIImage*) renderWaveImageFromAudioAsset:(AVURLAsset *)songAsset {
    
    NSError* error = nil;
    
    AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack* songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                        [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        nil];
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    
    UInt32 sampleRate, channelCount = 0;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    
    for (int i = 0; i < [formatDesc count]; ++i)
    {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if (fmtDesc)
        {
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
        }
    }
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 maxValue = 0;
    
    NSMutableData *fullSongData = [[NSMutableData alloc] init];
    
    [reader startReading];
    
    UInt64 totalBytes = 0;
    SInt64 totalLeft = 0;
    SInt64 totalRight = 0;
    NSInteger sampleTally = 0;
    
    NSInteger samplesPerPixel = 100; // pretty enougth for most of ui and fast
    
    int buffersCount = 0;
    while (reader.status == AVAssetReaderStatusReading)
    {
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef)
        {
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            @autoreleasepool
            {
                NSMutableData *data = [NSMutableData dataWithLength:length];
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
                
                SInt16 * samples = (SInt16*) data.mutableBytes;
                NSUInteger sampleCount = length / bytesPerSample;
                
                for (int i = 0; i < sampleCount; i++)
                {
                    SInt16 left = *samples++;
                    
                    totalLeft += left;
                    
                    SInt16 right = 0;
                    
                    if (channelCount == 2)
                    {
                        right = *samples++;
                        
                        totalRight += right;
                    }
                    
                    sampleTally++;
                    
                    if (sampleTally > samplesPerPixel)
                    {
                        left = (totalLeft / sampleTally);
                        
                        if (channelCount == 2)
                        {
                            right = (totalRight / sampleTally);
                        }
                        
                        SInt16 val = right ? ((right + left) / 2) : left;
                        
                        [fullSongData appendBytes:&val length:sizeof(val)];
                        
                        totalLeft = 0;
                        totalRight = 0;
                        sampleTally = 0;
                    }
                }
                CMSampleBufferInvalidate(sampleBufferRef);
                
                CFRelease(sampleBufferRef);
            }
        }
        
        buffersCount++;
    }
    
    NSMutableData *adjustedSongData = [[NSMutableData alloc] init];
    
    NSUInteger sampleCount = fullSongData.length / 2; // sizeof(SInt16)
    
    int adjustFactor = ceilf((float)sampleCount / (self.width / 1.8));
    
    SInt16* samples = (SInt16*) fullSongData.mutableBytes;
    
    int i = 0;
    
    while (i < sampleCount)
    {
        SInt16 val = 0;
        
        for (int j = 0; j < adjustFactor; j++)
        {
            val += samples[i + j];
        }
        val /= adjustFactor;
        if (ABS(val) > maxValue)
        {
            maxValue = ABS(val);
        }
        [adjustedSongData appendBytes:&val length:sizeof(val)];
        i += adjustFactor;
    }
    
    sampleCount = adjustedSongData.length / 2;
    
    if (reader.status == AVAssetReaderStatusCompleted)
    {
        UIImage *image = [self drawImageFromSamples:(SInt16 *)adjustedSongData.bytes
                                           maxValue:maxValue
                                        sampleCount:sampleCount];
        return image;
    }
    return nil;
}

- (UIImage*) drawImageFromSamples:(SInt16*)samples
                         maxValue:(SInt16)maxValue
                      sampleCount:(NSInteger)sampleCount {
    
    CGSize imageSize = CGSizeMake(sampleCount * _drawSpace, self.height);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextSetAlpha(context, 1.0);
    
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef waveColor = self.waveColor.CGColor;
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float channelCenterY = imageSize.height / 2;
    float sampleAdjustmentFactor = imageSize.height / (float)maxValue;
    
    for (NSInteger i = 0; i < sampleCount; i++)
    {
        float val = *samples++;
        val = val * sampleAdjustmentFactor;
        if ((int)val <= 0)
            val = 2.0; // draw dots instead emptyness
        
        CGFloat startX1 = i * _drawSpace;
        CGFloat startY1 = channelCenterY - val / 2.0;
        
        CGFloat endX1 = i * _drawSpace;
        CGFloat endY1 = channelCenterY;
        
        CGFloat startX2 = i * _drawSpace;
        CGFloat startY2 = channelCenterY + _upperAndlowerSpace;
        
        CGFloat endX2 = i * _drawSpace;
        CGFloat endY2 = startY2 + val / 2.0;
        
        NSLog(@"val = %f startX = %f,startY = %f,endX = %f,endY = %f", val, startX1, startY1, endX1, endY1);
        
        CGContextMoveToPoint(context, startX1, startY1);
        CGContextAddLineToPoint(context, endX1, endY1);
        
        CGContextMoveToPoint(context, startX2, startY2);
        CGContextAddLineToPoint(context, endX2, endY2);
        
        CGContextSetStrokeColorWithColor(context, waveColor);
        CGContextStrokePath(context);
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) setSoundURL:(NSURL*)soundURL {
    
    _soundURL = soundURL;
    
    [self render];
}

@end
