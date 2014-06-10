Rom Asset Mover
===============

The goal of these perl scripts and modules is to take a variety of inputs based around the need to maintain roms and assets
when using multiple arcade emulators with a frontend. 

The initial need was to take a quickplay datfile and manipulate roms and assets on disk to maintain compatibility between generations of rom names, 
as examplified by the the Functional script in InitialScriptedVersion. But the goal is to create a variety of related scripts, hence splitting into modules.

Because mame roms have a parent/child relationship, if we don't find the asset, we may need to use it's parent. This creates
interesting problems over time as other arcade sets don't keep in step with Mame (e.g.: when a rom's parent gets renamed in one arcade 
emulator scheme, but remains at it's old naming in others: hence we try and accomodate: e.g.: maintain parent asssets in the child name, but in subfolders)
