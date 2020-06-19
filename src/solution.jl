"""
Solution data structure definition
"""
mutable struct Solution

    arc_selection::Dict{Tuple{Int, Int}, Float64} # selection rate of the arcs 
    inst::Instance # corresponding instance
    score::Float64 # objective value

    """
    Solution object builder
    """
    function Solution(inst::Instance)
        
        this = new()

        # initialization of the containers which will be filled dynamically
        this.arc_selection = Dict{Tuple{Int, Int}, Float64}()

        this.inst = inst
        return this

    end 

end


"""
Prints the solution
"""
function pprint(sol::Solution)

    ln0()
    ln0("Score: $(sol.score)")
    ln0()
    ln0("Selected arcs:")
    for a in sol.inst.feasible_arcs
        if sol.arc_selection[a] >= 1e-8
            ln0("$(a[1]) $(a[2]) => $(sol.arc_selection[a])")
        end
    end

end


"""
Exports the solutions as a .sol file
"""
function export_to_file(sol::Solution)

    open("solutions/$(sol.inst.name)_cost=$(round(Int, sol.score)).sol", "w") do out
        redirect_stdout(out) do
            println(round(Int, sol.score))
            println()
            for a in sol.inst.feasible_arcs
                if sol.arc_selection[a] >= 1e-8
                    println("$(a[1]) $(a[2])")
                end
            end
        end
    end

end