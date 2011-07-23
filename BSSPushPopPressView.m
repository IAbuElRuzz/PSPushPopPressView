//
// -----------------------------------------------------------------------------
// Copyright (c) 2011 Blacksmith Software

// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
// -----------------------------------------------------------------------------
//
//  BSSPushPopPressView.m
//
//  Copyright 2011 Blacksmith Software. All rights reserved.
//

#import "BSSPushPopPressView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BSSPushPopPressView

@synthesize delegate;

- (id) initWithFrame: (CGRect) _frame {
    if ((self = [super initWithFrame: _frame])) {
        self.userInteractionEnabled = YES;
        
        scaleTransform = CGAffineTransformIdentity;
        rotateTransform = CGAffineTransformIdentity;
        panTransform = CGAffineTransformIdentity;
        
        initialFrame = _frame;
        
        UIPinchGestureRecognizer* pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget: self action: @selector(pinch:)];
        pinchRecognizer.delegate = self;
        [self addGestureRecognizer: pinchRecognizer];
        [pinchRecognizer release];
        
        UIRotationGestureRecognizer* rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget: self action: @selector(rotate:)];
        rotationRecognizer.delegate = self;
        [self addGestureRecognizer: rotationRecognizer];
        [rotationRecognizer release];
        
        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(pan:)];
        panRecognizer.delegate = self;
        panRecognizer.minimumNumberOfTouches = 2;
        panRecognizer.maximumNumberOfTouches = 2;
        [self addGestureRecognizer: panRecognizer];
        [panRecognizer release];
        
        UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tap:)];
        [self addGestureRecognizer: tapRecognizer];
        [tapRecognizer release];
    }
    
    return self;
}

- (void) dealloc {
    delegate = nil;
    [super dealloc];
}

- (void) moveViewToOriginalPosition {
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    rotateTransform = CGAffineTransformIdentity;
    panTransform = CGAffineTransformIdentity;
    scaleTransform = CGAffineTransformIdentity;
    self.transform = CGAffineTransformIdentity;
    self.frame = initialFrame;
    [UIView commitAnimations];
}

- (void) checkForBeginDelegateNotification {
    if (scaleBegan == NO && rotateBegan == NO && panBegan == NO) {
        if ([self.delegate respondsToSelector: @selector(bssPushPopPressViewDidStartManipulation:)]) {
            [self.delegate bssPushPopPressViewDidStartManipulation: self];
        }
    }
}

- (void) checkForEndDelegateNotification {
    if (scaleBegan == NO && rotateBegan == NO && panBegan == NO) {
        if ([self.delegate respondsToSelector: @selector(bssPushPopPressViewDidFinishManipulation:)]) {
            [self.delegate bssPushPopPressViewDidFinishManipulation: self];
        }
    }
}

- (void) pinch: (UIPinchGestureRecognizer*) pinch {
    switch (pinch.state) {
        case UIGestureRecognizerStateBegan: { 
            [self checkForBeginDelegateNotification];
            gestureRecognizersWereCancelled = NO;
            scaleBegan = YES;
            break; }
        case UIGestureRecognizerStatePossible: { break; }
        case UIGestureRecognizerStateCancelled: {
            gestureRecognizersWereCancelled = YES;
            scaleBegan = NO;
            rotateBegan = NO;
            panBegan = NO;
            [self moveViewToOriginalPosition];
            [self checkForEndDelegateNotification];
        } break;
        case UIGestureRecognizerStateFailed: { 
            scaleBegan = NO;
            [self checkForEndDelegateNotification];
        } break; 
        case UIGestureRecognizerStateChanged: {
            scaleTransform = CGAffineTransformScale(CGAffineTransformIdentity, pinch.scale, pinch.scale);
            self.transform = CGAffineTransformConcat(CGAffineTransformConcat(scaleTransform, rotateTransform), panTransform);
            break;
        }
        case UIGestureRecognizerStateEnded: {
            scaleBegan = NO;
            rotateBegan = NO;
            panBegan = NO;
            gestureRecognizersWereCancelled = YES;
            
            if (pinch.velocity >= 15.0) {
                [UIView beginAnimations: nil context: nil];
                scaleTransform = CGAffineTransformIdentity;
                rotateTransform = CGAffineTransformIdentity;
                panTransform = CGAffineTransformIdentity;
                self.transform = CGAffineTransformIdentity;
                self.frame = self.window.bounds;
                [UIView commitAnimations];
            } else if (pinch.scale * self.frame.size.width > (self.window.bounds.size.width * 0.75)) {
                [UIView beginAnimations: nil context: nil];
                [UIView setAnimationBeginsFromCurrentState: YES];
                scaleTransform = CGAffineTransformIdentity;
                rotateTransform = CGAffineTransformIdentity;
                panTransform = CGAffineTransformIdentity;
                self.transform = CGAffineTransformIdentity;
                self.frame = self.window.bounds;                
                [UIView commitAnimations];
            } else {
                [self moveViewToOriginalPosition];
            }
            [self checkForEndDelegateNotification];
            break; 
        }
    }
}

