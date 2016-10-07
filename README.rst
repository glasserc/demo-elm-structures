Demo of some Elm structures
===========================

This repo is an exercise in doing some refactors in Elm to explore
different program structures. It was motivated by comments on
https://github.com/n1k0/kinto-elm-experiments/pull/11 . In particular,
I felt like something was wrong with the structure of the
Task-manipulating code, but I was having a hard time explaining
it. This repo demonstrates (in isolation) some refactors that I would
probably do on such code and maybe explains a little bit what the
advantages are from my perspective. I'm not an Elm expert; I've done
some Haskell professionally but I wouldn't say I'm an expert there
either.

How to use this repo
====================

This file is a series of "structures". You can run them using elm
reactor. However, most files behave identically, so there may not be
much value in doing so. Each file is introduced in a separate git
commit, which explains a little bit about what was changed and why.

The files are:

- structure1.elm: initial state. An imitation of an HTTP client exists
  here, and code exists to process its response. Every file can be
  meaningfully diff'd against this one.

- structure1a.elm: if we force the parsing code to return a ``Result``
  instead of a ``Task``, we forbid impure parsing logic. Purity also
  makes the parsing logic easier to test in isolation. This file
  doesn't compile.

- structure2.elm: instead of having functions that take ``Task``\ s
  and return different ``Task``\ s, we can leave the essential
  sequencing up to the caller, and turn our functions into processing
  just the "contained" values. This is a trick that I learned from
  @pjrt, who argued (in Haskell) that you usually don't want to wrap
  `andThen`, but instead want to expose it.

- structure3.elm: ``parseResponseWith`` can be separated into two
  parts. The first part extracts the body of the response. The second
  part glues the first part with the handler function that it gets
  passed. Separate out the first part as a separate function and you
  end up with a chain of ``andThen``\ s, which give you more
  flexibility in how you decide to break things up (as demonstrated
  above). I spotted this refactor because of the use of higher-order
  functions in ``parseResponseWith``, which (although one of the
  strengths of functional programming!) can still be a code smell.
