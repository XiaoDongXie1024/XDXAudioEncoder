//
//  ViewController.m
//  XDXAudioUnitCapture
//
//  Created by 小东邪 on 2019/5/10.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import "ViewController.h"
#import "XDXAudioCaptureManager.h"
#import "XDXAduioEncoder.h"
#import "XDXAudioFileHandler.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<XDXAudioCaptureDelegate>

@property (nonatomic, assign) BOOL isRecordVoice;

@property (nonatomic, strong) XDXAduioEncoder *audioEncoder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Capture
    [XDXAudioCaptureManager getInstance].delegate = self;
    [[XDXAudioCaptureManager getInstance] startAudioCapture];
    
    // Encoder
    AudioStreamBasicDescription audioDataFormat = [[XDXAudioCaptureManager getInstance] getAudioDataFormat];
    self.audioEncoder = [[XDXAduioEncoder alloc] initWithSourceFormat:audioDataFormat
                                                         destFormatID:kAudioFormatMPEG4AAC
                                                           sampleRate:44100
                                                  isUseHardwareEncode:YES];
}

- (IBAction)startRecord:(id)sender {
    [self startRecordFile];
}

- (IBAction)stopRecord:(id)sender {
    [self stopRecordFile];
}

- (void)dealloc {
    [[XDXAudioCaptureManager getInstance] stopAudioCapture];
}

#pragma mark - Record
- (void)startRecordFile {
    [[XDXAudioFileHandler getInstance] startVoiceRecordByAudioUnitByAudioConverter:self.audioEncoder->mAudioConverter
                                                                   needMagicCookie:YES
                                                                         audioDesc:self.audioEncoder->mDestinationFormat];
    self.isRecordVoice = YES;
}

- (void)stopRecordFile {
    self.isRecordVoice = NO;
    [[XDXAudioFileHandler getInstance] stopVoiceRecordAudioConverter:self.audioEncoder->mAudioConverter
                                                     needMagicCookie:YES];
}

#pragma mark - Delegate
- (void)receiveAudioDataByDevice:(XDXCaptureAudioDataRef)audioDataRef {
    [self.audioEncoder encodeAudioWithSourceBuffer:audioDataRef->data
                                  sourceBufferSize:audioDataRef->size
                                   completeHandler:^(AudioBufferList * _Nonnull destBufferList, UInt32 outputPackets, AudioStreamPacketDescription * _Nonnull outputPacketDescriptions) {
                                       if (self.isRecordVoice) {
                                           [[XDXAudioFileHandler getInstance] writeFileWithInNumBytes:destBufferList->mBuffers->mDataByteSize
                                                                                         ioNumPackets:outputPackets
                                                                                             inBuffer:destBufferList->mBuffers->mData
                                                                                         inPacketDesc:outputPacketDescriptions];
                                       }
                                       
                                       free(destBufferList->mBuffers->mData);
                                   }];
}

@end
