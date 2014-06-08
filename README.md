Rom Asset Mover
===============

The goal of this perl script is to take a variety of inputs based around the need to maintain roms and assets
when using multiple arcade emulators with a frontend. Currently it takes a quickplay datfile and manipulates 
roms and assets on disk to maintain compatibility between generations of rom names.

Because mame roms have a parent/child relationship, if we don't find the asset, we will try and find it's parent and use 
its asset. Complications can emerge (e.g.: when a rom's parent gets renamed in one arcase emulator scheme, but remains at its
old naming in others. Hence we take a defensive approach and maintain parent asssets in the child name)
