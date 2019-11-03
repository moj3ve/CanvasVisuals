/*
Copyright (C) 2019 aesthyrica & Justin Carlson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details. You can find more details here: https://www.gnu.org/licenses/gpl-3.0.en.html
*/

#import <UIKit/UIWindow+Private.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <objc/runtime.h>
#import <CoreMedia/CoreMedia.h>

#include "MBProgressHUD.h"
#include "ALAssetsLibrary+CustomPhotoAlbum.h"

static NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];


@interface SPTVideoDisplayView : UIView
- (AVQueuePlayer *)player;
@end

void saveVideoFromAVQueue(AVQueuePlayer *displayView){
  AVPlayerItem *currentVideo = [[displayView items] objectAtIndex:0];
  NSURL *videoURL = [currentVideo valueForKey:@"URL"];

  UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  while (topRootViewController.presentedViewController)
  {
    topRootViewController = topRootViewController.presentedViewController;
  }

  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:topRootViewController.view animated:YES];
  hud.mode = MBProgressHUDModeCustomView;
  NSString *recPath = @"/Library/Application Support/Canvas Visuals DL/";
  NSString *imagePath = [recPath stringByAppendingPathComponent:@"Checkmark.png"];
  UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
  hud.customView = [[UIImageView alloc] initWithImage:image];
  hud.square = NO;
  hud.label.text = NSLocalizedString(@"Added to \n Gallery.", @"HUD Save title");
  hud.label.numberOfLines = 2;
  hud.label.font = [UIFont fontWithName:@"CircularSpUI-Book" size:14];
  [hud hideAnimated:YES afterDelay:1.2f];
  hud.minSize = CGSizeMake(140, 145);
  
  ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
  if ([prefs valueForKey:@"albumToSaveTo"]){
    NSString *savedValue = [prefs stringForKey:@"albumToSaveTo"];
    [library saveVideo:videoURL toAlbum:savedValue completion:nil failure:nil];
  }else{
    [library saveVideo:videoURL toAlbum:@"Canvas Visuals" completion:nil failure:nil];
  }
}


%hook SPTVideoDisplayView

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
      UIAlertController *alert= [UIAlertController
                              alertControllerWithTitle:@"Enter Album Name"
                              message:@""
                              preferredStyle:UIAlertControllerStyleAlert];

      UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action){
                                               UITextField *textField = alert.textFields[0];
                                               NSString *textInput = [NSString stringWithFormat:@"%@", textField.text];
                                               [prefs setObject:textInput forKey:@"albumToSaveTo"];
                                           }];
      UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) { }];

      [alert addAction:ok];
      [alert addAction:cancel];

      [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
          textField.keyboardType = UIKeyboardTypeDefault;
      }];

      UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
      while (topRootViewController.presentedViewController)
      {
        topRootViewController = topRootViewController.presentedViewController;
      }
      [topRootViewController presentViewController:alert animated:YES completion:nil];
    }
}

%new
-(void)gestureHandler:(UISwipeGestureRecognizer *)gesture
{
  if (gesture.state == UIGestureRecognizerStateEnded) {

   }else if (gesture.state == UIGestureRecognizerStateBegan){
     saveVideoFromAVQueue([self player]);
  }
}

// had to add gesture here because it was getting over layered if added in the init method
- (void)setPlayer:(id)arg1{
  %orig();
  UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureHandler:)];
  [longPressGesture setMinimumPressDuration:0.6];
  [self addGestureRecognizer:longPressGesture];

  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
  tapGesture.numberOfTapsRequired = 3;
  [self addGestureRecognizer:tapGesture];
}

%end

@interface SPTPopupDialog : UIViewController
+(id)popupWithTitle:(NSString *)title message:(NSString *)message dismissButtonTitle:(NSString *)buttonTitle;
+(id)popupWithTitle:(NSString *)title message:(NSString *)message buttons:(id)buttons;
-(void)dismissSelf;
@end

@interface SPTPopupButton : NSObject
+(id)buttonWithTitle:(NSString *)arg1;
+(id)buttonWithTitle:(NSString *)arg1 actionHandler:(id)arg2;
@end

@interface SPTPopupManager : NSObject
@property(nonatomic, readwrite, assign) NSMutableArray *presentationQueue;
+(SPTPopupManager *)sharedManager;
-(void)presentNextQueuedPopup;
@end

%hook SpotifyAppDelegate
  -(BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"2run"]) {
      SPTPopupButton *cancelAction = [%c(SPTPopupButton) buttonWithTitle:@"Dismiss"];
      NSArray *buttons = [[NSArray alloc] initWithObjects:cancelAction, nil];

      SPTPopupDialog *copyURIPopup = [%c(SPTPopupDialog) popupWithTitle:@"Canvas Visuals DL" message:@"Long press on a Canvas Visual to download." buttons:buttons];

      [[%c(SPTPopupManager) sharedManager].presentationQueue addObject:copyURIPopup];
      [[%c(SPTPopupManager) sharedManager] presentNextQueuedPopup];

        [[NSUserDefaults standardUserDefaults] setValue:@"2run" forKey:@"2run"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return %orig;
  }
%end
