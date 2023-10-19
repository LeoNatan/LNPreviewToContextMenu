//
//  UIViewController+UIPreviewContextCompat.m
//  LNPreviewToContextMenu
//
//  Created by Leo Natan on 9/20/19.
//  Copyright © 2019-2021 Leo Natan. All rights reserved.
//

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@import UIKit;
@import ObjectiveC;

static void* _LNPReviewContextCompatPreviewActionKey = &_LNPReviewContextCompatPreviewActionKey;

#pragma mark Support class

@class _LNPreviewContextCompatContextMenuInteraction;

@interface _LNPreviewContextCompatSupport : NSObject <UIViewControllerPreviewing>

@property (nonatomic, strong) UIGestureRecognizer *previewingGestureRecognizerForFailureRelationship;
@property (nonatomic, weak) id<UIViewControllerPreviewingDelegate> delegate;
@property (nonatomic, strong) UIView *sourceView;
@property (nonatomic) CGRect sourceRect;

@property (nonatomic, weak) _LNPreviewContextCompatContextMenuInteraction* interaction;

@end
@implementation _LNPreviewContextCompatSupport

- (void)setSourceRect:(CGRect)sourceRect
{
	_sourceRect = sourceRect;
}

@end

#pragma mark Context menu transformer

API_AVAILABLE(ios(13.0))
@interface _LNPreviewContextCompatContextMenuInteraction : UIContextMenuInteraction <UIContextMenuInteractionDelegate>

- (instancetype)init;
@property (nonatomic, strong) _LNPreviewContextCompatSupport* compatSupport;
@property (nonatomic, strong) UIViewController* previewViewController;
@property (nonatomic, strong) UIView* snapshotForTargetedPreview;

@end

@implementation _LNPreviewContextCompatContextMenuInteraction

- (instancetype)init
{
	return [super initWithDelegate:self];
}

- (UIMenuElement*)_menuElementForPreviewActionItem:(NSObject<UIPreviewActionItem>*)previewActionItem
{
	NSString* title = previewActionItem.title;
	UIImage* image = [previewActionItem valueForKey:@"image"];
	__weak __typeof(self) weakSelf = self;
	UIMenuElement* rv = nil;
	
	if([previewActionItem isKindOfClass:UIPreviewAction.class])
	{
		UIAction* action = [UIAction actionWithTitle:title image:image identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
			UIPreviewAction* userActionItem = (id)previewActionItem;
			void (^handler)(UIPreviewAction *action, UIViewController *previewViewController) = [userActionItem valueForKey:@"handler"];
			handler(userActionItem, weakSelf.previewViewController);
		}];
		
		if([[previewActionItem valueForKey:@"style"] unsignedIntegerValue] == UIPreviewActionStyleDestructive)
		{
			action.attributes = UIMenuElementAttributesDestructive;
		}
	
		rv = action;
	}
	else if([previewActionItem isKindOfClass:UIPreviewActionGroup.class])
	{
		NSArray* subActions = [previewActionItem valueForKey:@"actions"];
		
		NSMutableArray* menuItems = [NSMutableArray new];
		[subActions enumerateObjectsUsingBlock:^(id<UIPreviewActionItem>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			id element = [self _menuElementForPreviewActionItem:obj];
			
			if(element)
			{
				[menuItems addObject:element];
			}
		}];
		
		rv = [UIMenu menuWithTitle:title image:image identifier:nil options:0 children:menuItems];
	}
	
	return rv;
}

- (UIMenu*)_menuForPreviewViewController
{
	NSArray<id<UIPreviewActionItem>>* previewActionItems = [self.previewViewController previewActionItems];
	if(previewActionItems.count == 0)
	{
		return nil;
	}
	
	NSMutableArray* menuItems = [NSMutableArray new];
	[previewActionItems enumerateObjectsUsingBlock:^(id<UIPreviewActionItem>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		id element = [self _menuElementForPreviewActionItem:obj];
		
		if(element)
		{
			[menuItems addObject:element];
		}
	}];
	
	return [UIMenu menuWithTitle:@"" children:menuItems];
}

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location
{
	self.compatSupport.sourceRect = self.compatSupport.sourceView.bounds;
	self.previewViewController = [self.compatSupport.delegate previewingContext:self.compatSupport viewControllerForLocation:location];
	
	if(self.previewViewController == nil)
	{
		return nil;
	}
	
	return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
		return self.previewViewController;
	} actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
		return self._menuForPreviewViewController;
	}];
}

