// Optional command-line trigger for the READ-ONLY Native12 UI inspector.
// This does not load any tweak, start any window, or interact with vendor code.
// Only meaningful on a separate test device after the inspector is installed.
#include <notify.h>
#include <stdio.h>
int main(void) {
    const char *name="com.duoface.native12.reference.capture";
    uint32_t status=notify_post(name);
    if(status!=NOTIFY_STATUS_OK) {
        fprintf(stderr,"Native12 reference capture notify_post error=%u\n",status);
        return 1;
    }
    puts("Native12 reference capture requested; inspect local log directory.");
    return 0;
}
