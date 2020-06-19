@ms using JuMP
@ms using MathOptFormat


# import Julia library corresponding to the chosen solver
if args["external_solver"] == "cbc"
    @ms using Cbc
elseif args["external_solver"] == "glpk"
    @ms using GLPK
else
    @ms using CPLEX
end


"""
Creates an empty JuMP optimization model
"""
function new_model(; solver::String = "auto")
    if solver == "auto"
        solver = args["external_solver"]
    end
    if solver == "glpk"
        model = Model(with_optimizer(GLPK.Optimizer))
    elseif solver == "cplex"
        model = Model(with_optimizer(CPLEX.Optimizer))
    elseif solver == "cbc"
        model = Model(with_optimizer(Cbc.Optimizer))
    end
    return model
end