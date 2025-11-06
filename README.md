*****************************************************************
# Subway Builder Shell Tweaks
### A basic shell scripting approach to tweaking Subway Builder
*****************************************************************


Requirements
------------
- Subway Builder.  This has been tested for 0.7.3 and 0.8.0, and likely works for other versions.
- (?) Bash (may work with other shells, but has not been tested yet)
- Linux (welcoming contributors for Windows and Mac)
- npx, with @electron/asar
- appimagetool (https://github.com/AppImage/appimagetool)


Usage
-----
1. Open a terminal.  Clone the repo and enter it:
   - git clone https://github.com/rslurry/Subway-Builder-Shell-Tweaks
   - cd Subway-Builder-Shell-Tweaks
3. Edit config.cfg.  Ensure that GAME_PATH is properly set.  Set mod flags as desired.
4. Run modify_game_settings.sh.
5. Run the patched AppImage found in the builds/ directory and enjoy.


Config options
--------------
* GAME_PATH: path to your AppImage
* DISABLE_AUTOUPDATER: boolean flag to disable the auto updater. Only possible for versions <= 0.7.3
* CHANGE_SPEEDS: boolean flag to change the speed settings
* NEW_SPEEDS: 4 values of the speed relative to real time in format '1 2 3 4' (game default: '1 25 250 500')
* CHANGE_MIN_TURN_RAD: boolean flag to change the minimum allowed turn radius
* MIN_TURN_RAD: desired minimum turn radius in meters (game default: 29).
* CHANGE_MAX_SLOPE: boolean flag to change the maximum allowed track slope
* MAX_SLOPE: desired maximum allowed track slope in degrees (game default: 4)
* CHANGE_START_MONEY: boolean flag to change the starting money amount
* START_MONEY: desired starting money in billions (game default: 3)
* CLEANUP_FILES: determines whether to delete the working directory after the patched AppImage is created


Planned features for the future
-------------------------------
* Allow for more than 4 speed settings
* Allow changing maximum train speeds


Contributions
-------------
Contributions are welcomed and encouraged, especially for Windows/Mac compatibility and adding new features.



Questions, bugs, and feedback
-----------------------------
Please leave any questions, bug reports, and feedback either here on GitHub or in the thread on Discord.


