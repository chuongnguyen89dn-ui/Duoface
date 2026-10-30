"""Static integration gates; not an iOS/Play simulation."""
from pathlib import Path
import unittest

CODE = (Path(__file__).resolve().parents[1] / 'DFSceneLifecycle.m').read_text()

class PostLockContract(unittest.TestCase):
    def test_os_callback_exactly_once_before_owned_mutation(self):
        block = CODE.split('static void DFPostLockIntercept(',1)[1].split('static void DFInstallPostLockIntercept',1)[0]
        call = 'sOriginalPostLockIntercept(manager,cmd,scene,settings);'
        self.assertEqual(block.count(call),1)
        self.assertLess(block.index(call),block.index('DFIsOwnedHostedLockScene123(scene)'))
        self.assertLess(block.index(call),block.index('@try'))
        self.assertLess(block.index('DFIsOwnedHostedLockScene123(scene)'),block.index('DFPostLockSetBool('))
        for forbidden in ('setFrame:', 'setDeactivationReasons:', 'object_setIvar', 'updateSettings:', 'sendEvent:'):
            self.assertNotIn(forbidden,block)

    def test_void_two_object_abi_not_predicate_or_missing_method(self):
        block = CODE.split('static void DFInstallPostLockIntercept(',1)[1].split('static void DFInstallOwnedUnderLock123',1)[0]
        self.assertIn('method_getNumberOfArguments(method)!=4',block)
        self.assertIn('strcmp(type,"v")',block)
        self.assertIn("type[0]!='@'",block)
        self.assertNotIn('shouldBeUnderLockForScene:',block)

    def test_typed_bool_readback_and_no_raw_writes(self):
        block = CODE.split('static BOOL DFPostLockSetBool(',1)[1].split('static void DFPostLockIntercept',1)[0]
        self.assertIn('DFPostLockBoolABI([settings methodSignatureForSelector:read],NO)',block)
        self.assertIn('DFPostLockBoolABI([settings methodSignatureForSelector:write],YES)',block)
        self.assertIn('objc_msgSend)(settings,read)==value',block)
        self.assertNotIn('ivar',block)

if __name__ == '__main__': unittest.main()
