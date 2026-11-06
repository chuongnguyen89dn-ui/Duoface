#ifndef DF182_BLOCK_COMPLETION_ABI_H
#define DF182_BLOCK_COMPLETION_ABI_H
#import <Foundation/Foundation.h>
#import <string.h>
// Clang Apple Block ABI: https://clang.llvm.org/docs/Block-ABI-Apple.html
// Verify the block's OWN void(void) signature, not merely the method's @? argument.
static BOOL DF182VoidCompletion(id block) {
 if(!block)return YES;
 struct Literal {void *isa;int flags;int reserved;void *invoke;const void *descriptor;};
 const struct Literal *b=(__bridge const struct Literal *)block;
 if(!(b->flags&(1<<30)) || !b->descriptor)return NO;
 const char *cursor=(const char *)b->descriptor+2*sizeof(unsigned long);
 if(b->flags&(1<<25))cursor+=2*sizeof(void *);
 const char *signature=*(const char *const *)cursor;
 if(!signature)return NO;
 NSMethodSignature *s=[NSMethodSignature signatureWithObjCTypes:signature];
 return s.numberOfArguments==1 && !strcmp(s.methodReturnType,@encode(void)) &&
        !strcmp([s getArgumentTypeAtIndex:0],"@?");
}
#endif
