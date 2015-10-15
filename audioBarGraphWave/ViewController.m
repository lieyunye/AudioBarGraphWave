//
//  ViewController.m
//  audioBarGraphWave
//
//  Created by lieyunye on 10/15/15.
//  Copyright © 2015 lieyunye. All rights reserved.
//

#import "ViewController.h"
#import "AudioBarGraphWaveView.h"

@interface ViewController ()
{
    AudioBarGraphWaveView* _soundWaveView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _soundWaveView = [[AudioBarGraphWaveView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 55)];
    _soundWaveView.backgroundColor = [UIColor redColor];
    [self.view addSubview:_soundWaveView];
    NSString* filename = [NSString stringWithFormat:@"1.mp4"];
    
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:filename ofType:nil]];
    
    _soundWaveView.soundURL = url;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
