//
//  SCXcodeMinimap.m
//  SCXcodeMinimap
//
//  Created by Stefan Ceriu on 3/30/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved
//

#import "SCXcodeMinimap.h"
#import "SCXcodeMinimapView.h"

#import "IDESourceCodeEditor.h"
#import "DVTSourceTextView.h"

#import "DVTPreferenceSetManager.h"
#import "DVTFontAndColorTheme.h"

NSString *const IDESourceCodeEditorDidFinishSetupNotification = @"IDESourceCodeEditorDidFinishSetup";

NSString *const SCXcodeMinimapShouldDisplayChangeNotification = @"SCXcodeMinimapShouldDisplayChangeNotification";
NSString *const SCXcodeMinimapShouldDisplayKey = @"SCXcodeMinimapShouldDisplayKey";

NSString *const SCXcodeMinimapZoomLevelChangeNotification = @"SCXcodeMinimapZoomLevelChangeNotification";
NSString *const SCXcodeMinimapZoomLevelKey = @"SCXcodeMinimapZoomLevelKey";

NSString *const SCXcodeMinimapHighlightBreakpointsChangeNotification = @"SCXcodeMinimapHighlightBreakpointsChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightBreakpointsKey = @"SCXcodeMinimapShouldHighlightBreakpointsKey";

NSString *const SCXcodeMinimapHighlightIssuesChangeNotification = @"SCXcodeMinimapHighlightIssuesChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightIssuesKey = @"SCXcodeMinimapShouldHighlightIssuesKey";

NSString *const SCXcodeMinimapHighlightSelectedSymbolChangeNotification = @"SCXcodeMinimapHighlightSelectedSymbolChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightSelectedSymbolKey = @"SCXcodeMinimapShouldHighlightSelectedSymbolKey";

NSString *const SCXcodeMinimapHighlightSearchResultsChangeNotification = @"SCXcodeMinimapHighlightSearchResultsChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightSearchResultsKey = @"SCXcodeMinimapShouldHighlightSearchResultsKey";

NSString *const SCXcodeMinimapHighlightCommentsChangeNotification = @"SCXcodeMinimapHighlightCommentsChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightCommentsKey  = @"SCXcodeMinimapShouldHighlightCommentsKey";

NSString *const SCXcodeMinimapHighlightPreprocessorChangeNotification = @"SCXcodeMinimapHighlightPreprocessorChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightPreprocessorKey  = @"SCXcodeMinimapShouldHighlightPreprocessorKey";

NSString *const SCXcodeMinimapHighlightEditorChangeNotification = @"SCXcodeMinimapHighlightEditorChangeNotification";
NSString *const SCXcodeMinimapShouldHighlightEditorKey = @"SCXcodeMinimapShouldHighlightEditorKey";

NSString *const SCXcodeMinimapHideEditorScrollerChangeNotification = @"SCXcodeMinimapHideEditorScrollerChangeNotification";
NSString *const SCXcodeMinimapShouldHideEditorScrollerKey  = @"SCXcodeMinimapShouldHideEditorScrollerKey";

NSString *const SCXcodeMinimapAutohideChangeNotification = @"SCXcodeMinimapAutohideChangeNotification";
NSString *const SCXcodeMinimapShouldAutohideKey = @"SCXcodeMinimapShouldAutohideKey";

NSString *const SCXcodeMinimapThemeChangeNotification = @"SCXcodeMinimapThemeChangeNotification";
NSString *const SCXcodeMinimapThemeKey  = @"SCXcodeMinimapThemeKey";

NSString *const kViewMenuItemTitle = @"View";

NSString *const kMinimapMenuItemTitle = @"Minimap";
NSString *const kShowMinimapMenuItemTitle = @"Show Minimap";
NSString *const kHideMinimapMenuItemTitle = @"Hide Minimap";

NSString *const kSizeMenuItemTitle = @"Size";

