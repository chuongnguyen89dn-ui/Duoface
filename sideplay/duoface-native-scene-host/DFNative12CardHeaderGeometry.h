#ifndef DF_NATIVE12_CARD_HEADER_GEOMETRY_H
#define DF_NATIVE12_CARD_HEADER_GEOMETRY_H
#include <math.h>

/* Original SHA256 Dashboard 9e02a4bc... setupCardContent @0xa2a58.
 * Immutable evidence: audit/native12-continuation-96fa4ec/
 * 02_ORIGINAL_SETUP_CARD_CONTENT.txt, CARD_HEADER_LITERALS.json,
 * 03_ORIGINAL_HEADER_TABS_AUDIT.md. Three INNER tabs are not the four
 * OUTER Native12 toolbar actions. No third-party runtime code is used. */
typedef struct {
    double x,y,width,height;
} DFNative12CardRect;
typedef struct {
    double headerHeight,contentY;
    double tabZoneWidth,tabChildWidth;
    DFNative12CardRect icon,title,tabs,dismiss;
    DFNative12CardRect tabButtons[3];
} DFNative12CardHeader;
static inline DFNative12CardHeader DFOriginalCardHeader(double w,double h) {
    DFNative12CardHeader m={0};
    if(!isfinite(w)||!isfinite(h)||w<=0||h<=0)return m;
    const int compactH=(h<260.0);
    const double headerH=compactH?32.0:38.0;
    const double zone=(w<440.0)?190.0:210.0;
    const double tabHeight=compactH?24.0:28.0;
    const double tabW=floorf((float)((zone-4.0)/3.0));
    const double closeSize=compactH?24.0:26.0;
    m.headerHeight=headerH;
    m.contentY=headerH+0.5; // 0xa3dd8 -> setupPresetCards contentY
    m.tabZoneWidth=zone;
    m.tabChildWidth=tabW;
    m.icon=(DFNative12CardRect){14.0,(headerH-18.0)/2.0,18.0,18.0};
    m.title=(DFNative12CardRect){36.0,(headerH-20.0)/2.0,
        fmax(w-zone-74.0,80.0),20.0};
    m.tabs=(DFNative12CardRect){w-36.0-zone,compactH?4.0:5.0,zone,tabHeight};
    m.dismiss=(DFNative12CardRect){w-closeSize-8.0,
        compactH?4.0:6.0,closeSize,closeSize};
    m.tabButtons[0]=(DFNative12CardRect){1.0,1.0,tabW,tabHeight-2.0};
    m.tabButtons[1]=(DFNative12CardRect){1.0+tabW,1.0,tabW,tabHeight-2.0};
    m.tabButtons[2]=(DFNative12CardRect){1.0+2.0*tabW,1.0,
        zone-2.0*tabW-3.0,tabHeight-2.0};
    return m;
}
#endif
