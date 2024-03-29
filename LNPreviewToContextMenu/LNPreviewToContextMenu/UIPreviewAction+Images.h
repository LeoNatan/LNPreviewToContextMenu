//
//  UIPreviewAction+Images.h
//  LNPreviewToContextMenu
//
//  Created by Leo Natan on 9/20/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIPreviewAction ()

@property(retain, nonatomic, nullable) UIImage *image API_AVAILABLE(ios(13.0));

@end

@interface UIPreviewActionGroup ()

@property(retain, nonatomic, nullable) UIImage *image API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END
