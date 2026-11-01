// Real mailbox algorithm, deterministic notify backend; not iOS runtime evidence.
#include <assert.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#define DF156_NOTIFY_TEST 1
#define NOTIFY_STATUS_OK 0
static uint64_t slots[600];
static char names[600][224];
static int used,fail_set=-1,fail_get=-1,race_after=-1,reads,commit_token;
static uint32_t notify_register_check(const char *name,int *token) {
 for(int i=0;i<used;i++)if(!strcmp(names[i],name)){*token=i;return 0;}
 assert(used<600);*token=used;snprintf(names[used++],224,"%s",name);return 0;
}
static uint32_t notify_set_state(int token,uint64_t state) {
 if(token==fail_set)return 1;
 slots[token]=state;return 0;
}
static uint32_t notify_get_state(int token,uint64_t *state) {
 if(token==fail_get)return 1;
 if(++reads==race_after)slots[commit_token]++;
 *state=slots[token];return 0;
}
static uint32_t notify_post(const char *name){(void)name;return 0;}
#include "../DF156DarwinMailbox.h"
int main(void) {
 DF156Mailbox writer,reader;DF156Init(&writer,"test.state.app");DF156Init(&reader,"test.state.app");
 uint8_t input[DF156_MAX_BYTES],out[DF156_MAX_BYTES];
 for(size_t i=0;i<sizeof(input);i++)input[i]=(uint8_t)(i*17);
 assert(!DF156Read(&reader,out));
 for(size_t len=1;len<=sizeof(input);len++) {
  assert(DF156Write(&writer,input,len,len));
  assert(DF156Read(&reader,out)==len && !memcmp(input,out,len));
 }
 assert(!DF156Write(&writer,input,0,1));
 assert(!DF156Write(&writer,input,DF156_MAX_BYTES+1,1));
 assert(!DF156Write(&writer,input,5,0));
 slots[writer.words[1]]^=1;assert(!DF156Read(&reader,out)); // corrupt chunk
 assert(DF156Write(&writer,input,31,77));
 commit_token=writer.commit;reads=0;race_after=4;
 assert(!DF156Read(&reader,out));race_after=-1; // overwrite during snapshot
 fail_set=writer.words[1];assert(!DF156Write(&writer,input,31,78));
 assert(!DF156Read(&reader,out));fail_set=-1; // incomplete publish invalidates commit
 assert(DF156Write(&writer,input,31,79));
 fail_get=reader.words[1];assert(!DF156Read(&reader,out));fail_get=-1;
 DF156Mailbox other;DF156Init(&other,"test.state.other");assert(!DF156Read(&other,out));
 assert(DF156Read(&reader,out)==31); // other bundle isolated
 assert((unsigned)used<=2*(DF156_WORDS+2));
 puts("DF156_MAILBOX_BOUNDARIES_CORRUPTION_RACE_FAILURE_ISOLATION_PASS");
}
