Starflow
========

Starflow is a set of atrophotographing tools created or customized
by me for me. Someone else might find them useful, or not.

Whatever is created by me is under the BSD license included here.
Adapted code will of course follow the license of the original.

polar-plot/
===========

Plots the polar alignment of your eq mount from two images,
horizontal and vertical shots of Polaris and Lambda UMi.

Origins are in the intersting script from
  https://code.google.com/p/eq-polar-alignment/

titled "Rosedale Photo Polar Alignment", but instead of a script
(which does this and that) I've taken the idea and snippets of code
and combined them into a C program that just solves the alignment
axis and optionally plots a pretty picture of it.

Main use-case is to provide plots into a GUI for checking alignment
prior to shooting stars (pun intended).

Build from the directory by running "make".

You'll need working astrometry install, GSL and WCS libraries.
(better build system and more detailed instructions TBD)
