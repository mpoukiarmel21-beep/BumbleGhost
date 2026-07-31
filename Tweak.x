#import <Foundation/Foundation.h>

__attribute__((constructor))
static void init(void) {
    NSLog(@"[BumbleGhost] MINIMAL TEST - dylib loaded successfully!");
}