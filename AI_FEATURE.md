# Required local smart helper — Pokétran

## 1. User decision and purpose

**Decision:** Which Pokémon to work on next, whether to expand the roster, or whether duplicate primary types merit reconsideration. The helper reduces guesswork while leaving all changes to the user.

**Inputs:** Saved local Pokémon records belonging to the open team: primary type, level, training progress, role and roster count. No online data, personal profiles, API keys, or cloud inference. Input is user-entered and can be incomplete or inaccurate.

**Output:** A suggestion with a headline, next action, transparent rationale, and internal numerical priority. It is labeled as a rules-based suggestion, not a guaranteed tactical optimization.

## 2. Baseline and rule comparison

**Baseline:** Select the first Pokémon with the lowest recorded progress. On an empty roster, suggest recruitment. Implemented by `TeamAdvisor.baseline`.

**Enhanced method:** `TeamAdvisor.advise` computes rule candidates and sorts by priority. Examples:

| Rule | Condition | Example rationale |
|---|---|---|
| No-data | No members | Need at least one record before calculating team training |
| Completion | Every member at 100% | All saved members are ready to complete |
| Training | A member is below 50% | Its progress is lowest among members below halfway |
| Diversity | At least two members have the same *primary* type | Types repeat, which may limit variety |
| Open slot | Fewer than six members | There is capacity to add another member |
| Unspecified role | A role equals `Undecided` | Clarifying the role may improve planning |
| Closing gap | No member below 50%, not all 100% | There is unfinished training to complete |

The algorithm uses fixed rule scores, not trained weights or a statistical probability model. It does not know official battle matchups. Type overlap can be strategically useful; advice says *consider*, not *must change*.

## 3. Explicit user control

On the team detail screen, one suggestion shows its reason and next step. **Apply** records the choice and takes the trainer to the relevant normal editor or, if appropriate, the finish workflow. It never changes a Pokémon without an explicit save. **Not now** records a choice in SQLite (`coach_feedback`), hiding the tip across app restarts. **Reveal hidden tips** restores dismissed ideas. A saved roster edit clears dismissed tips so the next recommendation reflects current input. Turning the coach off in Settings stores the choice in SharedPreferences.

## 4. Five held-out synthetic evaluation cases

These cases are hand-authored examples for a reproducible deterministic test. They were not used to train a model; there is no trained model. `test/team_advisor_test.dart` expresses the expected outcomes. **Tests have not been executed in this delivery environment.**

| Case | Synthetic input | Baseline | Expected enhanced output | Assessment |
|---|---|---|---|---|
| 1. Empty | No members | Recruit first Pokémon | Explain lack of data, offer recruit action | Safe no-data behavior |
| 2. Ordinary | Pikachu 80%; Eevee 15% | Train Eevee | Rank Eevee with a clear progress rationale | Normal recommendation |
| 3. Type overlap | Charmander Fire 30%; Vulpix Fire 50% | Train Charmander | Also flag Fire repetition and a choice to diversify | Finds information baseline misses |
| 4. Completion | Squirtle Water 100% | Train Squirtle | Suggest completing an active team | Handles end state |
| 5. Counterexample avoidance | Pikachu Electric 40%; Squirtle Water 90% | Train Pikachu | **No** type-duplication claim | Avoids false overlap |

**Metric:** For each case, mark whether the expected behavior is observed (`pass`/`fail`); report actual test counts only after running `flutter test`. For case 3 the qualitative comparison criterion is presence of an appropriate type-overlap explanation absent from the baseline, not a claimed increase in win rate. Include an invalid/outlier roster case in manual testing (e.g., level 101 rejected by validation) and assess duplicate-type counterexamples with a real peer.

## 5. Why this is appropriate / limitations

Rules were selected because they are explainable, do not need network access or training data, and are stable enough to write tests for. The helper has no measured predictive accuracy, no performance guarantee, and no user-satisfaction data. It should not be described as ChatGPT, a trained model, or an official Pokémon strategy engine.

## 6. Implementation and demo path

- `lib/logic/team_advisor.dart`: baseline, rules, scores, and action types.
- `lib/pages/team_detail_page.dart`: reason card, Apply/Not now/Reveal controls.
- `lib/data/database_service.dart`: decision persistence and lifecycle transactions.
- `test/team_advisor_test.dart`: five labeled synthetic cases and additional regression examples.
- `test/database_test.dart`: feedback and persistence tests.

**Demo:** Create a sample Kanto team, open it, show baseline, show Fire-type overlap, dismiss, reopen the app to show persistent dismissal, reveal the tip, Apply the suggestion, and then compare again after a saved roster change. Record the actual results during testing.

## 7. Responsible development-assistance disclosure

Code and draft documentation were created with ChatGPT assistance; see `AI_Usage_Log.md`. No input records are transmitted to AI services when Pokétran runs.