NSString *const kHighlightBreakpointsMenuItemTitle = @"Highlight breakpoints";
NSString *const kHighlightIssuesMenuItemTitle = @"Highlight issues";
NSString *const kHighlightSelectedSymbolMenuItemTitle = @"Highlight selected symbol";
NSString *const kHighlightSearchResultsMenuItemTitle = @"Highlight search results";
NSString *const kHighlightCommentsMenuItemTitle = @"Highlight comments";
NSString *const kHighlightPreprocessorMenuItemTitle = @"Highlight preprocessor";
NSString *const kHighlightEditorMenuItemTitle = @"Highlight main editor";
NSString *const kHideEditorScrollerMenuItemTitle = @"Hide editor scroller";
NSString *const kAutohideMenuItemTitle = @"Autohide";

NSString *const kThemeMenuItemTitle = @"Theme";
NSString *const kEditorThemeMenuItemTitle = @"Editor Theme";

@implementation SCXcodeMinimap

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	BOOL isApplicationXcode = [[[NSBundle mainBundle] infoDictionary][@"CFBundleName"] isEqual:@"Xcode"];
	if (isApplicationXcode) {
		static SCXcodeMinimap *sharedMinimap = nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sharedMinimap = [[self alloc] init];
		});
	}
}

- (id)init
{
	if (self = [super init]) {
		
		[self registerUserDefaults];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self createMenuItem];
		});
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishSetup:) name:IDESourceCodeEditorDidFinishSetupNotification object:nil];
	}
	return self;
}

- (void)registerUserDefaults
{
	NSDictionary *userDefaults = @{SCXcodeMinimapZoomLevelKey                     : @(0.1f),
								   SCXcodeMinimapShouldDisplayKey                 : @(YES),
								   SCXcodeMinimapShouldHighlightBreakpointsKey    : @(YES),
								   SCXcodeMinimapShouldHighlightIssuesKey         : @(YES),
								   SCXcodeMinimapShouldHighlightSelectedSymbolKey : @(YES),
								   SCXcodeMinimapShouldHighlightSearchResultsKey  : @(YES),
								   SCXcodeMinimapShouldHighlightCommentsKey       : @(YES),
								   SCXcodeMinimapShouldHighlightPreprocessorKey   : @(YES)};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
}

#pragma mark - Menu Items and Actions

