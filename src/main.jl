# import log functions
@ms include("$APPDIR/utils/log.jl")

# read command line arguments
@ms include("$APPDIR/src/args.jl")
@ms global args = parse_commandline()

# import all routines
@ms include("$APPDIR/src/jump_model.jl")
@ms include("$APPDIR/src/instance.jl")
@ms include("$APPDIR/src/solution.jl")
@ms include("$APPDIR/src/solver.jl")


"""
Main function
"""
function main()

    # print active parameters
    display_active_args()

    ln0("\n=================== Start MAIN() =================\n")
    # clock time at the beginning (in s)
    t_begin = time()

    inst = Instance()
    sv = Solver(inst)
    solve!(sv)
    pprint(sv.sol)
    export_to_file(sv.sol)

    # total elapsed time of the MAIN
    sec = round((time() - t_begin), digits=3) 
    ln0("\nTotal elapsed time MAIN():\t$(sec)s")
    ln0("\n==================== End MAIN() ==================\n")

end