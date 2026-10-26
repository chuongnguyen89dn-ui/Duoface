#ifndef DF_APP_VIEWPORT_PROTOCOL_H
#define DF_APP_VIEWPORT_PROTOCOL_H
#include <stdint.h>
// Readback-gated, nonpersistent Darwin notification: [marker:8][active:1]
// [width:12][height:12][unix-seconds modulo 2^31:31]. No user credentials.
#define DFVP_MARKER 0xD2ULL
#define DFVP_TIME_MASK 0x7fffffffULL
static inline uint64_t DFVPPack(unsigned width,unsigned height,uint32_t now,int active) {
    if(!active){width=0;height=0;}
    if(width>4095 || height>4095)return 0;
    return (DFVP_MARKER<<56) | ((uint64_t)(active?1:0)<<55) |
           ((uint64_t)width<<43) | ((uint64_t)height<<31) |
           ((uint64_t)now&DFVP_TIME_MASK);
}
static inline int DFVPUnpack(uint64_t value,uint32_t now,
                            unsigned *width,unsigned *height,int *active) {
    if((value>>56)!=DFVP_MARKER)return 0;
    unsigned w=(unsigned)((value>>43)&4095);
    unsigned h=(unsigned)((value>>31)&4095);
    int a=((value>>55)&1)!=0;
    uint32_t stamp=(uint32_t)(value&DFVP_TIME_MASK);
    uint32_t age=(uint32_t)(((uint64_t)now-stamp)&DFVP_TIME_MASK);
    if(age>3 || (a && (w<100 || h<100)))return 0;
    if(width)*width=w;
    if(height)*height=h;
    if(active)*active=a;
    return 1;
}
#endif