- (void)createMenuItem
{
	NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:kViewMenuItemTitle];
	
	if(viewMenuItem == nil) {
		return;
	}
	
	[viewMenuItem.submenu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *minimapMenuItem = [[NSMenuItem alloc] initWithTitle:kMinimapMenuItemTitle action:nil keyEquivalent:@""];
	[viewMenuItem.submenu addItem:minimapMenuItem];
	
	NSMenu *minimapMenu = [[NSMenu alloc] init];
	{
		NSMenuItem *showHideMinimapItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(toggleMinimap:) keyEquivalent:@"M"];
		[showHideMinimapItem setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];
		[showHideMinimapItem setTarget:self];
		[minimapMenu addItem:showHideMinimapItem];
		
		[minimapMenu addItem:[NSMenuItem separatorItem]];
		
		NSView *sizeView = [[NSView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 225.0f, 20.0f)];
		[sizeView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
		
		NSTextField *sizeViewTitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20.0f, 0.0f, 50.0f, 20.0f)];
		[sizeViewTitleLabel setStringValue:kSizeMenuItemTitle];
		[sizeViewTitleLabel setFont:[NSFont systemFontOfSize:14]];
		[sizeViewTitleLabel setBezeled:NO];
		[sizeViewTitleLabel setDrawsBackground:NO];
		[sizeViewTitleLabel setEditable:NO];
		[sizeViewTitleLabel setSelectable:NO];
		[sizeView addSubview:sizeViewTitleLabel];
		
		NSSlider *sizeSlider = [[NSSlider alloc] initWithFrame:CGRectMake(60.0f, 0.0f, 156.0f, 20.0f)];
		[sizeSlider setMaxValue:0.35f];
		[sizeSlider setMinValue:0.05f];
		[sizeSlider setTarget:self];
		[sizeSlider setAction:@selector(onSizeSliderValueChanged:)];
		[sizeSlider setDoubleValue:[[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapZoomLevelKey] doubleValue]];
		[sizeView addSubview:sizeSlider];
		
		NSMenuItem *minimapSizeItem = [[NSMenuItem alloc] init];
		[minimapSizeItem setView:sizeView];
		[minimapMenu addItem:minimapSizeItem];
		
		BOOL shouldDisplayMinimap = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldDisplayKey] boolValue];
		[showHideMinimapItem setTitle:(shouldDisplayMinimap ? kHideMinimapMenuItemTitle : kShowMinimapMenuItemTitle)];
		
		[minimapMenu addItem:[NSMenuItem separatorItem]];
	}
	
	{
		NSMenuItem *highlightBreakpointsMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightBreakpointsMenuItemTitle
																			  action:@selector(toggleBreakpointHighlighting:) keyEquivalent:@""];
		[highlightBreakpointsMenuItem setTarget:self];
		[minimapMenu addItem:highlightBreakpointsMenuItem];
		
		BOOL breakpointHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightBreakpointsKey] boolValue];
		[highlightBreakpointsMenuItem setState:(breakpointHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightIssuesMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightIssuesMenuItemTitle
																		 action:@selector(toggleIssuesHighlighting:) keyEquivalent:@""];
		[highlightIssuesMenuItem setTarget:self];
		[minimapMenu addItem:highlightIssuesMenuItem];
		
		BOOL issueHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightIssuesKey] boolValue];
		[highlightIssuesMenuItem setState:(issueHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightSelectedSymbolMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightSelectedSymbolMenuItemTitle
																				 action:@selector(toggleSelectedSymbolHighlighting:) keyEquivalent:@""];
		[highlightSelectedSymbolMenuItem setTarget:self];
		[minimapMenu addItem:highlightSelectedSymbolMenuItem];
		
		BOOL selectedSymbolHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightSelectedSymbolKey] boolValue];
		[highlightSelectedSymbolMenuItem setState:(selectedSymbolHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightSearchResultsMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightSearchResultsMenuItemTitle
																				action:@selector(toggleSearchResultsHighlighting:) keyEquivalent:@""];
		[highlightSearchResultsMenuItem setTarget:self];
		[minimapMenu addItem:highlightSearchResultsMenuItem];
		
		BOOL searchResultsHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightSearchResultsKey] boolValue];
		[highlightSearchResultsMenuItem setState:(searchResultsHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightCommentsMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightCommentsMenuItemTitle
																		   action:@selector(toggleCommentsHighlighting:) keyEquivalent:@""];
		[highlightCommentsMenuItem setTarget:self];
		[minimapMenu addItem:highlightCommentsMenuItem];
		
		BOOL commentsHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightCommentsKey] boolValue];
		[highlightCommentsMenuItem setState:(commentsHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightPreprocessorMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightPreprocessorMenuItemTitle
																			   action:@selector(togglePreprocessorHighlighting:) keyEquivalent:@""];
		[highlightPreprocessorMenuItem setTarget:self];
		[minimapMenu addItem:highlightPreprocessorMenuItem];
		
		BOOL preprocessorHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightPreprocessorKey] boolValue];
		[highlightPreprocessorMenuItem setState:(preprocessorHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *highlightEditorMenuItem = [[NSMenuItem alloc] initWithTitle:kHighlightEditorMenuItemTitle
																		 action:@selector(toggleEditorHighlighting:) keyEquivalent:@""];
		[highlightEditorMenuItem setTarget:self];
		[minimapMenu addItem:highlightEditorMenuItem];
		
		BOOL editorHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightEditorKey] boolValue];
		[highlightEditorMenuItem setState:(editorHighlightingEnabled ? NSOnState : NSOffState)];
		
		
		NSMenuItem *hideEditorScrollerMenuItem = [[NSMenuItem alloc] initWithTitle:kHideEditorScrollerMenuItemTitle
																			action:@selector(toggleEditorScrollerHiding:) keyEquivalent:@""];
		[hideEditorScrollerMenuItem setTarget:self];
		[minimapMenu addItem:hideEditorScrollerMenuItem];
		
		BOOL shouldHideEditorScroller = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHideEditorScrollerKey] boolValue];
		[hideEditorScrollerMenuItem setState:(shouldHideEditorScroller ? NSOnState : NSOffState)];
		
		
		NSMenuItem *autohideMenuItem = [[NSMenuItem alloc] initWithTitle:kAutohideMenuItemTitle
																  action:@selector(toggleAutohide:) keyEquivalent:@""];
		[autohideMenuItem setTarget:self];
		[minimapMenu addItem:autohideMenuItem];
		
		BOOL shouldAutohide = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldAutohideKey] boolValue];
		[autohideMenuItem setState:(shouldAutohide ? NSOnState : NSOffState)];
		
		
		[minimapMenu addItem:[NSMenuItem separatorItem]];
	}
	
	{
		NSMenuItem *themesMenuItem = [[NSMenuItem alloc] initWithTitle:kThemeMenuItemTitle action:nil keyEquivalent:@""];
		[minimapMenu addItem:themesMenuItem];
		
		NSMenu *themesMenu = [[NSMenu alloc] init];
		{
			NSString *currentThemeName = [[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapThemeKey];
			
			NSMenuItem *editorThemeMenuItem = [[NSMenuItem alloc] initWithTitle:kEditorThemeMenuItemTitle action:@selector(setMinimapTheme:) keyEquivalent:@""];
			[editorThemeMenuItem setTarget:self];
			[themesMenu addItem:editorThemeMenuItem];
			
			if(currentThemeName == nil) {
				[editorThemeMenuItem setState:NSOnState];
			}
			
			[themesMenu addItem:[NSMenuItem separatorItem]];
			
			NSArray *themes = [[DVTFontAndColorTheme preferenceSetsManager] availablePreferenceSets];
			NSArray *builtInThemes = [themes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isBuiltIn == YES"]];
			NSArray *userThemes = [themes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isBuiltIn == NO"]];
			
			for(DVTFontAndColorTheme *theme in builtInThemes) {
				NSMenuItem *themeMenuItem = [[NSMenuItem alloc] initWithTitle:theme.localizedName action:@selector(setMinimapTheme:) keyEquivalent:@""];
				[themeMenuItem setTarget:self];
				[themesMenu addItem:themeMenuItem];
				
				if([theme.localizedName isEqualToString:currentThemeName]) {
					[themeMenuItem setState:NSOnState];
				}
			}
			
			[themesMenu addItem:[NSMenuItem separatorItem]];
			
			for(DVTFontAndColorTheme *theme in userThemes) {
				NSMenuItem *themeMenuItem = [[NSMenuItem alloc] initWithTitle:theme.localizedName action:@selector(setMinimapTheme:) keyEquivalent:@""];
				[themeMenuItem setTarget:self];
				[themesMenu addItem:themeMenuItem];
				
				if([theme.localizedName isEqualToString:currentThemeName]) {
					[themeMenuItem setState:NSOnState];
				}
			}
		}
		[themesMenuItem setSubmenu:themesMenu];
		
	}
	[minimapMenuItem setSubmenu:minimapMenu];
}

- (void)toggleMinimap:(NSMenuItem *)sender
{
	BOOL shouldDisplayMinimap = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldDisplayKey] boolValue];
	
	[sender setTitle:(!shouldDisplayMinimap ? kHideMinimapMenuItemTitle : kShowMinimapMenuItemTitle)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!shouldDisplayMinimap) forKey:SCXcodeMinimapShouldDisplayKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapShouldDisplayChangeNotification object:nil];
}

