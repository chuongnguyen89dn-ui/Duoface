# 2026-10-31 QA146 public Sileo live verified; physical Home exit STILL pending

- QA145 real Log22 physical bug: selected Facebook/YouTube apps open from CarPlay Home but native Home cannot release independent scene; Home visibility hook was not installed, native statusbar Home receiver is available, old owner check depended on DuoFace CPTemplate. Forensics run 41184755646 SUCCESS, report sideplay/audit/qa145-log22-home-exit-20261031/QA145_LOG22_NATIVE_HOME_EXIT_ROOT_CAUSE.md.
- QA146 canonical standalone-Home exit repair signed in project branch feature/duoface-qa146-native-home-exit-20261031: source 1159f7119d515a5eefe0959ce9aa6701d92a62bb, build 41185002153 SUCCESS, archive sideplay/jb-embedded-appbridge/evidence/runs/41185002153/, package SHA256 1785d5d6bef53337033f5664d5acfc573dabe20892bd629649fab5730b04e078.
- Public Sileo publisher carplaydsp commit 416679c1b518f56d59a9ac557f315911f880dba0, run 41185275192: build, deploy, integrated Pages SHA, all other verification SUCCESS. YAML 41185275135 SUCCESS. Independent this-checkpoint workflow additionally fetched current public Packages, validated exactly one current integrated DuoFace version 0.0.146~native-home-release1 and downloaded exact DEB with matching SHA256.
- Different branch feature/duoface-qa144-standalone-carplay-home-20261031 received later experimental source commits 44d8ed5, cadf26c, 593f830 (extra external-screen/consent guard, source static test). Its separate static CI 41185438031 SUCCESS; none of those extra commits is included in immutable canonical signed QA146 source 1159f711. Do not present or merge as shipped.
- Physical QA146 Home/Back/app switching not yet tested. Next: refresh Sileo QA146 once with car parked, press native Home, choose another app; export Log23, verify real qa146-native-home-standalone-stop-notified and stopped native-Home-exit evidence. Direct Dock switch, GOFA and YouTube touch still unverified.

---

