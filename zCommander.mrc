on *:LOAD: {

        echo -a zCommander v1.0.1, by Lynn.
}


dialog z.commander {

        title "zCommander - "
        size -1 -1 390 234
        option dbu
        box "", 2, 0 23 389 198
        box "", 3, 0 219 310 15
        text "", 4, 2 224 305 8
        box "Change Directory", 5, 0 0 195 22
        box "Filter files/directories", 6, 195 0 194 22
        edit "", 7, 3 8 150 10
        button "Go!", 8, 155 8 37 10
        edit "", 9, 198 8 150 10
        button "Filter!", 10, 349 8 37 10
        list 11, 3 30 192 166, sort size extsel
        list 12, 194 30 192 166, sort size extsel
        button "Refresh", 13, 4 197 37 10
        button "Create Dir...", 14, 81 197 37 10
        button "Move Dir...", 15, 119 197 37 10
        button "Remove Dir", 16, 157 197 37 10
        button "Refresh", 17, 196 197 37 10
        button "Create File...", 18, 235 197 37 10
        button "Copy File...", 19, 273 197 37 10
        button "Move File..", 20, 311 197 37 10
        button "Delete File", 21, 349 197 37 10
        button "Load", 22, 235 208 37 10
        button "Open", 23, 273 208 37 10
        button "Search...", 24, 311 208 37 10
        button "Run...", 25, 349 208 37 10
        button "Settings...", 26, 311 222 39 12
        button "Exit", 27, 352 222 37 12, cancel
}

dialog z.commander.settings {

        title "zCommander Settings"
        size -1 -1 166 40
        option dbu
        edit "", 1, 49 2 115 10
        edit "", 2, 49 14 115 10
        button "Cancel", 3, 87 26 37 12, cancel
        button "Ok", 4, 127 26 37 12
        text "Default workdir", 5, 5 3 40 8
        text "Default filter", 6, 5 15 40 8
}

;---------------------Init stuff-------------------

alias z.commander {

        if ($exists($scriptdirzCommander.ini) != $true) {

                echo zCommander.ini not found, generating defaults.

                writeini $qt($scriptdirzCommander.ini) zcommander workdir C:
                writeini $qt($scriptdirzCommander.ini) zcommander filter *

                echo Done, starting zCommander.
        }

        dialog -m z.commander z.commander
}

on *:DIALOG:z.commander:init:0: {

        did -b $dname 24
        set %zc.filter $readini($scriptdirzCommander.ini, zcommander, filter)
        cd $readini($scriptdirzCommander.ini, zcommander, workdir)
}

;------------- settings stuff ---------------------

on *:DIALOG:z.commander.settings:init:0: {

        did -a $dname 1 $readini($scriptdirzCommander.ini, zcommander, workdir)
        did -a $dname 2 $readini($scriptdirzCommander.ini, zcommander, filter)
}

on *:DIALOG:z.commander.settings:sclick:4: {

        writeini $qt($scriptdirzCommander.ini) zcommander workdir $did(1).text
        writeini $qt($scriptdirzCommander.ini) zcommander filter $did(2).text
        dialog -x z.commander.settings
}

;--------------------Change directory field-------

on *:DIALOG:z.commander:sclick:8: {

        if ($did(7) != $null) {

                if ($isdir($did(7)) == $true) {

                        cd $did(7)
                }

                else {

                        status No such directory.
                }
        }

        else {

                status No directory specified.
        }
}

;----------------Filter files field-------------

on *:DIALOG:z.commander:sclick:10: {

        if ($did(9) != $null) {

                set %zc.filter $did(9)
                ls df
        }

        else {

                set %zc.filter *
                ls df
        }
}

;-------------directory browsing----------------

on *:DIALOG:z.commander:dclick:11: {

        if ($did(11, $did(11).sel).text == ..) {

                if ($numtok(%zc.workdir, 92) > 1) {

                        cd $deltok(%zc.workdir, -1, 92)
                }

                else {

                        cd
                }
        }
        elseif ($right($left($did(11, $did(11).sel).text, 2), 1) == $chr(58)) {

                cd $did(11, $did(11).sel).text
        }

        else {

                cd $seldir(path)
        }
}

;-------------File browsing-------------------

on *:DIALOG:z.commander:sclick:12: {

        status $fileinfo($selfile, $selfile(path))
}

;------------Refresh buttons----------------

on *:DIALOG:z.commander:sclick:13,17: {

        set %target $replacex($did, 13, d, 17, f)
        ls %target
}

;---------Create Dir-------------------------

on *:DIALOG:z.commander:sclick:14: {

        :start

        mkdir $qt(%zc.workdir $+ $?="New directory:")
        ls d

        return

        :error

        if ($?!="Invalid directory name. Try again?" == $true) {

                goto start
        }
}

;----------Remove Dir-----------------------------

;it's a dirty hack, I know... :/
on *:DIALOG:z.commander:sclick:16: {

        run cmd /Q /C rd /Q /S $seldir(path)
        status Directory $+(',$seldir,') removed.
        did -r $dname
}

;----------Create File-----------------------

on *:DIALOG:z.commander:sclick:18: {

        :start

        write $qt($+(%zc.workdir,\,$?="Create file:")) $chr(32)
        ls f *

        return

        :error

        if ($?!="Invalid directory name. Try again?" == $true) {

                goto start
        }
}

;-----------Copy File--------------------------

on *:DIALOG:z.commander:sclick:19: {

        :start

        var %dest $?="Copy to..."
        run cmd /Q /C xcopy $selfile(path) %dest /E /C /G /H /Y

        status $selfile(path)) moved to %dest

        did -d z.commander 12 $did(12).sel

        return

        :error

        if ($?!="Invalid destination. Try again?" == $true) {

                goto start
        }
}

