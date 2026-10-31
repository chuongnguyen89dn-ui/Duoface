// First-party native preparation continuation: one result per owner generation.
// Pure C for Linux/macOS runtime tests. No vendor code or license.
#ifndef DF_NATIVE_PREP_ONCE_152_H
#define DF_NATIVE_PREP_ONCE_152_H
#include <stdint.h>
#include <stdbool.h>
typedef struct {
 uint64_t generation;
 bool pending;
 bool resumed;
} DF152Preparation;
static inline uint64_t DF152Begin(DF152Preparation *p) {
 ++p->generation; p->pending=true; p->resumed=false;
 return p->generation;
}
static inline bool DF152FinishOnce(DF152Preparation *p,uint64_t gen) {
 if(!p || !p->pending || p->resumed || p->generation!=gen)return false;
 p->resumed=true; p->pending=false;
 return true;
}
static inline void DF152Revoke(DF152Preparation *p) {
 if(!p)return;
 ++p->generation; p->pending=false;p->resumed=false;
}
#endif
