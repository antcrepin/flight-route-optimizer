global const APPDIR = dirname(dirname(realpath(@__FILE__())))
@show APPDIR

# @ms() macro
include("$APPDIR/utils/time.jl")

# import and execute
@ms include("$APPDIR/src/main.jl")
main()