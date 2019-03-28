# Contacting the Ops team

The steps below for finding an Ops person escalate in urgency and disruptiveness. Favor earlier steps and waiting for a response, but use your best judgement.

If there is an emergency -- production is down right before a big demo, an attack is in progress -- then it's more important to get an engineer's attention than it is to avoid sending notifications to a few extra people.

1. Note that we do not currently have a formal on-call rotation. 24x7 support is Best Effort.
1. If you don't have an account on the RtF Slack, skip the next few steps.
1. Go to [#ops in Slack](https://raisingthefloor.slack.com/messages/ops/). Ask for help using `@here`. [More on Slack announcements](https://get.slack.help/hc/en-us/articles/202009646-Make-an-announcement).
1. Go to [#ops in Slack](https://raisingthefloor.slack.com/messages/ops/). Ask for help using `@channel`.
1. Email `ops at raisingthefloor dot org`. Please, attach as much detail of the issue as you can. A good template for such email could be:

```
Subject: [Type here a short description of the issue]
Body of the message:

* Physical location of the PC that is having a problem (e.g. Pilot site in Washington, D.C.; my development laptop on my local cafe's internet)?

* Describe the problem. What is happening?
** Please include any screenshot, detailed error messages, or other details that you think might be helpful.

* What did you expect to happen instead?

* If possible, what happens use a browser on the affected PC and go to https://flowmanager.prd.gcp.gpii.net/health. What does it say?

* If possible, try to reproduce the problem on a nearby computer (e.g. another device in the same lab). Repeat the above check using the nearby computer's browser. Is anything different?
```

## There is an operational emergency (production is broken, there's been a security breach, etc.)

First of all, DON'T PANIC! Everything is going to be fine. :)

Your next task is to find a human on the Ops team. Ops engineers are trained to handle emergencies (including asking other experts for help).

Start with the procedure above -- it is the quickest way to notify as many Ops team members as possible -- but bias toward action rather than waiting. For example, for an ordinary question or non-urgent problem, I would post in Slack and wait a while before trying again or moving to the next contact step. If production were down, I would post in Slack but wait only a minute or two before moving to the next contact step.

If you have exhausted the contact steps above, move on to these steps only for emergencies:

1. Call or text specific Ops engineers. [Contact info](https://docs.google.com/document/d/1EDYhWYipUluzG6K8S-W4clsAGInm2RdjkpKq9Lw_dhE/edit).
   * If possible, pick an engineer who is in the middle of their work day over an engineer who is likely asleep. Timezone information is in [Contact info](https://docs.google.com/document/d/1EDYhWYipUluzG6K8S-W4clsAGInm2RdjkpKq9Lw_dhE/edit)
   * Repeat until you've reached an Ops engineer, or exhausted the list of Ops engineers (likely-awake or otherwise).
1. [#ops in Slack](https://raisingthefloor.slack.com/messages/ops/), Skype, text, or call Sandra, Colin, or Gregg. These people may know where to find an Ops engineer.
1. Email `ops at raisingthefloor dot org`, using the above template in order to provide a detailed description of the emergency.
