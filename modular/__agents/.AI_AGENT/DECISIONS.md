# DECISIONS

## Active Decisions for PR #1277 Port

### D1: PR #1277 уже полностью портирован в BT
**Decision**: Все 9 файлов из diff уже содержат все изменения. Никаких implementation-правок не требуется.
**Result**: ALREADY PRESENT. ✅

### D2: Queen screech/ai уже присутствует
**Decision**: `/datum/action/xeno_action/onclick/screech/ai` уже определён в конце Queen.dm, используется в base_actions и mobile_aged_abilities. `/datum/action/xeno_action/activable/xeno_spit/queen_macro/ai` также присутствует.
**Result**: ALREADY PRESENT. ✅

### D3: Compile check
**Result**: Не требуется — 0 implementation-изменений.
