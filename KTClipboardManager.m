#import "KTClipboardManager.h"
#import "KTSettings.h"
#include <sys/file.h>
#include <fcntl.h>
#include <unistd.h>

static NSString * const KTStoreKey = @"/var/mobile/Library/Preferences/com.keyboardtoolskayoko.history.plist";
static NSString * const KTChangeKey = @"/var/mobile/Library/Preferences/com.keyboardtoolskayoko.lastchange.plist";

@implementation KTClipboardItem
- (NSDictionary *)dictionary {
    return @{
        @"text": self.text ?: @"",
        @"bundle": self.bundleIdentifier ?: @"",
        @"app": self.appName ?: @"",
        @"timestamp": @((self.recordedAt ?: NSDate.date).timeIntervalSince1970),
        @"favorite": @(self.favorite)
    };
}
+ (instancetype)itemWithDictionary:(NSDictionary *)d {
    KTClipboardItem *i = [KTClipboardItem new];
    i.text = [d[@"text"] isKindOfClass:NSString.class] ? d[@"text"] : @"";
    i.bundleIdentifier = [d[@"bundle"] isKindOfClass:NSString.class] ? d[@"bundle"] : @"";
    i.appName = [d[@"app"] isKindOfClass:NSString.class] ? d[@"app"] : @"";
    NSNumber *ts = [d[@"timestamp"] isKindOfClass:NSNumber.class] ? d[@"timestamp"] : nil;
    i.recordedAt = ts ? [NSDate dateWithTimeIntervalSince1970:ts.doubleValue] : NSDate.date;
    i.favorite = [d[@"favorite"] boolValue];
    return i;
}
@end

@interface KTClipboardManager ()
@property(nonatomic,strong) NSMutableArray<KTClipboardItem *> *mutableItems;
@end

@implementation KTClipboardManager
+ (instancetype)sharedManager {
    static KTClipboardManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [self new]; });
    return m;
}

- (instancetype)init {
    if ((self = [super init])) {
        _mutableItems = [NSMutableArray array];
        [self reloadFromDisk];
    }
    return self;
}

- (int)lockFile {
    int fd = open("/var/mobile/Library/Preferences/com.keyboardtoolskayoko.history.lock", O_CREAT | O_RDWR, 0644);
    if (fd >= 0) flock(fd, LOCK_EX);
    return fd;
}

- (void)unlockFile:(int)fd {
    if (fd < 0) return;
    flock(fd, LOCK_UN);
    close(fd);
}

- (void)reloadFromDisk {
    int fd = [self lockFile];
    NSArray *saved = [NSArray arrayWithContentsOfFile:KTStoreKey];
    [_mutableItems removeAllObjects];
    for (NSDictionary *d in saved) {
        if ([d isKindOfClass:NSDictionary.class]) [_mutableItems addObject:[KTClipboardItem itemWithDictionary:d]];
    }
    [self unlockFile:fd];
}

- (void)saveLocked {
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:self.mutableItems.count];
    for (KTClipboardItem *i in self.mutableItems) [a addObject:i.dictionary];
    [a writeToFile:KTStoreKey atomically:YES];
}

- (void)startMonitoring {
    if (!KTEnabled() || !KTRecordClipboard()) return;
}

- (void)pasteboardChanged:(NSNotification *)note {
    [self addCurrentClipboard];
}

- (void)addCurrentClipboard {
    if (!KTEnabled() || !KTRecordClipboard()) return;
    UIPasteboard *pb = UIPasteboard.generalPasteboard;
    NSString *text = pb.string;
    if (!text.length) return;
    NSString *bid = NSBundle.mainBundle.bundleIdentifier ?: @"";
    NSString *name = NSBundle.mainBundle.localizedInfoDictionary[@"CFBundleDisplayName"] ?: NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"] ?: NSBundle.mainBundle.infoDictionary[@"CFBundleName"] ?: bid;
    [self addCapturedText:text bundleIdentifier:bid appName:name recordedAt:NSDate.date];
}

