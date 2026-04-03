#import "VideoScreenSaverView.h"
@import AVFoundation;
@import UniformTypeIdentifiers;

static NSString *const kVideoPathKey = @"VideoPath";
static NSString *const kSuiteName = @"com.generald.VideoScreenSaver";

@implementation VideoScreenSaverView {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    id _loopObserver;
    id _visibilityObserver;
    NSWindow *_configWindow;
    BOOL _isPreview;
}

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        _isPreview = isPreview;
        [self setAnimationTimeInterval:DBL_MAX];
        [self setWantsLayer:YES];
    }
    return self;
}

#pragma mark - Lifecycle

- (void)startAnimation {
    [super startAnimation];
    [self setupPlayer];
}

- (void)stopAnimation {
    [self tearDownPlayer];
    [super stopAnimation];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (!self.window) {
        [self tearDownPlayer];
    }
}

- (void)dealloc {
    [self tearDownPlayer];
}

- (void)drawRect:(NSRect)rect {
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
}

- (void)animateOneFrame {
    // No-op: AVPlayerLayer renders via Core Animation.
}

#pragma mark - Preferences

- (NSUserDefaults *)prefs {
    return [[NSUserDefaults alloc] initWithSuiteName:kSuiteName];
}

- (NSString *)videoPath {
    return [[self prefs] stringForKey:kVideoPathKey];
}

- (void)setVideoPath:(NSString *)path {
    [[self prefs] setObject:path forKey:kVideoPathKey];
    [[self prefs] synchronize];
}

#pragma mark - Player

- (void)setupPlayer {
    NSString *path = [self videoPath];
    if (!path || path.length == 0) return;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return;

    NSURL *url = [NSURL fileURLWithPath:path];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:item];
    _player.muted = YES;
    _player.volume = 0;
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.bounds;
    _playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:_playerLayer];

    __weak AVPlayer *weakPlayer = _player;
    _loopObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
        object:item
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            [weakPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {}];
        }];

    [_player play];

    // Pause when the screensaver window becomes non-visible (e.g. occluded).
    _visibilityObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSWindowDidChangeOcclusionStateNotification
        object:self.window
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            NSWindow *win = [note object];
            if (win.occlusionState & NSWindowOcclusionStateVisible) {
                [weakPlayer play];
            } else {
                [weakPlayer pause];
            }
        }];
}

- (void)tearDownPlayer {
    if (_loopObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_loopObserver];
        _loopObserver = nil;
    }
    if (_visibilityObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_visibilityObserver];
        _visibilityObserver = nil;
    }
    [_player pause];
    [_player replaceCurrentItemWithPlayerItem:nil];
    [_playerLayer removeFromSuperlayer];
    _player = nil;
    _playerLayer = nil;
}

#pragma mark - Config Sheet

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow *)configureSheet {
    if (!_configWindow) {
        _configWindow = [self createConfigSheet];
    }
    NSTextField *pathField = [_configWindow.contentView viewWithTag:100];
    pathField.stringValue = [self videoPath] ?: @"";
    return _configWindow;
}

- (NSWindow *)createConfigSheet {
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(0, 0, 500, 160)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
        backing:NSBackingStoreBuffered
        defer:NO];
    window.title = @"Video Screensaver";

    NSView *content = window.contentView;

    NSTextField *label = [NSTextField labelWithString:@"Video File:"];
    label.frame = NSMakeRect(20, 110, 80, 20);

    NSTextField *pathField = [[NSTextField alloc] initWithFrame:NSMakeRect(100, 108, 300, 24)];
    pathField.editable = NO;
    pathField.tag = 100;

    NSButton *browseBtn = [[NSButton alloc] initWithFrame:NSMakeRect(410, 106, 70, 28)];
    browseBtn.title = @"Browse";
    browseBtn.bezelStyle = NSBezelStyleRounded;
    browseBtn.target = self;
    browseBtn.action = @selector(browseVideo:);

    NSButton *okBtn = [[NSButton alloc] initWithFrame:NSMakeRect(400, 20, 80, 28)];
    okBtn.title = @"OK";
    okBtn.bezelStyle = NSBezelStyleRounded;
    okBtn.keyEquivalent = @"\r";
    okBtn.target = self;
    okBtn.action = @selector(saveAndClose:);

    NSButton *cancelBtn = [[NSButton alloc] initWithFrame:NSMakeRect(310, 20, 80, 28)];
    cancelBtn.title = @"Cancel";
    cancelBtn.bezelStyle = NSBezelStyleRounded;
    cancelBtn.keyEquivalent = @"\033";
    cancelBtn.target = self;
    cancelBtn.action = @selector(dismissSheet:);

    [content addSubview:label];
    [content addSubview:pathField];
    [content addSubview:browseBtn];
    [content addSubview:okBtn];
    [content addSubview:cancelBtn];

    return window;
}

- (IBAction)browseVideo:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedContentTypes = @[UTTypeMovie, UTTypeMPEG4Movie, UTTypeQuickTimeMovie];
    panel.allowsOtherFileTypes = YES;

    NSInteger result = [panel runModal];
    if (result != NSModalResponseOK) return;

    NSURL *url = panel.URL;
    if (!url) return;

    NSString *path = [url path];
    NSTextField *pathField = [_configWindow.contentView viewWithTag:100];
    pathField.stringValue = path ?: @"";
}

- (IBAction)saveAndClose:(id)sender {
    NSTextField *pathField = [_configWindow.contentView viewWithTag:100];
    NSString *path = pathField.stringValue;

    if (path.length > 0) {
        [self setVideoPath:path];
    }

    NSWindow *parent = [((NSButton *)sender) window].sheetParent;
    if (parent) {
        [parent endSheet:((NSButton *)sender).window];
    }
}

- (IBAction)dismissSheet:(id)sender {
    NSWindow *parent = [((NSButton *)sender) window].sheetParent;
    if (parent) {
        [parent endSheet:((NSButton *)sender).window];
    }
}

@end
