# PACE design spec (text copy of Allen's Figma exports)

This file replaces the PDFs as the design reference inside the repo. It was written from the three exports (foundations, components and rest-timer states, 39 screens) with the photos left out. Pixel sizes were measured from 2x exports of 390 x 844 frames, so treat them as plus or minus 2 px. Items marked **(confirm)** are inferred and should be checked with Allen.

Frame: 390 x 844, dark theme, Inter font. Status bar shows "9:41".

## 1. Foundations

| Token | Value |
|---|---|
| bg/base | `#0B0B0D` (screens appear pure black `#000` behind content: **confirm**) |
| bg/card | `#18181B` |
| action/primary | `#E32636` |
| action/primary-pressed | `#B91C2C` |
| text/primary | `#FFFFFF` |
| text/secondary | `#A1A1AA` |
| border/default | `#303036` (rendered lighter, about `#55555C`, on inputs and outlined buttons: **confirm**) |
| status/success | `#22C55E` |
| error text and border | light red/pink, about `#FF8A8A` (**confirm**) |
| active tab icon | same pink (**confirm**) |

Type (Inter): Display 28/32 bold, Title 20/24 semibold, Body 16/24 regular, Caption 13/16 (uppercase for labels such as "STRENGTH · INTERMEDIATE · 6 WEEKS" and section labels).
Spacing scale 8 / 16 / 24 / 32 / 40 / 48, plus 12. Screen side margin 24. Corner radius 12 (cards, inputs, buttons, chips, set chips). Minimum tap 44, workout actions 56. Primary button and inputs are about 56 high.
Rules: red means action; green confirms a logged set; always use a label next to color; never put small text directly over a busy photo.

