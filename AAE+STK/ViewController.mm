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
#import "AEAudioUnitFilter.h"

#import "Stk.h"
#import "Mandolin.h"


@interface ViewController ()

@property (nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, retain) AEBlockChannel *mySynthChannel;
@property (nonatomic, retain) AEAudioUnitFilter *myReverb;
@property (nonatomic, retain) AEAudioUnitFilter *myDistortion;

@property stk::Mandolin *myMandolin;

@end

@implementation ViewController

- (void) setupAudio{
    
    
    //AEAudioController setup:
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]
                            ];
    
    NSError *errorAudioSetup = NULL;
    BOOL result = [_audioController start:&errorAudioSetup];
    if ( !result ) {
        NSLog(@"Error starting audio engine: %@", errorAudioSetup.localizedDescription);
    }
    
    
    
    //MANDOLIN SYNTH:
    self.myMandolin = new stk::Mandolin(400);
    self.myMandolin->setFrequency(400);
    
    self.mySynthChannel = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                             UInt32           frames,
                                                             AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {
            
            ((float*)audio->mBuffers[0].mData)[i] =
            ((float*)audio->mBuffers[1].mData)[i] = self.myMandolin->tick();
            
            //OR:
//            ((float*)audio->mBuffers[0].mData)[i] = self.myMandolin->tick();
//            ((float*)audio->mBuffers[1].mData)[i] = self.myMandolin->lastOut();

            
            
        }
    }];
    
    
    
    [self.audioController addChannels:@[self.mySynthChannel]];
    
    
    //REVERB:
    NSError *errorReverbSetup = NULL;
    self.myReverb = [[AEAudioUnitFilter alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_Reverb2) audioController:_audioController error:&errorReverbSetup];
    
    if (errorReverbSetup) {
        NSLog(@"Error setting up reverb: %@", errorReverbSetup.localizedDescription);
    }
    
    AudioUnitSetParameter(self.myReverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 0.0f, 0);
    
    [self.audioController addFilter:self.myReverb toChannel:self.mySynthChannel];
    
    
    
    //LOW SHELF FILTER:    
    NSError *errorDistortionSetup = NULL;
    self.myDistortion = [[AEAudioUnitFilter alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_LowShelfFilter) audioController:_audioController error:&errorDistortionSetup];
    
    if (errorDistortionSetup) {
        NSLog(@"Error setting up reverb: %@", errorDistortionSetup.localizedDescription);
    }
    
    //this should set the filter's gain to 10?
    CheckError(AudioUnitSetParameter(self.myDistortion.audioUnit, kAULowShelfParam_Gain, kAudioUnitScope_Global, 0, 10, 0), "setting filter gain to 10");
    
  
    //Uncomment one of the lines below to test the two error checking functions:
    
    //Chris Adamson's:
//    CheckError(AudioUnitSetParameter(self.myDistortion.audioUnit, kAudioUnitSubType_LowPassFilter, kAudioUnitScope_Global, 0, 10, 0), "TESTING CheckError, setting gain to 10");
    
    //check result does not format the error string well:
//    checkResult(AudioUnitSetParameter(self.myDistortion.audioUnit, kAudioUnitSubType_LowPassFilter, kAudioUnitScope_Global, 0, 10, 0), "TESTING checkResult, setting gain to 10");


    
    [self.audioController addFilter:self.myDistortion toChannel:self.mySynthChannel];
    
    
    
}

-(IBAction)sliderMoved:(UISlider *)sender{
    
    AudioUnitSetParameter(self.myReverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, sender.value, 0);
    
    NSLog(@"dry wet set to %f", sender.value);
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