- (void)addCapturedText:(NSString *)text bundleIdentifier:(NSString *)bid appName:(NSString *)name recordedAt:(NSDate *)recordedAt {
    if (!KTEnabled() || !KTRecordClipboard() || !text.length) return;

    int fd = [self lockFile];
    NSArray *saved = [NSArray arrayWithContentsOfFile:KTStoreKey];
    NSMutableArray<KTClipboardItem *> *items = [NSMutableArray array];
    for (NSDictionary *d in saved) if ([d isKindOfClass:NSDictionary.class]) [items addObject:[KTClipboardItem itemWithDictionary:d]];

    KTClipboardItem *latest = items.firstObject;
    if (latest && [latest.text isEqualToString:text] && [latest.bundleIdentifier isEqualToString:(bid ?: @"")]) {
        [self.mutableItems removeAllObjects];
        [self.mutableItems addObjectsFromArray:items];
        [self unlockFile:fd];
        return;
    }

    KTClipboardItem *i = [KTClipboardItem new];
    i.text = text;
    i.bundleIdentifier = bid ?: @"";
    i.appName = name ?: @"";
    i.recordedAt = recordedAt ?: NSDate.date;
    i.favorite = NO;
    [items insertObject:i atIndex:0];

    NSUInteger limit = KTHistoryLimit();
    while (items.count > limit) {
        NSUInteger removeIndex = NSNotFound;
        for (NSInteger n = (NSInteger)items.count - 1; n >= 0; n--) {
            if (!items[(NSUInteger)n].favorite) { removeIndex = (NSUInteger)n; break; }
        }
        if (removeIndex == NSNotFound) break;
        [items removeObjectAtIndex:removeIndex];
    }

    NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:items.count];
    for (KTClipboardItem *item in items) [dicts addObject:item.dictionary];
    [dicts writeToFile:KTStoreKey atomically:YES];
    [self.mutableItems removeAllObjects];
    [self.mutableItems addObjectsFromArray:items];
    [self unlockFile:fd];
}

- (void)addText:(NSString *)text bundleIdentifier:(NSString *)bid appName:(NSString *)name {
    [self addCapturedText:text bundleIdentifier:bid appName:name recordedAt:NSDate.date];
}

- (NSArray *)items {
    [self reloadFromDisk];
    return [self.mutableItems copy];
}

- (NSArray *)favorites {
    [self reloadFromDisk];
    NSMutableArray *a = [NSMutableArray array];
    for (KTClipboardItem *i in self.mutableItems) if (i.favorite) [a addObject:i];
    return a;
}

- (void)setFavorite:(BOOL)favorite forItem:(KTClipboardItem *)item {
    if (!item) return;
    int fd = [self lockFile];
    NSArray *saved = [NSArray arrayWithContentsOfFile:KTStoreKey];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *d in saved) if ([d isKindOfClass:NSDictionary.class]) [items addObject:[KTClipboardItem itemWithDictionary:d]];
    for (KTClipboardItem *x in items) {
        if ([x.text isEqualToString:item.text] && [x.recordedAt isEqualToDate:item.recordedAt]) x.favorite = favorite;
    }
    NSMutableArray *dicts = [NSMutableArray array];
    for (KTClipboardItem *x in items) [dicts addObject:x.dictionary];
    [dicts writeToFile:KTStoreKey atomically:YES];
    [self.mutableItems removeAllObjects];
    [self.mutableItems addObjectsFromArray:items];
    [self unlockFile:fd];
}

- (void)removeItem:(KTClipboardItem *)item {
    if (!item) return;
    int fd = [self lockFile];
    NSArray *saved = [NSArray arrayWithContentsOfFile:KTStoreKey];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *d in saved) if ([d isKindOfClass:NSDictionary.class]) [items addObject:[KTClipboardItem itemWithDictionary:d]];
    for (NSInteger n = (NSInteger)items.count - 1; n >= 0; n--) {
        KTClipboardItem *x = items[(NSUInteger)n];
        if ([x.text isEqualToString:item.text] && [x.recordedAt isEqualToDate:item.recordedAt]) [items removeObjectAtIndex:(NSUInteger)n];
    }
    NSMutableArray *dicts = [NSMutableArray array];
    for (KTClipboardItem *x in items) [dicts addObject:x.dictionary];
    [dicts writeToFile:KTStoreKey atomically:YES];
    [self.mutableItems removeAllObjects];
    [self.mutableItems addObjectsFromArray:items];
    [self unlockFile:fd];
}

- (void)clearClipboardHistory {
    int fd = [self lockFile];
    NSArray *saved = [NSArray arrayWithContentsOfFile:KTStoreKey];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *d in saved) {
        KTClipboardItem *i = [KTClipboardItem itemWithDictionary:d];
        if (i.favorite) [items addObject:i];
    }
    NSMutableArray *dicts = [NSMutableArray array];
    for (KTClipboardItem *i in items) [dicts addObject:i.dictionary];
    [dicts writeToFile:KTStoreKey atomically:YES];
    [self.mutableItems removeAllObjects];
    [self.mutableItems addObjectsFromArray:items];
    [self unlockFile:fd];
}

- (void)clearImages {
    UIPasteboard *pb = UIPasteboard.generalPasteboard;
    if (pb.hasImages) pb.items = @[];
}

- (void)pasteItem:(KTClipboardItem *)item intoInput:(id<UITextInput>)input {
    if (!item.text.length || !input) return;
    UITextRange *r = input.selectedTextRange;
    if (r) [input replaceRange:r withText:item.text];
}
@end