;------------Move File-------------------------

on *:DIALOG:z.commander:sclick:20: {

        :start

        var %dest $?="Move to..."
        run cmd /Q /C move /Y $selfile(path) %dest

        status $selfile moved to %dest

        did -d z.commander 12 $did(12).sel

        return

        :error

        if ($?!="Invalid destination. Try again?" == $true) {

                goto start
        }
}

;-----------delete file--------------------

on *:DIALOG:z.commander:sclick:21: {

        remove -b $selfile(path)

        status $selfile(path) moved to trash.

        did -d z.commander 12 $did(12).sel
}

;-----------Load file-------------------

on *:DIALOG:z.commander:sclick:22: {

        .load -rs $selfile(path)

        status Loaded $+($selfile,$chr(44))
}

;---------Open file---------------

on *:DIALOG:z.commander:sclick:23: {

        run $qt($+(%zc.workdir,$did(12, $did(12).sel).text))
}

;-----------Run....----------------------------

on *:DIALOG:z.commander:sclick:25: {

        var %command $?="Run command..."
        run %command

        return

        :error

        status Unknown command: %command
}

;---------Settings button-----------

on *:DIALOG:z.commander:sclick:26: {

        dialog -m z.commander.settings z.commander.settings
}

;----------system aliases----------------------

alias -l ls {

        var %ctime $ctime
        var %switches $1

        if (d isin %switches) {

                clear d
                var %dir.total $finddir(%zc.workdir, %zc.filter, 0, 0)
                did -r z.commander 11
                var %dir.count 1
        }
        if (f isin %switches) {

                clear f
                var %file.total $findfile(%zc.workdir, %zc.filter, 0, 0)
                did -r z.commander 12
                var %file.count 1
        }

        var %main.count 1
        var %main.total %dir.total + %file.total

        while (%main.count <= %main.total) {

                if (%dir.count <= %dir.total) {

                        did -a z.commander $iif(d isin %switches, 11 $nodirpath($finddir(%zc.workdir, %zc.filter, %dir.count, 0)), 12 $nopath($findfile(%zc.workdir, %zc.filter, %file.count, 0)))
                        inc %dir.count
                }

                if (%file.count <= %file.total) {

                        did -a z.commander 12 $nopath($findfile(%zc.workdir, %zc.filter, %file.count, 0))
                        var %size $calc(%size + $file($findfile(%zc.workdir, %zc.filter, %file.count, 0)).size)
                        inc %file.count
                }

                status Listing $+($shortfn(%zc.workdir),...) $perc(%main.count, %main.total)

                inc %main.count
        }

        if (d isin %switches) {

                did -i z.commander 11 1 ..
        }

        if (df isin %switches) {

                did -o z.commander 2 1 $calc(%dir.count - 1) directories, $calc(%file.count - 1) $+(files,$iif(%size > 0, $+($chr(44),$chr(32),$bytes(%size).suf)),.)
        }

        status Listed $+($iif(d isin %switches, $calc(%dir.count - 1) directories),$iif(f isin %switches, $+($chr(44),$chr(32)) $calc(%file.count - 1) files)) in $duration($calc($ctime - %ctime))
}

;-------------------don't try this at home, kids.--------------------
alias -l cd {

        if ($1 != $null) {

                set %zc.workdir $+($remove($replacex($1-,$+($chr(92),$chr(92)),$chr(92)),$chr(34)),$iif($right($1-, 1) != $chr(92),$chr(92)))
                dialog -t z.commander zCommander - %zc.workdir
                ls df
        }

        else {

                unset %zc.workdir
                dialog -t z.commander zCommander - Root
                did -r z.commander 11,12
                getdisk l
                did -o z.commander 2 1 $getdisk(i)
        }
}

alias -l nodirpath {

        return $gettok($1-, -1, 92)
}

alias -l status {

        did -o z.commander 4 1 $1-
}

alias -l perc {

        return $+($round($calc(($1 / $2) * 100), 0),$(%))
}

alias -l getdisk {

        if (l isin $1) {

                var %ctime $ctime
                var %x 1

                while (%x <= $disk(0)) {

                        did -a z.commander 11 $disk(%x).path $disk(%x).label
                        inc %x
                }

                status Listed $calc(%x - 1) drives in $+($duration($calc($ctime - %ctime)),.)
        }

        if (i isin $1) {

                var %x 1

                while (%x <= $disk(0)) {

                        var %disk.free $calc(%disk.free + $disk(%x).free)
                        var %disk.size $calc(%disk.size + $disk(%x).size)
                        inc %x
                }

                return $calc(%x - 1) drives, $+($bytes($calc(%disk.size - %disk.free)),/,$bytes(%disk.size).suf) used, $bytes(%disk.free).suf free.
        }
}

alias -l fileinfo {

        return $+($1,:) $+($bytes($file($2).size).suf,$chr(44)) Last modified: $duration($calc($ctime - $file($2).mtime)) ago.
}

alias -l clear {

        if (d isin $1) {

                did -r z.commander 11
        }

        elseif (f isin $1) {

                did -r z.commander 12
        }
}

alias -l selfile {

        if ($1 == path) {

                return $qt($+(%zc.workdir,\,$did(12, $did(12).sel).text))
        }

        else {

                return $did(12, $did(12).sel).text
        }
}

alias -l seldir {

        if ($1 == path) {

                return $qt($+(%zc.workdir,\,$did(11, $did(11).sel).text))
        }

        else {

                return $did(11, $did(11).sel).text)
        }
}

menu status,menubar,channel {

        .zCommander:/z.commander
}