- (void) rotate: (UIRotationGestureRecognizer*) rotate {
    if (rotate.state == UIGestureRecognizerStateBegan) {
        gestureRecognizersWereCancelled = NO;
    }
    
    if (gestureRecognizersWereCancelled) return;
    
    switch (rotate.state) {
        case UIGestureRecognizerStateBegan: { 
            [self checkForBeginDelegateNotification];
            rotateBegan = YES;
        } break;
        case UIGestureRecognizerStatePossible: { break; }
        case UIGestureRecognizerStateCancelled: { 
            rotateBegan = NO;
            [self moveViewToOriginalPosition];
            [self checkForEndDelegateNotification];
        } break;
        case UIGestureRecognizerStateFailed: { 
            rotateBegan = NO;
            [self checkForEndDelegateNotification];
        } break;
        case UIGestureRecognizerStateChanged: {
            rotateTransform = CGAffineTransformRotate(CGAffineTransformIdentity, rotate.rotation);
            self.transform = CGAffineTransformConcat(CGAffineTransformConcat(scaleTransform, rotateTransform), panTransform);
            break;
        }
        case UIGestureRecognizerStateEnded: {
            rotateBegan = NO;
            rotateTransform = CGAffineTransformIdentity;
            [self checkForEndDelegateNotification];
            break; 
        }
    }
}

- (void) pan: (UIPanGestureRecognizer*) pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        gestureRecognizersWereCancelled = NO;
    }
    
    if (gestureRecognizersWereCancelled) return;
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: { 
            [self checkForBeginDelegateNotification];
            panBegan = YES;
        } break;
        case UIGestureRecognizerStatePossible: { break; }
        case UIGestureRecognizerStateCancelled: { 
            panBegan = NO;
            [self moveViewToOriginalPosition];
            [self checkForEndDelegateNotification];
        } break;
        case UIGestureRecognizerStateFailed: { 
            panBegan = NO;
            [self checkForEndDelegateNotification];
        } break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [pan translationInView: self.superview];
            panTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, translation.x, translation.y);
            self.transform = CGAffineTransformConcat(CGAffineTransformConcat(scaleTransform, rotateTransform), panTransform);
            break;
        }
        case UIGestureRecognizerStateEnded: { 
            panBegan = NO;
            panTransform = CGAffineTransformIdentity;
            self.transform = CGAffineTransformConcat(CGAffineTransformConcat(scaleTransform, rotateTransform), panTransform);
            [self checkForEndDelegateNotification];
            break; 
        }
    }
}

- (void) tap: (UITapGestureRecognizer*) tap {
    if (CGRectEqualToRect(self.frame, initialFrame)) {
        [UIView animateWithDuration: 0.35 animations: ^{
            self.frame = CGRectMake(self.window.bounds.origin.x - 15, self.window.bounds.origin.y - 15, self.window.bounds.size.width + 30, self.window.bounds.size.height + 30);
        } completion: ^(BOOL finished) {
            [UIView animateWithDuration: 0.2 animations: ^{
                self.frame = self.window.bounds;
            }];
        }];
    } else {
        [UIView animateWithDuration: 0.35 animations: ^{
            self.frame = CGRectMake(initialFrame.origin.x + 4, initialFrame.origin.y + 4, initialFrame.size.width - 8, initialFrame.size.height - 8);
        } completion: ^(BOOL finished) {
            [UIView animateWithDuration: 0.15 animations: ^{
                self.frame = initialFrame;
            }];
        }];
    }
}

- (BOOL) gestureRecognizer: (UIGestureRecognizer*) gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer: (UIGestureRecognizer*) otherGestureRecognizer {
    return YES;
}

@end