Photography (three pictures in the foundations sheet, now included from the original exports with the user's clearance):
1. Training / plan previews: woman in a dark gym holding dumbbells, black background.
2. Community / welcome: man and woman back to back holding dumbbells, cut out on dark.
3. Completion / positive reinforcement: man and woman high-fiving, cut out on dark.
Other photos: Welcome and auth screens use dark gym photos (bowed head, push-up position) as a faded hero behind the wordmark; Home uses grayscale dumbbell crops on cards; avatars are portrait photos.

## 2. Components and states

- **Button** (4 states: default, pressed, disabled, loading with spinner and "Creating account…"). Variants: primary (red fill, white text), secondary (transparent, white text, gray outline), destructive outline (pink text and border, used for Log out and an enabled-looking Submit report), text button ("Forgot password?", "Register now", "Log in" links, white bold). Pressed primary uses `#B91C2C`.
- **Input**: label above (14, white), field 56 high, fill about `#1B1B1E`, 1 px border. States: default, focused (white border), filled, error (pink border, "⚠ Enter a valid email address." below in pink), disabled-looking helper text gray ("Use 8+ characters, including a number."). Password input has an eye toggle at the right.
- **Chip** (category): rounded rectangle radius 12, about 44 high. Selected: white fill, black bold text. Unselected: dark fill, gray outline, white bold text. Wraps onto two rows (Strength, Hypertrophy, Fat Loss / Endurance, General Fitness). The current app uses pill chips; change to radius 12.
- **Segmented control**: bordered container, two segments; selected is white fill with black text (Public | Private, Popular | New).
- **Set chip** (about 52 square, radius 12): ready (outlined, number), logged (green fill, dark text, "✓ 1"), skipped (outlined, "— 8"), up next (dim outline). Used in lists of set rows and in a wrapping grid (4 per row).
- **Toast**: dark card, 2 px green border, green "✓ message" text, large radius. Messages: "Plan saved to your library", "Plan link copied", "Report sent. Thank you.", "Workout shared with the community".
- **Avatar**: circle 40 on plan cards; rounded square about 80 on Profile.
- **Icon / Icon button**: 24 px outlined icons, tap area 44.
- **Tab item / Bottom tab bar**: Home, Discover (search icon), Create (plus), Profile. Active: pink icon and white bold label. Inactive: gray icon and label. Bar fill `#0B0B0D`, height about 72 plus home indicator.
- **Plan card**: fill bg/card, radius 12, padding 16. Title 20 semibold; meta gray "Strength · Intermediate · 6 weeks"; row with avatar 40 and "@handle" (and "· 2h ago" on new plans); footer: bookmark icon and "1,248 saves" in gray on the left, outlined button "Save" or "Saved" on the right.
- **Empty state**: card with icon, title 20 semibold, gray body, red primary button ("Create a plan") or "Clear filters".
- **Rest-timer bar**: docked card above the main button. Left caption "REST TIMER · SECONDS", right number 32 bold. Row: outlined "−15s", outlined "+15s", text "Skip". At 90 the +15s is dimmed. At 0: caption becomes "READY FOR THE NEXT SET", "−15s" and "Skip" dimmed, "+15s" enabled. 91 states are drawn (90 down to 0, 1 s per step).
- **Day card**: "Day 1" label and title ("Pull & press"), then exercise rows: name white, gray "4 sets × 8 reps · Rest 90s". Unilateral rows read "8 sets × 10 reps / side · Rest 60s".
- **Exercise row** (plan builder): name, gray "4 sets × 8 reps · 90s rest", gray muscle tag below ("Chest", "Back"), six-dot drag handle at right. Swipe left reveals a pink-outlined "Delete" button.
- **Welcome preview row**: green ✓ square and "8 reps × 40 kg"; third row is a dark square "3" with "Next set · You've got this".
- **Profile header**: "Profile" Display title, settings gear at right, avatar, name 24 semibold, "@handle" gray. **Stats card**: three columns, big number and caption ("sessions", "day streak" in green, "kg volume"). **Plan row**: document icon, title, gray "Public · Strength · 6 weeks", chevron. **Settings row**: card with title, gray value ("On", "Private", "Kilograms (kg)"), chevron.
- **Auth heading/form/body/footer**: see screens 2 below.

## 3. Screens (39)

Navigation: tabs Home, Discover, Create, Profile. Back arrows top left on pushed screens, title centered or left-aligned beside them.

### 01 Guided starter flow
1. **Discover**: title "Discover", subtitle "Find your next training block." Featured card (photo 1, label "COMMUNITY FAVOURITE", title "Upper-body foundation", "6 weeks · Strength · @maya.moves"). Label "Search plans", search field "Search by goal, plan or coach". Category chips (Strength selected). Segmented Popular | New. Section label "COMMUNITY FAVOURITES", then plan cards. Tab bar with Discover active.
2. **Plan detail**: back, title "Plan", share and flag icons right. Hero photo, caption "STRENGTH · INTERMEDIATE", title "Upper-body foundation", meta "6 weeks · 2 workouts / week · 35–45 min". Author row: avatar, "Maya Chen", "@maya.moves". Description paragraph "Build a balanced upper body with two focused sessions. Add a little weight when every rep feels strong." Starter card: "START SMALL. BUILD MOMENTUM." / "Try the 2-set starter" / "Bench press · 2 × 8 reps · 40 kg" / "90-second rest between sets". Below (scrolls): "Your weekly schedule", "Repeat each week. Rest at least 48h between days.", day cards. Fixed bottom: primary "Start workout", then two outlined buttons "Save" and "Copy & edit".
3. **Starter intro** ("Your 2-set starter"): back bar card. Hero card with photo 2, label "PACE / STARTER", "Start strong.", "Two sets. One good habit." Title "Upper-body foundation", gray "Bench-press starter · Maya Chen". Info card: "BARBELL BENCH PRESS", "2 sets × 8 reps", "40 kg total barbell weight", "90-second rest between sets". Note "A short preview of the full plan. Warm up first. Use a weight that feels controlled." Primary "Start session".
4. **Workout, set 1 ready** ("Bench-press starter"): "SET 1 OF 2", heading "Build your rhythm.", "Barbell bench press", "0 of 2 sets logged · 90s rest". Two inputs: "Weight · kg" (40) and "Reps" (8). Two set rows (number chip + "40 kg × 8 reps" + status: "Ready to log" / "Up next"). Tip card "CONTROL EVERY REP" / "Lower smoothly. Press with intent." Hint "Next: recover for 90 seconds." Primary "Log set 1 · 40 kg × 8".
5. **Rest running**: "1 OF 2 SETS LOGGED", "Take a breather.", green "Set 1 saved · 40 kg × 8 reps". Set 1 row green "Logged · 320 kg volume", set 2 "Up next". "UP NEXT" / "Set 2 · Barbell bench press". Rest-timer bar counting down. Primary "Continue to set 2".
6. **Rest complete**: same, heading "Ready for round two?", timer at 0 "READY FOR THE NEXT SET".
7. **Set 2 ready**: "SET 2 OF 2", "Make it count.", "1 of 2 sets logged · 90s rest", set 1 logged, set 2 "Ready to log", hint "Your final set. Finish when you're ready.", primary "Log set 2 · 40 kg × 8".
8. **Two sets logged**: green "2 OF 2 SETS LOGGED", "Strong finish.", "Every rep is in. Take a moment to recover.", both rows logged, card "TOTAL VOLUME" "640 kg" "2 sets · 16 reps · No skipped sets", hint "Finish to save this session to your history.", primary "Finish workout".
9. **Review session**: "BEFORE YOU GO", "Ready to wrap up?", "Your two-set starter is complete. Save your session and keep the momentum." Card "Upper-body foundation" / "Bench-press starter" with rows "Sets completed 2 / 2" (green), "Reps completed 16", "Total volume 640 kg". Buttons: outlined "Back to session", primary "Finish & save".
10. **Summary**: "Workout summary", photo 3, green "SESSION SAVED", "You showed up.", "Upper-body foundation · 2-set starter". Card with "640 kg Total volume" and "16 Reps completed". Row card "Barbell bench press" / "2 / 2 sets saved · 40 kg × 8 reps each". Primary "Back to Discover".

### 02 Access and home
11. **Welcome**: huge "PACE" wordmark, spaced caption "TRAIN WITH INTENT" over a faded dark photo. Card "TODAY'S PLAN" / "Stronger, set by set." with the welcome preview rows. Headline "Your next rep. Your next level." gray "Build plans. Train. Share progress." Primary "Log in", secondary "Create account".
12. **Log in**: back arrow, "PACE" wordmark over faded photo, "Welcome back", gray "Your next session is waiting." Email field, Password field with eye, right-aligned "Forgot password?", primary "Log in". Bottom centered gray "New to PACE?" and "Register now".
13. **Create account**: wordmark, "Create account", "A stronger routine starts here." Fields Name ("Your name"), Email ("you@email.com"), Password ("At least 8 characters"), helper "Use 8+ characters, including a number.", primary "Create account", gray "By continuing, you agree to our", "Terms of Service and Privacy Policy", gray "Already have an account?", "Log in".
14. **Log in error**: email "alex@" has pink border and "⚠ Enter a valid email address."
15. **Create account loading**: fields filled (Alex Morgan, alex@email.com), button shows spinner and "Creating account…" in the pressed color.
16. **Home**: "PACE" wordmark top left with a short red line right, caption "MONDAY, AUGUST 18", "Good morning, Alex." Stats card "THIS WEEK 3 day streak" and "SESSIONS 2 sessions". "Continue workout" card with grayscale photo: "STRENGTH", "Upper body A", "Day 1 · 13 sets complete · 1 skipped", primary "Resume workout". "Saved Plans" with "+" at right; plan rows "Upper / lower split / 4 workouts · Strength" and "Weekend full body / 2 workouts · General fitness" each with a square thumbnail.
17. **Home, no plans**: "Let's get moving, Alex.", stats "0 day streak" / "0 sessions", card "No activity yet" / "Your first session starts a new streak." "Saved Plans" empty card: "Make room for progress." / "Build your first plan, then make every session count." / primary "Create a plan".

### 03 Discovery, sharing, moderation
18. **Discover, New**: Discover without the featured card; chips; segmented with New selected; label "JUST ADDED"; cards "The steady strength reset" ("Strength · Beginner · 4 weeks", "@maya.moves · 2h ago", "12 saves", "Save") and "Build a stronger back" ("Strength · Intermediate · 8 weeks", "8 saves", "Saved").
19. **Discover, no results**: search "Marathon on Mars"; empty card with search icon, "No plans found", "Try another search or clear your filters.", primary "Clear filters".
20. **Share plan**: "Share plan", "Train better, together.", "Send a plan to your training partner." Plan card ("Upper-body foundation", "Saved"). "PLAN LINK" card: "pace.fit/p/upper-body-foundation", outlined "Copy link". Outlined "Share with Messages", text "More sharing options".
21. **Report plan**: "Report plan", "Help keep PACE safe.", "Choose a reason. Reports are private and reviewed by our community team." Four outlined options: "Unsafe exercise advice", "Spam or misleading content", "Harassment or hate", "Something else". Note "Reporting does not notify the author." Bottom "Submit report" (pink, disabled until a reason is chosen).

### 04 Plan builder
22. **Create plan**: "Create plan". Fields: Plan name, Duration ("6 weeks") and Difficulty ("Intermediate") side by side, Category ("Strength"), Visibility segmented (Public | Private) with "Public plans appear in Discover." Section "Day 1 · Exercises" with "Hold the grip to reorder. Swipe left to delete." Exercise rows. Sticky primary "Save plan" above the tab bar.
23. **Plan exercises**: "Plan exercises", summary card "Upper-body foundation" / "6 weeks · Strength · Intermediate · Public" / "Edit plan details". "Day 1 · Exercises", rows (including "Single-arm half-kneeling cable row 8 sets × 10 reps · 60s rest Back"), outlined "+ Add exercise", sticky "Save plan".
24. **Add exercise** (bottom sheet over "Create plan"): drag handle, close X, "Add exercise", "Make every set count.", "Add an exercise to Day 1." Fields: Exercise name, Sets (8) and Reps (10), "Rest between sets" ("60 seconds") and "Muscle tag" ("Back"). Note "For unilateral moves, reps are per side." Primary "Add to Day 1".
25. **Reordered**: the added row now first in the list.
26. **Delete**: one row swiped to show pink "Delete"; helper "Swipe left to reveal Delete."
27. **After delete**: list without that row.

### 05 Full workout and sharing
28. **Active workout** ("Upper body A"): "14 / 15 sets completed · 1 skipped", green progress bar, "Tap a set to complete it. Tap again to skip." Completed exercise collapses to "Barbell bench press ✓ 4 / 4 sets · 8 reps × 40 kg" (green). Open exercise: name, "10 reps / side × 20 kg · 60s rest", grid of set chips. Rest-timer bar docked. Primary "Finish workout".
29. **Last set**: "13 / 15 sets completed · 1 skipped", "One more set. Finish strong.", collapsed cards (second reads "✓ 7 complete · 1 skipped · 20 kg × 10"), open card "Wide-grip lat pulldown" with "12 reps × 40 kg · 60s rest" and chips ✓1 ✓2 3. Disabled bottom button "Complete the final set".
30. **Workout summary**: green trophy icon, "Session complete.", "Upper body A · Today, 7:42 AM". Card: "TOTAL VOLUME 4,120 kg", "DURATION 42 min 18 sec", "SETS COMPLETED 14 of 15 · 1 skipped". Card "NEW PERSONAL RECORD" (green) "Barbell bench press" "40 kg × 8 reps" "+2.5 kg from your previous best". Buttons: primary "Share", outlined "Done".
31. **Share workout**: same summary; primary "Share to community", outlined "Share with a friend".

### 06 Profile and settings
32. **Profile, public**: described in components. Segmented Public | Private on "My plans" (Public selected). Rows "Upper-body foundation / Public · Strength · 6 weeks", "Bodyweight anywhere / Public · Strength · 4 weeks". "Saved plans" row "Upper-body foundation / @maya.moves · 6 weeks · Strength".
33. **Profile, private**: segment on Private; row "Strength builder draft / Private · Strength · 8 weeks"; outlined "Create a plan".
34. **Profile, no activity**: stats 0, 0, 0; empty card "Make your first plan" / "Your routines and progress will live here." / primary "Create a plan"; "Saved plans" empty row "No saved plans yet."
35. **Settings**: back, "Settings" Display title. Card "Alex Morgan / alex@email.com". "PREFERENCES": Notifications (On), Default plan privacy (Private), Weight units (Kilograms (kg)). "ACCOUNT & SUPPORT": Privacy & security, Help & feedback. Pink-outlined "Log out". Footer "PACE · Version 1.0".

### 07 Feedback
36 to 39. Four toasts (see components).

## 4. Interaction notes

- Rest timer: 90 s maximum, 1 s steps, ±15 s, Skip ends the rest. At 0 the label changes and set can continue.
- Workout lists: tap a set chip to complete, tap again to skip (full workout). Guided starter logs one set at a time with a button.
- Drafts: reorder by dragging the handle, delete by swiping left.
- Buttons are 56 high on workout screens.
- Never put small text over a busy photo (the auth screens' hero photo is faded for this reason, but the "PACE" wordmark overlaps the photo).

## 5. Known inconsistencies in the design

See section 4 of `docs/gap-audit.md`. Ask Allen to confirm: background black vs `#0B0B0D`, the pink active color, the pill vs radius-12 chips, and the +15s behavior at 0.
