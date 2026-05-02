# BYOND/DM Runtime Safety Rules

## List mutation

Не удалять nested list / assoc-list candidate из outer-list через:

```dm
outer -= candidate
```

Если `candidate` сам является `list`, удалять через индекс:

```dm
var/remove_index = null

for(var/i in 1 to length(items))
	if(items[i] == candidate)
		remove_index = i
		break

if(!isnull(remove_index))
	items.Cut(remove_index, remove_index + 1)
```

Для best-candidate selection сразу хранить индекс:

```dm
var/best_index = null
var/list/best_candidate = null

for(var/i in 1 to length(candidates))
	var/list/candidate = candidates[i]
	if(should_select(candidate, best_candidate))
		best_candidate = candidate
		best_index = i

if(!isnull(best_index))
	result += list(best_candidate)
	candidates.Cut(best_index, best_index + 1)
```

## While loop invariant

Каждый `while` обязан иметь очевидный progress invariant:

- список уменьшается;
- индекс растет;
- счетчик достигает лимита;
- состояние переходит в terminal state.

Если `while(length(list))` использует удаление элемента, удаление должно быть проверяемым и deterministic.

Для runtime-heavy кода желательно добавлять debug/test safety guard:

```dm
var/safety_iterations = 0
var/max_iterations = length(items) + 4

while(length(items))
	safety_iterations++
	if(safety_iterations > max_iterations)
		CRASH("Loop failed to consume items.")
```

В production runtime вместо `CRASH` использовать controlled error plan / warning, если это пользовательский инструмент.

## Planner / preview / apply

Для planner-кода нельзя делать unbounded алгоритмы:

- `area * footprint` без бюджета;
- полный rebuild на hover;
- повторный full-plan build на confirm/apply;
- preview object specs без лимита;
- endpoint clamp с множеством full-plan attempts.

Для preview/apply pipeline нужно разделять:

- cheap hover preview;
- click validation;
- real plan build;
- apply already-built plan.

## Tests

Для исправления runtime runaway добавлять focused tests:

- цикл потребляет candidates;
- результат не содержит повтор одного nested candidate;
- over-budget input завершается controlled error;
- unsupported input fail-fast;
- apply не пересобирает heavy plan, если должен reuse existing plan.