- (void)toggleBreakpointHighlighting:(NSMenuItem *)sender
{
	BOOL breakpointHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightBreakpointsKey] boolValue];
	
	[sender setState:(breakpointHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!breakpointHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightBreakpointsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightBreakpointsChangeNotification object:nil];
}

- (void)toggleIssuesHighlighting:(NSMenuItem *)sender
{
	BOOL issueHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightIssuesKey] boolValue];
	
	[sender setState:(issueHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!issueHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightIssuesKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightIssuesChangeNotification object:nil];
}

- (void)toggleSelectedSymbolHighlighting:(NSMenuItem *)sender
{
	BOOL selectedSymbolHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightSelectedSymbolKey] boolValue];
	
	[sender setState:(selectedSymbolHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!selectedSymbolHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightSelectedSymbolKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightSelectedSymbolChangeNotification object:nil];
}

- (void)toggleSearchResultsHighlighting:(NSMenuItem *)sender
{
	BOOL searchResultsHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightSearchResultsKey] boolValue];
	
	[sender setState:(searchResultsHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!searchResultsHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightSearchResultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightSearchResultsChangeNotification object:nil];
}

- (void)toggleCommentsHighlighting:(NSMenuItem *)sender
{
	BOOL commentsHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightCommentsKey] boolValue];
	
	[sender setState:(commentsHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!commentsHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightCommentsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightCommentsChangeNotification object:nil];
}

