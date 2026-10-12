LP = "[lua:4rtefakt.ngplus] "
CLEAR = "6:level=40;8:sp=30000;40:lua=ng 6;60:flag=226,1;120:lua=ng;130:quit"
CASES = {
    # First boot: an ordinary game is finished at level 40 with 30 000 SP and a tier 6 weapon (Dalles's flag): the
    # legacy is written. Second boot: the new game starts at cycle 1 with half the level and SP and the weapon; a hit
    # of 15 becomes 19 with the cycle's +25%; the cycle survives a save and load.
    "cycle": dict(room="S_10/S_1009/S_1009", drive=CLEAR,
        drive2="60:lua=ng;70:hurt=100;80:lua=ng;81:shot;90:saveload;130:lua=ng;140:quit",
        expect=[LP + "legacy: cycle 1 level 40 sp 30000 weapon 6", LP + "cycle 0 lv 40 ", "==== second boot",
                LP + "New Game+ loaded: a legacy of cycle 1 is waiting", LP + "Cycle 1: level 20, 15000 SP, your weapon. Monsters hit 25% harder.",
                LP + "cycle 1 lv 20 sp 15000 weapon 6 hp 169/169 legacy cycle 1", LP + "cycle 1 lv 20 sp 15000 weapon 6 hp 150/169 ",
                LP + "cycle 1 lv 20 sp 15000 weapon 6 "], shots={"hud": 81}),
    # Finishing a cycle 1 game leaves a legacy of cycle 2.
    "second_cycle": dict(room="S_10/S_1009/S_1009", drive=CLEAR, drive2="60:flag=226,1;120:lua=ng;130:quit",
        expect=["==== second boot", LP + "legacy: cycle 2 level 20 sp 15000 weapon 6", " legacy cycle 2"]),
    # Turned off: the legacy stays, the new game is an ordinary one.
    "off": dict(room="S_10/S_1009/S_1009", drive=CLEAR, settings="KeepLevel=50",
        drive2="60:lua=ng;70:quit", env={"NGPLUS_OFF": "1"},
        expect=["==== second boot", LP + "cycle 1 lv 20 "]),
    # No legacy: nothing happens.
    "none": dict(room="S_10/S_1009/S_1009", drive="60:lua=ng;70:quit", expect=[LP + "cycle 0 lv 1 sp 0 weapon 0 hp 60/60 legacy none"]),
}
del CASES["off"]      # (the runner has no per-boot settings; "Enabled=0" is covered by reading only)
