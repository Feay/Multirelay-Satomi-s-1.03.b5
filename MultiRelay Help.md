DISCLAIMER: This relay is the one OpenCollar's has been based on since version 3.2. So don't be surprised to find many similarities. However both relays followed their own ways and now have some noticeable differences: for instance OpenCollar's is well integrated to the collar's auth subsystem whereas this HUD relay focuses more on experimental features, and as it is a HUD also provides visual indicators the collar relay cannot have.

This relay is a multi-object relay, with some extra features.

It conforms to the Open Relay Group (ORG) specifications version 0003 (which include RLVR 1.100 compatiblity).
It is "Multi" in the sense that in opposition to most relay that were made before year 2009, it won't reject commands from new devices when you are already controlled by one.


A bug? A suggestion? Please report it here: http://code.google.com/p/multirelay/issues/list

Main features
- several concurrently restraining devices supported
- classic ask/auto/off modes
- extra mode: restricted (only whitelisted goes through)
- extra submode playful
- (togglable) safeword
- evil safeword - when someone is around you, they will be asked to help you. When you are alone you just get freed. (thanks Vala Vella for adding this!)
- black and white lists for objects and avatars
- manual lockFree
- autolocking when restrained, and impossibility to turn the relay off or cut the already restraining sources off
- smart strip: when enabled, clothing items stripped through this relay will also make you unwear the folder they are in (if this was in #RLV)
- informative HUD
- menu access by chat command: /99relay
- not vulnerable to the "arbitrary text on arbitray channel", and "shout garbage on public chat" loopholes
- not vulnerable to the stack-heap collision issue when requests accumulate (rejects them when there are too many)
- auto-updates via HippoUpdate

Note: the auto-update script is the only script that isn't mine and that I don't license and distribute full perm. It is no mod only for hiding the password of my update server (but as this update server is only for free items, I will consider making the script full perm too if I can be sure that divulging this "password" is no security issue). Delete the script if it bugs you that the contents of one of the scripts are not visible, it will only stop auto-updating but won't prevent the relay from working correctly.


ORG x-tensions:
- who: the relay can be informed about who is operating the device restraining it (user name appears in the ask dialog)
- handover: transfer a relay session from one object to another
- channel: lessens the lag by switching relay chat to another channel.
- email: enables gridwide (cross-sim) access. (you will need a compatible device for controlling your relay gridwide, such as the Witchy Remote, which I blatantly advertise! You may find it there: 􀀀
- http (commented out for now)
- ack: silence your spammy acknowledgements!
- delay: delayed relay commands (timed restrictions, and stuff like this ;-))
- vision: hud vision effects through applying colors, transparency and textures to a prim of the relay.
- follow: makes it possible for a controller to have the relay wearer follow it (like a leash)

non-ORG extension:
- @thirdview pseudocommand: makes it possible for a device to enforce mouselook

Potentially coming in the future:
- ORG !x-animate
- ORG !x-safe
- ORG !x-key
- <insert your idea here>


Menus buttons:
(Note that irrelevant buttons are automatically hidden in the dialogs. Don't be surprised if you don't always have all those buttons!)

In the main dialog:
* Mode (xxxx): the relay is in mode xxxx. Click this to go the next mode.
   Current modes are:
   * Off: the relay is disabled
   * Restricted: the relay rejects every future request (except from whitelisted devices and devices already controlling you)
   * Ask: the relay asks before accepting future requests (except from white or blacklisted devices)
   * Auto: the relay accepts every future request (except from blacklisted devices)
* Playf (off/on): en/disable automatic acceptation of non-restraining commands (combines with the previous modes)
* SW (off/on/evil): en/disables the possibility to safeword when restricted or enables the evil Safeword
* Grabbed by: shows the list of devices currently controlling your avatar, and the list of restrictions they enforce.
* Refresh: checks that every device restricting you is reachable. Restrictions from unreachable devices will be cleared.
* Pending: shows the request dialog, in case there are pending requests
* Help: gives this notecard
* SAFEWORD: clears all restrictions and lists
* Access lists: opens the access list management dialog, for removing trusted or banned sources

In the request dialog:
* Yes: accept this command (and other commands from the same device until unrestricted)
* No: rejects this command (and other commands from the same device in the few following seconds)
* Trust Object: same as Yes, but adds the object to the whitelist
* Ban Object: same as No, but adds the object to the blacklist
* Trust Owner: same as Yes, but adds the owner of the object to the whitelist
* Ban Owner: same as No, but adds the owner of the object to the blacklist
* Trust User: same as Yes, but adds the avatar using the object to the whitelist
* Ban User: same as No, but adds the avatar using the object to the blacklist

HUD code:
* red blinking circle prim on the right: there are pending authorization requests. Touch this prim to get the ask dialog.
* highlighted: relay is locked, the hovering number tells how many sources grab you
* green background: auto mode
* blue background: ask mode
* red background: restricted mode
* grey background:  relay is off
* the numbers above the relay is the number of sources currently grabbing it. Touch the numbers to get their names and the list of restrictions they set on you.


Changelog:

1.03:
b5
* long press on source number to safeword (and moved safeword stuff to safekeeper)
* changed llParseString2List to llParseStringKeepNulls where it makes sense (allows parsing RLV commands with empty idents). Issue 28.
* fixed chatkeeper permissions
* fixed "Out of memory" message on negatively authed commands
b4
* added command "/99debug 1" and "/99debug 0" to toggle outputting ack values to llOwnerSay (because it's become impossible to use a separate debugger with llRegionSayTo)
* issue 15: the relay would not be unlockable after safeword+relog
* all touch events and hud effects managed from the same script in root prim (fixes issue 18, and incidentally issue 8)
* issue 11, missing llListFindList (thank you Toy Wylie)
* ping/llSleep inversion prevented sitting back on relog (issue 16?)
* use of llRegionSayTo for acknowledgements
* fixed !x-follow in the case with parameters
* huge memory optimizations in gatekeeper (mostly inlining)
* removed confusing internal "$$" command (use of a CMD_FLUSH LM instead)
* hardened gatekeeper against stack-heap collisions (using queue memory estimate instead of queue length)
* graceful escape in case of memory saturation (every command that cannot be queued is ko'd)
* reversed safeword order
* updated messages to the wearer
* moved number texturing to root prim (llSetLinkPrimitiveParamsFast in StatusKeeper)
b3
* issue 2: now timers should not get stuck anymore
* issue 7 improvement: HUD is resized before color change
* !x-follow now is reset on safeword
b2
* issue 6: ignore pong answers from non-legit sources (was OC issue 1169, thank you Cora Haiku)
* issue 5: Winter's !x-follow implementation now integrated
* issue 7: added !x-vision support
* issue 8: touch the numbers to have the sources and restrictions list
b1
* issue 1: RLV lock restored on relog in Locked mode (thanks Jo Ronin)
* issue 3: added link to bug tracker in the menu
* lots of code reorganization, following the fix of issue 1

1.02:
* SA: ORG 0003: wildcard support, relay always answers to key ffffffff-ffff-ffff-ffff-fffffffffffff in addition to the wearer key.
* SA: delayed clearing entries in Pigeonkeeper after safewording (we need this to send !release,ok)
* SA: the relay stops resetting windlight settings when it is uncalled for (thank you Kim Fosset for reporting)
* SA: removing annoying message on rez about the relay being locked (or not)
* SA: added /99relay chat trigger to open the relay menu
* SA: 3rd view handle multiple devices and blocks setenv and setdebug
* SA: added x-ack
* SA: added x-delay

1.01:
* SA: pending status glitches fixed (thanks to Ash Yheng for the report)
* SA: some bug in email mode due to the http changes, now fixed (thanks to Yakumo Fujin for the report)

1.00:
(* http-in support: commented out in released version, until I finalize the protocol draft)
* new hud from Medea Destiny
* improvements on that hud by Toy Wylie
* fix by Liace Parx (pre45)
* fixed @clear=xxx issue (restrictions not released) (pre46) (thanks Cerdita Piek for reporting)
* fixed ko on !pong (pre47) (thanks Mikk Morane and R2D2 Scribe for reporting)

0.99:
* added the evil Safeword functions. Adapted by Vala Vella from Marissa Mistwallow's relay, via Toy Wylie's smart relay ;-). See SafeKeeper Script for details. 
* revamped the main dialog. Now buttons do reflect the current setting instead of the next one.
* distance control for relay answers (no need to spam all the already laggy sim with relay replys)
* access lists are reset on owner change
* added a manual locking menu option to provide a means against accidental detaching of the relay (by Toy Wylie)
* fixed error message when trying to edit an access list that has more than 11 entries
0.98:
* added owner names in the "Grabbed by" output
0.97:
* added "Refresh" for clearing restrictions from unreachable devices
* added reinforcement of rescrictions if the relay has been displaced although it was locked
* removed the non restraining mode, as it makes the relay "lie" and not being compliant with the RLVR specification (the code is still in there in gatekeeper script if you want to uncomment it)
0.96:
* !x-tensions became !x-orgversions
* the relay is now supposed to be reachable directly by email (if the controlling devices knows its email adress)
<0.96: I don't remember. I try to file the changelog from now on!
0.95: gridwide really usable
0.90: preliminary gridwide access features



Legal disclaimers:
* My scripts are full perm, and I want it to be redistributed as such. Consider they are GPL with the same clauses as OpenCollar. So if you want to take it into the relay of your own shop, there is no problem with me, provided all scripts remain full perm (not counting OpenCollar, at least 2 other famous shops I know of are already doing so with my benediction).
* Only the script "MultiRelay VersionKeeper" comes from Hippo Technologies and is not licensed by me. Please do not include it in derived products!
* The padlocks of the HUD are a derivative work I made from an original clipart by AJ Ashton, under the Creative Commons Attribution license. The original padlock can be found on Wikicommons.

Acknowledgements (other than code contributions):
Marissa Mistwallow for her active search of loopholes in the relay implementations.
Maike Short for her relay test suite that helped me fixing some typical relay bugs.
Chloe1982 Constantine and Ilana Debevec for fruitful discussions about the new metacommands.
Vala Vella for adding the evil safeword.
Toy Wylie for adding the manual locking feature and paging system for access lists.
All the guinea pigs who tried the early versions of my relay!


I hope my relay will suit your needs!
Satomi Ahn