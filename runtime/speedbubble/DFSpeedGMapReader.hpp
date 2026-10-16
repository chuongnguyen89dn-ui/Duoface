#pragma once
// Read-only, byte-verified adapter for GMapHUD v0.2.3 per-source wire format.
// This is ONLY data; GMapHUD's CarPlay renderer is explicitly excluded.
#include "DFSpeedProtocol.hpp"
namespace DFSpeed {
bool ReadPinnedGMapWire(Sample &sample);
// GMapHUD v0.2.3 publishers require an explicitly selected source.
// Only choose a source present in the DuoFace-owned active app set.
bool RequestPinnedGMapSource(Source source);
}
