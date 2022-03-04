#-- set defaults for the various directories used
#
if {![info exists defaults_are_set]} {
    #-- set this to your folder structure's top directory

    if { $::tcl_platform(platform) == "windows" && $::env(USERNAME) == "jschamba" } {
        set topDir "p:"
        #
        #-- set this to where the top git working dir is
        #
        #set git_dir $topDir
        set git_dir "E:/Users/jschamba/Documents/ALICE/ITS/git/itswp10_devel/itswp10"
        #-- add the path for the git executable
        global env; set env(PATH) "C:/Program Files/Git/bin;$env(PATH)"

        set modelsim_simlib_path C:/modelsim
    } else {
        set scriptDir [file dirname [file normalize [info script]]]
        set topDir [file normalize $scriptDir/../../../../ ]
        set git_dir $scriptDir
    }

    # indicate that the above variables are set
    set defaults_are_set 1
}
