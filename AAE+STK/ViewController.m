//
//  ViewController.m
//  AAE+STK
//
//  Created by Ariel Elkin on 08/05/2013.
//  Copyright (c) 2013 ariel. All rights reserved.
//

#import "ViewController.h"
#import "AEAudioController.h"
#import "AEBlockChannel.h"

@interface ViewController ()

@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEBlockChannel *mySynthChannel;
@property (nonatomic, retain) AEBlockChannel *myNoiseChannel;

@property __block float oscillatorRate;

////Do we need to add an audioDescription whenever we create an AEBlockChannel?
////when should we chose an audio unit file player over a AEAudioFilePlayer?

@end

@implementation ViewController

- (void) setupAudio{
        
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:YES]; // don't forget to autorelease if you don't use ARC!
    
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", error.localizedDescription);
    }

    // Create a block-based channel, with an implementation of an oscillator
    __block float oscillatorPosition = 0;
    self.oscillatorRate = 622.0/44100.0;

    
    self.mySynthChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                         UInt32           frames,
                                                         AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {
            // Quick sin-esque oscillator
            float x = oscillatorPosition;
            x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
            x *= INT16_MAX;
            x -= INT16_MAX / 2;
            oscillatorPosition += self.oscillatorRate;
            if ( oscillatorPosition > 1.0 ) oscillatorPosition -= 2.0;
            
            ((SInt16*)audio->mBuffers[0].mData)[i] = x;
            ((SInt16*)audio->mBuffers[1].mData)[i] = x;

        }
    }];
    
    
    self.myNoiseChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                             UInt32           frames,
                                                             AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {
            // Noise generator
            
            ((SInt16*)audio->mBuffers[0].mData)[i] = (arc4random()%100)/100.0;
            ((SInt16*)audio->mBuffers[1].mData)[i] = (arc4random()%100)/100.0;
        }
    }];
    
    
    self.myNoiseChannel.audioDescription = [AEAudioController nonInterleaved16BitStereoAudioDescription];
    
    [self.audioController addChannels:@[self.mySynthChannel, self.myNoiseChannel]];
    
}

-(IBAction)sliderMoved:(UISlider *)sender{
    self.oscillatorRate = sender.value/44100.0;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:[UIColor redColor]];
    
    [self setupAudio];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
