// First-party bounded latest-value mailbox over Darwin notify state.
// One writer per (bundle,direction); notify is a wakeup, not the payload.
// This provides consistency, NOT sender authentication or a command queue.
#ifndef DF156_DARWIN_MAILBOX_H
#define DF156_DARWIN_MAILBOX_H
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#ifndef DF156_NOTIFY_TEST
#include <notify.h>
#endif
#define DF156_MAX_BYTES 2048u
#define DF156_WORDS (DF156_MAX_BYTES/8u)
typedef struct {
 char name[192];
 int commit, header, words[DF156_WORDS];
} DF156Mailbox;
static inline void DF156Init(DF156Mailbox *m,const char *name) {
 memset(m,0,sizeof(*m));
 snprintf(m->name,sizeof(m->name),"%s",name);
 m->commit=m->header=-1;
 for(size_t i=0;i<DF156_WORDS;i++)m->words[i]=-1;
}
static inline uint32_t DF156CRC(const uint8_t *data,size_t size) {
 uint32_t crc=UINT32_MAX;
 for(size_t i=0;i<size;i++) {
  crc^=data[i];
  for(unsigned bit=0;bit<8;bit++)crc=(crc>>1)^(0xedb88320u & (0u-(crc&1u)));
 }
 return ~crc;
}
static inline int DF156Token(DF156Mailbox *m,int slot) {
 int *token=slot==-2?&m->commit:slot==-1?&m->header:&m->words[slot];
 if(*token>=0)return *token;
 char key[224];
 snprintf(key,sizeof(key),"%s.%d",m->name,slot);
 int candidate=-1;
 if(notify_register_check(key,&candidate)!=NOTIFY_STATUS_OK)return -1;
 *token=candidate;return candidate;
}
static inline int DF156Set(DF156Mailbox *m,int slot,uint64_t value) {
 int token=DF156Token(m,slot);
 return token>=0 && notify_set_state(token,value)==NOTIFY_STATUS_OK;
}
static inline int DF156Get(DF156Mailbox *m,int slot,uint64_t *value) {
 int token=DF156Token(m,slot);
 return token>=0 && notify_get_state(token,value)==NOTIFY_STATUS_OK;
}
static inline int DF156Write(DF156Mailbox *m,const uint8_t *data,size_t size,uint64_t generation) {
 if(!data || !size || size>DF156_MAX_BYTES || !generation)return 0;
 // Invalidate BEFORE changing any slot. Failure leaves no committed packet.
 if(!DF156Set(m,-2,0))return 0;
 uint64_t header=((uint64_t)DF156CRC(data,size)<<32)|(uint32_t)size;
 if(!DF156Set(m,-1,header))return 0;
 for(size_t offset=0;offset<size;offset+=8) {
  uint64_t word=0;
  for(size_t j=0;j<8 && offset+j<size;j++)word|=(uint64_t)data[offset+j]<<(8*j);
  if(!DF156Set(m,(int)(offset/8),word))return 0;
 }
 if(!DF156Set(m,-2,generation))return 0;
 return notify_post(m->name)==NOTIFY_STATUS_OK;
}
static inline size_t DF156Read(DF156Mailbox *m,uint8_t out[DF156_MAX_BYTES]) {
 uint64_t before=0,after=0,header=0;
 if(!DF156Get(m,-2,&before) || !before || !DF156Get(m,-1,&header))return 0;
 size_t size=(uint32_t)header;
 if(!size || size>DF156_MAX_BYTES)return 0;
 for(size_t offset=0;offset<size;offset+=8) {
  uint64_t word=0;
  if(!DF156Get(m,(int)(offset/8),&word))return 0;
  for(size_t j=0;j<8 && offset+j<size;j++)out[offset+j]=(uint8_t)(word>>(8*j));
 }
 if(!DF156Get(m,-2,&after) || before!=after ||
    DF156CRC(out,size)!=(uint32_t)(header>>32))return 0;
 return size;
}
#endif
