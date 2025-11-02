*****************************************************************
                   Subway Builder Shell Tweaks
  A basic shell scripting approach to tweaking Subway Builder
*****************************************************************


Requirements
------------
- Subway Builder version <=0.7.3
- (?) Bash (may work with other shells, but has not been tested yet)
- Linux (welcoming contributors for Windows and Mac)
- npx, with @electron/asar
- appimagetool (https://github.com/AppImage/appimagetool)


Usage
-----
1. Edit config.cfg.  Ensure that GAME_PATH is properly set.  Set mod flags as desired.
2. Run modify_game_settings.sh.
3. Run the patched AppImage found in the builds/ directory and enjoy.


Config options
--------------
* GAME_PATH: path to your AppImage
* DISABLE_AUTOUPDATER: boolean flag to disable the auto updater
* CHANGE_SPEEDS: boolean flag to change the speed settings
* NEW_SPEEDS: 4 values of the speed relative to real time
* CLEANUP_FILES: determines whether to delete the working directory after the patched AppImage is created


Contributions
-------------
Contributions are welcomed and encouraged, especially for Windows/Mac compatibility and adding new features.


Questions, bugs, and feedback
-----------------------------
Please leave any questions, bug reports, and feedback either here on GitHub or in the thread on Discord.

