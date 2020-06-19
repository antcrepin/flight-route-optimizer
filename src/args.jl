using ArgParse
global args

"""
Parses the arguments given by the user
"""
function parse_commandline()

    settings = ArgParseSettings()

    # define arguments (type, description, default value)
    @add_arg_table! settings begin
        "--external_solver", "-x"
            help = "External solver: \"cbc\", \"cplex\" or \"glpk\""
            arg_type = String
            default = "cplex"

        "--input", "-i"
            help = "Instance file path"
            arg_type = Union{Nothing,String}
            default = "data/n20_3.txt"

        "--method", "-m"
            help = "Solution method: \"sequential\", \"single-flow\", \"std-constr-gen\" or \"adv-constr-gen\""
            arg_type = String
            default = "single-flow"

        "--verbosity", "-v"
            help = "Verbosity level"
            arg_type = Int
            default = 1
    end

    parsed_args = parse_args(settings)

    # check validity of arguments
    if !(parsed_args["external_solver"] in ["cbc", "cplex", "glpk"])
        error("Unexpected value for --external_solver: $(parsed_args["external_solver"])")
    elseif !(parsed_args["input"] === nothing) && !isfile(parsed_args["input"])
        error("Invalid path for --input: $(parsed_args["infile"])")
    elseif !(parsed_args["method"] in ["sequential", "single-flow", "std-constr-gen", "adv-constr-gen"])
        error("Unexpected value for --method: $(parsed_args["method"])")
    end

    return parsed_args

end


"""
Outputs the active parameters
"""
function display_active_args()
    ln0("\n========= Active parameters =========\n")
    global args
    for arg in args
        if arg[1] in ["method", "input"]
            ln0("\t$(arg[1])\t\t= $(arg[2])")
        else
            ln0("\t$(arg[1])\t= $(arg[2])")
        end
    end
end