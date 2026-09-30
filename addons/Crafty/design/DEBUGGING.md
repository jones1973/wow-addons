# Debugging Conventions

When something breaks, switch modes: stop building, start investigating. The
rules in this document apply during debugging specifically. They are stricter
than the everyday CLAUDE.md guidance because debugging is where most of the
process failures in this project have happened.

If a process correction is needed during a debugging session, it goes in
here, not in CLAUDE.md.

---

## The workflow

The default order of operations when a bug is reported:

### 1. Establish reproducibility

A bug you can't reproduce is a bug you can't debug. The first priority,
before any investigation, is having a reliable way to make the bug happen.

Intermittent bugs need to be made intermittent-on-demand. If the user can
reproduce it and you can't, that reproduction is the most valuable resource
in the session — don't ship any code that might disturb it before
extracting diagnostic value from it.

### 2. Diff and look

Identify what changed since the system last worked. Read that diff. Look
for:
- The mechanism that would produce the observed symptom.
- Plausibly-suspect lines you'd want to instrument or disable.

Investigate to the depth required to produce a well-formed report — see
step 3.

### 3. Report

Stop and report what you found. The report is the deliverable. It must
stand on its own — well-formed, complete, researched, no loose ends.

The standard is "report you'd give to a boss you feared." That means:
- No guesses dressed up as findings. Every claim is either backed by
  evidence (diff hunk, line number, observed behavior) or labeled
  explicitly as a hypothesis.
- No "do you want me to..." questions. The report proposes the next
  step, doesn't ask for permission to think of one.
- No vague language ("maybe," "possibly," "could be") used to hide
  uncertainty. If something is uncertain, name what's uncertain and
  what would resolve it.
- No omitted negatives. If the diff shows nothing implicated, say so
  directly; don't hedge.
- No padding. Length matches content; if the answer is one sentence,
  the report is one sentence.