- (nullable UITargetedPreview *)contextMenuInteraction:(UIContextMenuInteraction *)interaction previewForHighlightingMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
{
	if(CGRectEqualToRect(self.compatSupport.sourceRect, self.compatSupport.sourceView.bounds))
	{
		return nil;
	}
	
	if([self.compatSupport.sourceView isKindOfClass:UITableView.class] || [self.compatSupport.sourceView isKindOfClass:UICollectionView.class])
	{
		CGPoint center = CGPointMake(CGRectGetMidX(self.compatSupport.sourceRect), CGRectGetMidY(self.compatSupport.sourceRect));
		id tableView = self.compatSupport.sourceView;
		
		UIView* cell = nil;
		if([self.compatSupport.sourceView isKindOfClass:UICollectionView.class])
		{
			cell = [tableView cellForItemAtIndexPath:[tableView indexPathForItemAtPoint:center]];
		}
		else
		{
			cell = [tableView cellForRowAtIndexPath:[tableView indexPathForRowAtPoint:center]];
		}
		
		if(CGRectEqualToRect([tableView convertRect:cell.bounds fromView:cell], self.compatSupport.sourceRect))
		{
			return [[UITargetedPreview alloc] initWithView:cell parameters:[UIPreviewParameters new]];
		}
	}
	
	self.snapshotForTargetedPreview = [self.compatSupport.sourceView snapshotViewAfterScreenUpdates:YES];
	CGRect frame = CGRectOffset(self.snapshotForTargetedPreview.frame, self.compatSupport.sourceView.bounds.origin.x, self.compatSupport.sourceView.bounds.origin.y);
	self.snapshotForTargetedPreview.frame = frame;
	
	[self.compatSupport.sourceView addSubview:self.snapshotForTargetedPreview];
	
	UIPreviewParameters* params = [UIPreviewParameters new];
	params.visiblePath = [UIBezierPath bezierPathWithRect:CGRectOffset(self.compatSupport.sourceRect, - self.compatSupport.sourceView.bounds.origin.x, - self.compatSupport.sourceView.bounds.origin.y)];
	return [[UITargetedPreview alloc] initWithView:self.snapshotForTargetedPreview parameters:params];
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator
{
	UIViewController* vc = animator.previewViewController;
	[animator addAnimations:^{
		[self.compatSupport.delegate previewingContext:self.compatSupport commitViewController:vc];
	}];
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willEndForConfiguration:(UIContextMenuConfiguration *)configuration animator:(nullable id<UIContextMenuInteractionAnimating>)animator
{
	id snapshotViewToRemove = self.snapshotForTargetedPreview;
	self.snapshotForTargetedPreview = nil;
	
	dispatch_block_t block = ^{
		[snapshotViewToRemove removeFromSuperview];
	};
	
	if(animator != nil)
	{
		[animator addCompletion:block];
	}
	else
	{
		block();
	}
}

@end

#pragma mark UIViewController category

@interface UIViewController (UIPreviewContextCompat) @end

@implementation UIViewController (UIPreviewContextCompat)

+ (void)load
{
	if(@available(iOS 13, *))
	{
		Method m1 = class_getInstanceMethod(UIViewController.class, @selector(registerForPreviewingWithDelegate:sourceView:));
		Method m2 = class_getInstanceMethod(UIViewController.class, @selector(_ln_registerForPreviewingWithDelegate:sourceView:));
		method_exchangeImplementations(m1, m2);
		
		m1 = class_getInstanceMethod(UIViewController.class, @selector(unregisterForPreviewingWithContext:));
		m2 = class_getInstanceMethod(UIViewController.class, @selector(_ln_unregisterForPreviewingWithContext:));
		method_exchangeImplementations(m1, m2);
	}
}

- (id<UIViewControllerPreviewing>)_ln_registerForPreviewingWithDelegate:(id<UIViewControllerPreviewingDelegate>)delegate sourceView:(UIView *)sourceView API_AVAILABLE(ios(13.0))
{
	_LNPreviewContextCompatSupport* rv = [_LNPreviewContextCompatSupport new];
	rv.delegate = delegate;
	rv.sourceView = sourceView;
	rv.sourceRect = sourceView.bounds;
	
	_LNPreviewContextCompatContextMenuInteraction* interaction = [[_LNPreviewContextCompatContextMenuInteraction alloc] init];
	interaction.compatSupport = rv;
	
	rv.interaction = interaction;
	
	[sourceView addInteraction:interaction];
	
	return rv;
}

- (void)_ln_unregisterForPreviewingWithContext:(_LNPreviewContextCompatSupport*)previewing API_AVAILABLE(ios(13.0))
{
	if([previewing isKindOfClass:_LNPreviewContextCompatSupport.class] == NO)
	{
		[self _ln_unregisterForPreviewingWithContext:previewing];
		return;
	}
	
	_LNPreviewContextCompatContextMenuInteraction* interaction = [previewing interaction];
	[previewing.sourceView removeInteraction:interaction];
}

@end

#pragma GCC diagnostic pop
