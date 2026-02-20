# IRONCORE ARENA - MVP TEST CHECKLIST
## Quick Validation Before Adding More Content

---

## PRE-TEST SETUP

1. Open Godot 4.6
2. Open `ironcore-work/project/project.godot`
3. Press F5 to run

---

## TEST 1: MAIN MENU

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 1.1 | Game starts | See main menu with title | [ ] |
| 1.2 | Click "New Campaign" | Goes to builder screen | [ ] |
| 1.3 | Press ESC | Returns to main menu | [ ] |
| 1.4 | Click "Component Shop" | Opens shop screen | [ ] |
| 1.5 | Press ESC | Returns to main menu | [ ] |
| 1.6 | Click "Quit" | Game closes | [ ] |

**Issues:** _________________________________

---

## TEST 2: BUILDER SCREEN

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 2.1 | In builder | See 3 panels (Shop/Inventory/My Bots) | [ ] |
| 2.2 | Click "Chassis" button | Shop list shows chassis | [ ] |
| 2.3 | Click "Armor" button | Shop list shows armor | [ ] |
| 2.4 | Click "Weapon/Heal" button | Shop list shows weapons | [ ] |
| 2.5 | Check bottom bar | Shows "Weight: X / Y kg" and "Credits: 500" | [ ] |
| 2.6 | Click "Test Battle" | Goes to battle screen | [ ] |

**Issues:** _________________________________

---

## TEST 3: BATTLE SCREEN

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 3.1 | Battle starts | See countdown (3, 2, 1) | [ ] |
| 3.2 | After countdown | Bots spawn and move | [ ] |
| 3.3 | Watch combat | Bots shoot projectiles | [ ] |
| 3.4 | Check HUD | Shows "Enemies: X/Y" updating | [ ] |
| 3.5 | Wait for end | One team wins | [ ] |
| 3.6 | Results show | Victory/Defeat + Grade + Credits | [ ] |

**Issues:** _________________________________

---

## TEST 4: RESULTS & REWARDS

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 4.1 | See results | Grade displayed (S/A/B/C/D/F) | [ ] |
| 4.2 | See credits | "Credits Earned" shows number | [ ] |
| 4.3 | Click "Continue" | Returns to builder or next arena | [ ] |
| 4.4 | Check credits | Bottom bar shows increased credits | [ ] |

**Issues:** _________________________________

---

## TEST 5: SAVE / LOAD (CRITICAL)

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 5.1 | Complete one battle | Win or lose | [ ] |
| 5.2 | Return to main menu | Auto-save triggered | [ ] |
| 5.3 | Note credit amount | Remember the number | [ ] |
| 5.4 | Close game | Window closes | [ ] |
| 5.5 | Reopen game | Run project again | [ ] |
| 5.6 | Click "Continue" | Loads save | [ ] |
| 5.7 | Check credits | Same amount as before | [ ] |
| 5.8 | Check completed arenas | Previous arena marked complete | [ ] |

**Issues:** _________________________________

---

## TEST 6: SHOP SYSTEM

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 6.1 | From main menu | Click "Component Shop" | [ ] |
| 6.2 | See shop items | Items with prices listed | [ ] |
| 6.3 | Try to buy | If enough credits, purchase succeeds | [ ] |
| 6.4 | Check inventory | New item appears in inventory | [ ] |
| 6.5 | Check credits | Credits deducted | [ ] |
| 6.6 | Leave shop | Press ESC, returns to menu | [ ] |

**Issues:** _________________________________

---

## TEST 7: DEBUG FEATURES

| Step | Action | Expected | Pass? |
|------|--------|----------|-------|
| 7.1 | Press F5 | "Quick save triggered" in console | [ ] |
| 7.2 | Press F9 | "Quick load triggered" in console | [ ] |
| 7.3 | Press ESC in battle | Returns to previous screen | [ ] |

**Issues:** _________________________________

---

## OVERALL ASSESSMENT

| Category | Status |
|----------|--------|
| Core Loop (Menu→Builder→Battle→Results) | ☐ Working ☐ Broken |
| Combat System | ☐ Working ☐ Broken |
| Save/Load System | ☐ Working ☐ Broken |
| Shop/Economy | ☐ Working ☐ Broken |
| UI Navigation | ☐ Working ☐ Broken |

---

## BLOCKERS (If Any)

List anything that prevents completing a test:

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

## DECISION

After testing, choose one:

- [ ] **ALL GOOD** — Add second arena
- [ ] **MINOR BUGS** — Fix issues, then add content
- [ ] **MAJOR ISSUES** — Stop, debug, fix before continuing

---

## NOTES

Use this space for any observations:

_______________________________________________

_______________________________________________

_______________________________________________

---

**Tested by:** _______________  
**Date:** _______________  
**Time spent:** _______________  
**Overall feel:** ☐ Fun ☐ Okay ☐ Frustrating