Shape of a report:
- What changed (diff summary, scoped to what's relevant).
- What the diff suggests about the cause.
- The proposed next step and the experiment that would falsify the
  hypothesis if wrong.

The report gives the user the chance to either approve the proposed
step or redirect. This is the checkpoint. Don't skip it by continuing
to investigate or starting to design a fix.

### 4. Proceed as directed

The user either confirms your direction, redirects, or asks for more
information. Whichever they choose, do that — not what you started
doing on your own.

---

## Instrumentation

Often the right next step after the report is instrumentation rather than
more reading. When the runtime behavior doesn't match the model in your
head, ASK THE RUNTIME what it's actually doing.

### When to instrument

- Static reading has produced a hypothesis but not certainty.
- Static and runtime appear to disagree.
- The system is too complex (timing, environment, external data) for static
  reading alone to be conclusive.
- The bug only manifests in conditions hard to replicate outside the
  running system.

### How to design good probes

Instrument as if this is the ONLY capture you will ever get - even when the
user says they can reproduce it at will. Every probe set must be designed so a
single run answers every open question at once, top to bottom: trace each path
the values can take, and at every silent return, every nil-able lookup, every
branch, make the code self-report in that same run. If a capture comes back and
tells you only WHERE it died but not WHY - so you have to add more probes and
ask for another capture - the instrumentation was lazy. Needing a second round
of probes is a failure, not iteration. Before shipping a probe, ask: "if this
run comes back, will I know the complete answer, or just the next question?" If
it is the next question, the instrumentation is not done.

Visible, well-designed instrumentation beats observable reproducibility
alone. Good probes are:

- **Minimal lines, maximum information.** One log line at a decision point
  that prints all the relevant inputs is better than five lines printing
  one variable each.

- **Placed at decision points.** Branches, returns, calls into external
  systems. Anywhere the code chooses between paths is where the data
  needs to be visible.

- **Especially placed at inputs.** Before a function uses a value, confirm
  the value is what it expects. Half of all bugs are "the input wasn't
  what I thought." Instrumenting inputs catches those without needing to
  trace further.

- **Non-disturbing.** Probes should observe, not change. They must not
  alter the function being debugged. Side effects, mutation, re-ordering
  of operations — all forbidden in a probe.

- **Self-labeling.** Each probe's output should be unambiguous about
  which probe it came from. When five probes fire during one user
  action, you need to know which value belongs to which.

### Knowing what data you need

You can't always know up front. That's expected.

Strategy:
- Start with the inputs to whatever code you suspect.
- Add the outputs of decision points (which branch was taken, what
  values were compared).
- If neither reveals the cause, expand outward: caller inputs, callee
  outputs.

The discipline is "instrument the boundaries of the suspect region
first, expand inward only when needed." Over-instrumenting up front
clutters the output and slows the diagnostic.

### Remove instrumentation after it confirms

Once a probe has answered its question — confirmed inputs are what you
expected, confirmed a branch is taken, confirmed a value at a moment —
take it out.

Constant confirmation of things already known is noise. It clutters
output, makes future debug sessions harder to read, and accumulates
into a codebase that's gradually less clean. The probe was a tool for
one question; when the question is answered, the tool comes out.

Exception: instrumentation that's expected to fire only in error
conditions (warnings, assertions about invariants) can stay
permanently. Those are guards, not probes.

---

## Core rules

### Read symptoms literally

The data is the data. "Name is blank, tooltip shows the name" means
exactly that. Don't reinterpret it as "the displayed text looks blank
but is actually some weird non-empty thing" unless the literal read
fails to fit any plausible mechanism.

When the literal read suggests an impossible mechanism, the answer is
to test the mechanism, not to invent a more comfortable interpretation.

### Read the vendor's source before probing client behavior

Blizzard's own UI is published: github.com/Gethe/wow-ui-source, branch
`classic` for MoP Classic, `classic_anniversary` for TBC. When the question is
"how does this client want this API called," the FrameXML that ships the
working button is a PRIMARY SOURCE and outranks any probe we can write - it
shows the exact call, the exact argument, and the surrounding teardown.

Field-earned: an unlearn call failed silently through two builds and a probe
round-trip. The vendor's dialog handed AbandonSkill the SKILL LINE ID; our
walk was passing a list POSITION. One clone of the UI source answered in
minutes what in-game probing had not.

Applies to any protected/secure-path question, any "does this event fire
before or after X," and any argument-shape uncertainty. Read first, probe the
remainder.

### Suspect recent changes most

A bug that appears shortly after a code change is almost always caused
by that change. The mental prior on "the new code is wrong" should be
very high relative to "the old stable code has hidden issues that just
now surfaced."

### Subtract before adding

When a feature is suspected, REMOVE it (or bypass it) as the first
diagnostic. Adding fallbacks, parameters, or guard clauses to "fix"
the suspect code is more work and provides weaker signal than just
turning the code off and seeing what happens.

If the symptom disappears with the code disabled, the code is the
cause. If it persists, the cause is elsewhere — and we've ruled out a
whole direction cheaply.

This is the foundation of bisection (Agans' "Divide and Conquer").

### Investigate, don't theorize

When data and theory disagree, the data wins. Always.

Static analysis can prove things are logically consistent in
isolation. It can't prove that the runtime environment behaves the
way the static analysis assumes (lazy resolution, uninitialized
state, race conditions, undocumented platform behaviors). High
confidence in a static read is a signal to test the static read
against runtime — not to skip the test.

### Falsify before fixing

Confirm the cause before designing the fix.

The order is:
1. Form a hypothesis about the cause.
2. Identify a cheap experiment that would falsify the hypothesis if
   wrong.
3. Run the experiment.
4. If the hypothesis survives, only then design the fix.

Designing the fix before step 3 is premature. It primes you to filter
evidence in favor of the design you've already started building — this
is confirmation bias, and it is the single most-studied cognitive bias
affecting programmers (ACM research finds ~70% of developer actions
associated with at least one cognitive bias; confirmation bias
prominent among them).

### Stay in scope

Pick the single most likely cause given the evidence. Test that one.
Don't multiply hypotheses pre-emptively ("it could also be X, Y, Z").

Multiplying hypotheses before testing the first one feels thorough but
is actually a tell that you don't trust your own ranking of
probability. Trust the ranking. If the top hypothesis falsifies, move
to the next.

### Confidence is not evidence

"I'm sure the code can't do X" is not the same as "I tested the code
and it didn't do X." The first is a feeling about a model in your
head. The second is data.

Calibrate confidence to evidence. If a static read says "this can't
happen" and the user shows it happening, the evidence wins — find
what your model is missing.

### If it isn't fixed, it isn't fixed

A fix that "seems to work" without you understanding WHY the original
behavior occurred is not a fix. The bug will return, often in a
different form. Verify the fix addresses the actual cause, not a
coincidental symptom.

Practical test: after a fix, can you re-introduce the bug deliberately
by reverting just your fix? If yes, you fixed it. If no (the bug
doesn't come back), you may have changed something incidental and the
real cause is still lurking.

---

## Anti-patterns

These are failure modes that recur in debugging. Naming them makes
them easier to catch in oneself.

### "It might also be X, Y, Z"

Multiplying hypotheses before testing the first one. Feels thorough;
is actually unfocused.

Cure: pick the single most likely. Test it. Branch only if it
falsifies.

### Designing the fix before confirming the cause

Sketching the new code structure, the new parameter list, the new
fallback logic — before running an experiment that confirms the cause.

Cure: write down the hypothesis. Write down what experiment would
falsify it. Run the experiment. Only after confirmation, design the
fix.

### Asking questions the evidence already answers

The user provides screenshots, error messages, reproduction steps.
Asking questions whose answers are sitting in that evidence wastes
the user's time and signals you didn't read the evidence carefully.

Cure: before asking, re-read what the user provided. Read it twice
if the first read suggests an "ambiguity."

### Static-as-proof

Concluding "the code can't do X" from reading the code, then sticking
with that conclusion when runtime evidence contradicts it.

Cure: when static and runtime disagree, runtime wins. Find what the
static read missed.

### Speculation as substitute for measurement

"Maybe the layout engine hasn't resolved yet. Maybe the font object
is nil. Maybe..." — strings of plausible-sounding theories with no
test attached.

Cure: each "maybe" is a hypothesis. Each hypothesis gets one cheap
experiment. If you're stringing maybes together without experiments,
stop and run one.

### Going deeper in the same direction when stuck

If two rounds of investigation in the same direction haven't found
the bug, the direction is probably wrong. Continuing to dig deeper
produces diminishing returns.

Cure: change approach. Try a different angle (subtract instead of
add, instrument instead of read, ask the user a different question).

### Treating "this worked before X" as theory rather than data

When a user says "it worked before X and now it doesn't," that's a
diff signal. It is the most reliable kind of data the user can
provide.

Cure: trust the user's observation. They have access to runtime
state you don't.

### Leaving instrumentation in after it's served its purpose

A probe that confirmed something a week ago is just noise now. Old
probes accumulate, clutter output, and make the next debug session
harder.

Cure: when a probe has answered its question, remove it in the same
session.

---

## References

- Agans, David J. *Debugging: The 9 Indispensable Rules for Finding
  Even the Most Elusive Software and Hardware Problems.* AMACOM,
  2002.
- Zeller, Andreas. *Why Programs Fail.* Morgan Kaufmann. (Scientific
  debugging methodology.)
- MIT 6.031 — *Reading 13: Debugging.* Hypothesis/experiment loop and
  the design of probes that minimally disturb the system.
- ACM Communications — *Cognitive Biases in Software Development.*
  Field study finding 70% of developer actions associated with
  cognitive biases.
- Software Quality Journal — *Influence of Confirmation Biases of
  Developers on Software Quality.* Empirical evidence that
  developers tend to seek confirming rather than falsifying evidence.
