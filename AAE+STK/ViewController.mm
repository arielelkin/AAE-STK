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

#import "Stk.h"
#import "Mandolin.h"

@interface ViewController ()

@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEBlockChannel *myOscillatorChannel;
@property (nonatomic, retain) AEBlockChannel *mySynthChannel;

@property stk::Mandolin *myMandolin;

@property __block float oscillatorRate;

////Do we need to add an audioDescription whenever we create an AEBlockChannel?
////when should we chose an audio unit file player over a AEAudioFilePlayer?

////tried setting the ASBD to interleaved16BitStereoAudioDescription

@end

@implementation ViewController

- (void) setupAudio{
    
    
    //AEAudioController setup:
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:YES]; // don't forget to autorelease if you don't use ARC!
    
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", error.localizedDescription);
    }
    
    
    
    //Simple oscillator works well:

    // Create a block-based channel, with an implementation of an oscillator
    __block float oscillatorPosition = 0;
    self.oscillatorRate = 200/44100.0;
    
    self.myOscillatorChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
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
    [self.myOscillatorChannel setVolume:0.2];
    
    
    
    
    //Now trying to add a synthesiser from the Synthesis Toolkit:
    
    self.myMandolin = new stk::Mandolin(400);
    
    self.mySynthChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                             UInt32           frames,
                                                             AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {

            // STK Mandolin:
            
            ((SInt16*)audio->mBuffers[0].mData)[i] = self.myMandolin->tick();
            ((SInt16*)audio->mBuffers[1].mData)[i] = self.myMandolin->tick();
            
            
        }
    }];
    
    
    //No sound!
    
    //Could it be because of the channel's asbd?
    
//    self.mySynthChannel.audioDescription = [AEAudioController nonInterleaved16BitStereoAudioDescription];
    
    
        
    [self.audioController addChannels:@[self.myOscillatorChannel, self.mySynthChannel]];
    
}

-(IBAction)sliderMoved:(UISlider *)sender{
    self.oscillatorRate = sender.value/44100.0;
}

-(IBAction)buttonPressed{
    self.myMandolin->pluck(1);
    
    NSLog(@"Plucked mandolin! Last sample generated: %f", self.myMandolin->lastOut());
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