- (void)togglePreprocessorHighlighting:(NSMenuItem *)sender
{
	BOOL preprocessorHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightPreprocessorKey] boolValue];
	
	[sender setState:(preprocessorHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!preprocessorHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightPreprocessorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightPreprocessorChangeNotification object:nil];
}

- (void)toggleEditorHighlighting:(NSMenuItem *)sender
{
	BOOL editorHighlightingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHighlightEditorKey] boolValue];
	
	[sender setState:(editorHighlightingEnabled ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!editorHighlightingEnabled) forKey:SCXcodeMinimapShouldHighlightEditorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHighlightEditorChangeNotification object:nil];
}

- (void)toggleEditorScrollerHiding:(NSMenuItem *)sender
{
	BOOL shouldHideEditorScroller = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldHideEditorScrollerKey] boolValue];
	
	[sender setState:(shouldHideEditorScroller ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!shouldHideEditorScroller) forKey:SCXcodeMinimapShouldHideEditorScrollerKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapHideEditorScrollerChangeNotification object:nil];
}

- (void)toggleAutohide:(NSMenuItem *)sender
{
	BOOL shouldAutohide = [[[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapShouldAutohideKey] boolValue];
	
	[sender setState:(shouldAutohide ? NSOffState : NSOnState)];
	[[NSUserDefaults standardUserDefaults] setObject:@(!shouldAutohide) forKey:SCXcodeMinimapShouldAutohideKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapAutohideChangeNotification object:nil];
}

- (void)setMinimapTheme:(NSMenuItem *)sender
{
	NSString *currentThemeName = [[NSUserDefaults standardUserDefaults] objectForKey:SCXcodeMinimapThemeKey];
	
	if(currentThemeName == sender.title || [currentThemeName isEqualToString:sender.title]) {
		return;
	}
	
	NSMenu *themesSubmenu = [[[[NSApp mainMenu] itemWithTitle:kViewMenuItemTitle].submenu itemWithTitle:kMinimapMenuItemTitle].submenu itemWithTitle:kThemeMenuItemTitle].submenu;
	for(NSMenuItem *item in themesSubmenu.itemArray) {
		[item setState:NSOffState];
	}
	
	[sender setState:NSOnState];
	
	if([sender.menu indexOfItem:sender] == 0) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:SCXcodeMinimapThemeKey];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:sender.title forKey:SCXcodeMinimapThemeKey];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapThemeChangeNotification object:nil];
}

- (void)onSizeSliderValueChanged:(NSSlider *)sender
{
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	if(event.type != NSLeftMouseUp) {
		return;
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:@(sender.doubleValue) forKey:SCXcodeMinimapZoomLevelKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SCXcodeMinimapZoomLevelChangeNotification object:nil];
}

#pragma mark - Xcode Notification

- (void)onDidFinishSetup:(NSNotification*)sender
{
	if(![sender.object isKindOfClass:[IDESourceCodeEditor class]]) {
		NSLog(@"Could not fetch source code editor container");
		return;
	}
	
	IDESourceCodeEditor *editor = (IDESourceCodeEditor *)[sender object];
	[editor.textView setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable];
	[editor.scrollView setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable];
	[editor.containerView setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable];
	
	SCXcodeMinimapView *minimapView = [[SCXcodeMinimapView alloc] initWithEditor:editor];
	[editor.containerView addSubview:minimapView];
}

@end
