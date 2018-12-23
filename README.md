# DRAWS
DRAWS turnkey scripts for the SVARC and MBARC radio clubs in Bellingham and Whatcom County Washington
Please note that through this document 'we' will refer to the above clubs and those who use this script

PLEASE NOTE UNTIL FURTHER NOTICE THESE SCRIPTS ARE UNTESTED!!!! USE AT YOUR OWN RISK!
TODO:
- test script for correctness
- work on weak signal software (ie wsjt and the like)

This project will have two main scripts:
- the install script that will auto-install all libraries, support files and programs that 'We' use
- a 'quick and dirty' update script that uninstalls old programs, downloads and installs new versions

Main focus for this will be:
- FLDIGI library (including FLAMP and FLMSG)
- WSJT Type programs (ie weak signal that requires percise time keeping)
- GPS utilities
- XASTIR with a setup file that includes the GPS 'modem'

other items that will be of some use:
- sound card settings that 'work' (I tweaked the orginal settings to make mine work)
- field day logger program
- other utilites that are helpful

Current status:
12/23/18:
- checked xastir and direwolf, direwolf works but xastir's version is too old, modified script to install libraries and from source
- fldigi installs correctly, gps and chrony also install with config files
- code flows better, consolidated and refractored code
- better comments and whitespace
