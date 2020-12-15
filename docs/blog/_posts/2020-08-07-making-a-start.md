---
layout: post
date:   2020-07-08 20:00 +0100
category: Blog
tags: Tax Benefit
title: Making A Start
author: graham_s
---

I'm writing a Scottish Tax Benefit model, and I thought I would blog my progress. I'm writing this mainly just for me,
as a kind of journal; I really would be rather disturbed if anyone read much of it (but, if you do, welcome..). As much
as anything I'd like some practice writing a few hundred words every day.

Tonight I'm waiting for a Covid test result (J. and I both had a dry cough), and I'm having a [Twitter
Argument](https://twitter.com/Malcolm4Linn/status/1291757194137014272), which are both great distractions. Plus some
Prosecco that Judith has poured for me. 

The twitter fight is about [adjustments to Scottish Higher and Standard Grade results given there couldn't be exams this
year](https://www.thenational.scot/news/18637326.scottish-labour-call-john-swinney-resign-exam-results/). The line on
Twitter is that there is a conspiracy here against low income pupils and low income schools, and there just isn't.
Undoubtedly things are tough, especially round here, but the conspiracy stuff, and the innumeracy of many of the
posters, is really annoying. Trouble is, Twitter is (by design I suppose) rather addictive once you get going, looking
for the little blue flags. So that's an hour of my life gone (14 tweets). I'm not very good at Twitter - I kind of
[Colin Robinson](https://uproxx.com/tv/colin-robinson-what-we-do-in-the-shadows/) people into submission ...

The home Covid test requires you to type in 3 long serial numbers (smallest 10 digits) without error, in 3 different
places. I think I did it OK, but I wonder how many tests have gone off into the Ether.

On the model. I've managed to work for 3 days on it this week. I'm not being paid for this, but I have a wee gap in my
schedule building [this monster](https://adrs-global.com/) and I want to get on with things while I can. Got a bit
further. The start of the week was doubling back to the calculation modules I've already written, to change them to
accept calculated, rather than actual, incomes. Should have done that from the outset. Today I got needlessly stuck on
the [Julia Documenter](https://juliadocs.github.io/Documenter.jl/stable/), specifically with how you include docs for
more than one module.

The only other thing of note I managed today is some changes to the National Insurance module to allow pension
contributions as a deduction. I'm not convinced I'm doing this quite right - it's employer's contribitions, so arguably
shouldn't be treated as a deduction from gross wages (but incidence...). But all the tests pass, so that's something.

A year into using it and I'm still struggling sometimes with Julia's type system. The done thing is to use type
annotations sparingly, really just to allow overloading of methods. But I like strong typing. Probably an age thing...
I'll post some examples soon.

I'm also trying a new editor [VS Code](https://code.visualstudio.com/). The first Microsoft thing I've used of my own
free will since, I think, Microsoft Pascal back in the late 80s (that was shit). VS code is the editor the Julia people
are pushing; it used to be [Atom](https://atom.io/). Atom and VS seem pretty similar, though VS is more polished and
perhaps more stable. Both seem a little fussy for my taste; writing this I'm back with my trusty
[JEdit](http://www.jedit.org/). It gets the job done.

So, that's all I think. It was an absolutely beautiful evening here in South Glasgow; should have taken a picture. 

, 