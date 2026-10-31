#ifndef DF_DOCK_LIFECYCLE_147_H
#define DF_DOCK_LIFECYCLE_147_H
#include <stdbool.h>
#include <stdint.h>
typedef enum { DF147Ignore, DF147Activate, DF147Restore } DF147Action;
typedef struct { uint64_t generation; bool pending,active; } DF147Lifecycle;
static inline void DF147BeginGeneration(DF147Lifecycle *s) {
 ++s->generation;s->pending=true;s->active=false;
}
static inline DF147Action DF147ResultAction(DF147Lifecycle *s,bool identity,bool fresh,
                                          bool hosted,bool terminal,bool validPID) {
 if(!identity || !fresh || (!s->pending&&!s->active))return DF147Ignore;
 if(terminal){bool was=s->active;s->pending=false;s->active=false;return was?DF147Restore:DF147Ignore;}
 if(hosted && validPID && s->pending){s->pending=false;s->active=true;return DF147Activate;}
 return DF147Ignore;
}
static inline DF147Action DF147RevokeGeneration(DF147Lifecycle *s) {
 bool was=s->active;++s->generation;s->pending=false;s->active=false;
 return was?DF147Restore:DF147Ignore;
}
#endif
