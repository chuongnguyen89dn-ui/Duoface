"""Guard actual sender integration; contact behavior runs in production header model."""
import pathlib,sys
text=pathlib.Path(sys.argv[1]).read_text()
hook=text.split('static void DF177SendEventHook(',1)[1].split('// Installs the sendEvent:',1)[0]
assert 'DF176ConsumeWakeEvent(event,DF177TouchBundle)' in hook, 'QA175_GATE_MISSING_FROM_APP_DELIVERY'
assert hook.index('DF176ConsumeWakeEvent(')<hook.index('DF177SendEventOriginal)('), 'QA175_GATE_AFTER_CHILD_DELIVERY'
assert 'if(DF176ConsumeWakeEvent(event,DF177TouchBundle))return;' in hook
print('QA176_APP_SENDER_INTEGRATION_PASS')
