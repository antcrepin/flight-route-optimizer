"""
Solver data structure definition
"""
mutable struct Solver

    inst::Instance # instance to solve
    master::Model # master problem model
    sub::Model # subproblem model
    sol::Solution # corresponding solution

    """
    Solver object builder
    """
    function Solver(inst::Instance)

        this = new()
        this.inst = inst
        this.sol =  Solution(inst)
        return this

    end 
    
end


"""
Generates and initializes the optimization model corresponding to the master problem
"""
function generate_master_model!(sv::Solver; relax_integrality::Bool = false)

    sv.master = new_model()

    # advanced constraint generation
    if args["method"] == "adv-constr-gen"

        # declaration of variables
        if relax_integrality
            @variable(sv.master, 0 <= x[a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])] <= 1)
            @variable(sv.master, 0 <= t[1:sv.inst.n] <= 1)
        else
            @variable(sv.master, x[a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])], Bin)
            @variable(sv.master, t[1:sv.inst.n], Bin)
        end

        # declaration of the objective function
        @expression(sv.master, distance, sum(sv.inst.D[a]*x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])))
        @objective(sv.master, Min, distance)

        # declaration of constraints
        @constraint(sv.master,
            force_artificial_arc,
            x[(sv.inst.F, sv.inst.I)] == 1)
        @constraint(sv.master,
            minimum_visited_airdromes,
            sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])) >= sv.inst.k)
        @constraint(sv.master,
            unique_visit[i in 1:sv.inst.n],
            sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)]) if a[1] == i)
            + sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)]) if a[2] == i) == 2*t[i])
        @constraint(sv.master,
            touch_and_go[i in 1:sv.inst.n],
            sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)]) if a[1] == i)
            - sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)]) if a[2] == i) == 0)
        @constraint(sv.master,
            geographical_diversity[r in 1:sv.inst.m],
            sum(x[a] for a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)]) if sv.inst.R[a[1]] == r || sv.inst.R[a[2]] == r) >= 1)

    else
        # declaration of variables
        if relax_integrality
            @variable(sv.master, 0 <= x[a in sv.inst.feasible_arcs] <= 1)
        else
            @variable(sv.master, x[a in sv.inst.feasible_arcs], Bin)
        end

        if args["method"] == "sequential"
            @variable(sv.master, u[1:sv.inst.n] >= 0)

        elseif args["method"] == "single-flow"
            @variable(sv.master, q[a in sv.inst.feasible_arcs] >= 0)
            if relax_integrality
                @variable(sv.master, 0 <= φ[1:sv.inst.n] <= 1)
            else
                @variable(sv.master, φ[1:sv.inst.n], Bin)
            end
        end

        # declaration of the objective function
        @expression(sv.master, distance, sum(sv.inst.D[a]*x[a] for a in sv.inst.feasible_arcs))
        @objective(sv.master, Min, distance)

        # declaration of constraints
        @constraint(sv.master,
            minimum_visited_airdromes,
            sum(x[a] for a in sv.inst.feasible_arcs) >= sv.inst.k-1)
        @constraint(sv.master,
            unique_visit[i in 1:sv.inst.n],
            sum(x[a] for a in sv.inst.feasible_arcs if a[1] == i) + sum(x[a] for a in sv.inst.feasible_arcs if a[2] == i) <= 2)
        @constraint(sv.master,
            touch_and_go[i in 1:sv.inst.n],
            sum(x[a] for a in sv.inst.feasible_arcs if a[1] == i)
            - sum(x[a] for a in sv.inst.feasible_arcs if a[2] == i) == Int(i == sv.inst.I) - Int(i == sv.inst.F))
        @constraint(sv.master,
            geographical_diversity[r in 1:sv.inst.m],
            sum(x[a] for a in sv.inst.feasible_arcs if sv.inst.R[a[1]] == r || sv.inst.R[a[2]] == r) >= 1)
        
        if args["method"] == "sequential"
            @constraint(sv.master,
                increasing_order_of_visit[a in sv.inst.feasible_arcs],
                u[a[2]] - u[a[1]] + sv.inst.n*(1-x[a]) >= 1)

        elseif args["method"] == "single-flow"
            @constraint(sv.master,
                flow_limitation[a in sv.inst.feasible_arcs],
                (sv.inst.n-1)*x[a] - q[a] >= 0)
            @constraint(sv.master,
                total_flow,
                sum(q[a] for a in sv.inst.feasible_arcs if a[1] == sv.inst.I) - sum(φ[i] for i in setdiff(1:sv.inst.n, sv.inst.I)) == 0)
            @constraint(sv.master,
                flow_conservation[i in setdiff(1:sv.inst.n, sv.inst.I)],
                sum(q[a] for a in sv.inst.feasible_arcs if a[2] == i) - sum(q[a] for a in sv.inst.feasible_arcs if a[1] == i) - φ[i] == 0)
            @constraint(sv.master,
                virtual_demand[i in setdiff(1:sv.inst.n, sv.inst.I)],
                sum(x[a] for a in sv.inst.feasible_arcs if a[2] == i) - φ[i] == 0)
        end
    end

end


"""
Generates and initializes the optimization model corresponding to the subproblem
"""
function generate_sub_model!(sv::Solver; relax_integrality::Bool = false)

    sv.sub = new_model()

    # declaration of variables
    if relax_integrality
        @variable(sv.sub, 0 <= z[1:sv.inst.n] <= 1)
    else
        @variable(sv.sub, z[1:sv.inst.n], Bin)
    end

    @constraint(sv.sub, non_empty_subset, sum(z[i] for i in 1:sv.inst.n) >= 1)

    # advanced constraint generation
    if args["method"] == "adv-constr-gen"
        @variable(sv.sub, y[a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])] >= 0)

        # declaration of constraints
        @constraint(sv.sub,
            linearization1[a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])],
            y[a] - z[a[1]] <= 0)
        @constraint(sv.sub,
            linearization2[a in union(sv.inst.feasible_arcs, [(sv.inst.F, sv.inst.I)])],
            y[a] - z[a[2]] <= 0)
        
        # dummy constraint that will be updated
        sv.sub[:pivot] = @constraint(sv.sub, 0 <= 1)

    # standard constraint generation
    else
        @variable(sv.sub, y[a in sv.inst.feasible_arcs] >= 0)

        # declaration of constraints
        @constraint(sv.sub,
            linearization1[a in sv.inst.feasible_arcs],
            y[a] - z[a[1]] <= 0)
        @constraint(sv.sub,
            linearization2[a in sv.inst.feasible_arcs],
            y[a] - z[a[2]] <= 0)
        @constraint(sv.sub,
            linearization3[a in sv.inst.feasible_arcs],
            z[a[1]] + z[a[2]] - y[a] <= 1)
    end

end


"""
Updates the subproblem model by adding a subtour elimination constraint
"""
function add_subtour_constraint!(sv::Solver, z_cur::Dict{Int, Int}, nb_added_subtours::Int, p::Union{Int, Nothing} = nothing)

    # standard constraint generation
    if args["method"] == "std-constr-gen"  
        sv.master[Symbol("subtour$(nb_added_subtours)")] = @constraint(sv.master,
            sum(sv.master[:x][a] for a in sv.inst.feasible_arcs if z_cur[a[1]] == 1 && z_cur[a[2]] == 1) - sum(z_cur[i] for i in 1:sv.inst.n) + 1 <= 0)

    # advanced constraint generation
    else
        sv.master[Symbol("subtour$(nb_added_subtours)")] = @constraint(sv.master,
            sum(sv.master[:x][a] for a in sv.inst.feasible_arcs if z_cur[a[1]] == 1 && z_cur[a[2]] == 1 && a[1] != sv.inst.I && a[2] != sv.inst.I)
            - sum(sv.master[:t][i] for i in setdiff(1:sv.inst.n, Set([p, sv.inst.I])) if z_cur[i] == 1) <= 0)
    end
end


"""
Updates the subproblem model's objective using the current solution of the master problem
"""
function update_sub_model_objective!(sv::Solver, x_cur::Dict{Tuple{Int, Int}, Float64}, t_cur::Union{Dict{Int, Float64}, Nothing} = nothing, p::Union{Int, Nothing} = nothing)

    # standard constraint generation
    if args["method"] == "std-constr-gen"
        sv.sub[:violation] = @expression(sv.sub, sum(x_cur[a]*sv.sub[:y][a] for a in sv.inst.feasible_arcs) - sum(sv.sub[:z][i] for i in 1:sv.inst.n) + 1)
    
    # advanced constraint generation
    else
        sv.sub[:violation] = @expression(sv.sub,
            sum(x_cur[a]*sv.sub[:y][a] for a in sv.inst.feasible_arcs if a[1] != sv.inst.I && a[2] != sv.inst.I)
            - sum(t_cur[i]*sv.sub[:z][i] for i in 1:sv.inst.n if i != p && i != sv.inst.I))
    end

    @objective(sv.sub, Max, sv.sub[:violation])

end


"""
(Advanced constraint generation ONLY) Updates the pivot p in the subproblem model
"""
function update_sub_model_pivot_constraint!(sv::Solver, p::Int)

    delete(sv.sub, sv.sub[:pivot])
    sv.sub[:pivot] = @constraint(sv.sub, sv.sub[:z][p] == 1)

end


"""
Runs the optimization
"""
function solve!(sv::Solver)

    # non-iterative methods => single MILP to solve
    if args["method"] == "sequential" || args["method"] == "single-flow"
        generate_master_model!(sv)
        if args["verbosity"] == 0
            stdoff()
        end
        optimize!(sv.master)
        if args["verbosity"] == 0
            stdon()
        end
        ln1("")

    # standard constraint generation
    elseif args["method"] == "std-constr-gen"
        nb_added_subtours = 0
        x_cur = Dict{Tuple{Int, Int}, Float64}()
        z_cur = Dict{Int, Int}()
        generate_master_model!(sv)
        generate_sub_model!(sv)

        while true
            # solve the master problem
            stdoff()
            optimize!(sv.master)
            stdon()
            ln1("Iteration n°$(nb_added_subtours+1) ($(nb_added_subtours) subtour constraints generated so far)")
            ln1("Master objective value: $(value(sv.master[:distance]))")

            # retrieve the solution and update the subproblem model
            for a in sv.inst.feasible_arcs
                x_cur[a] = value(sv.master[:x][a])
            end
            update_sub_model_objective!(sv, x_cur)

            # solve the subproblem
            stdoff()
            optimize!(sv.sub)
            stdon()
            ln2("Subproblem objective value: $(value(sv.sub[:violation]))")
            ln1("")

            # while loop stops where there is no more subtour
            if value(sv.sub[:violation]) <= 1e-8
                break
            end

            # if there is a subtour, update the master problem model
            nb_added_subtours += 1
            for i in 1:sv.inst.n
                z_cur[i] = round(Int, value(sv.sub[:z][i]))
            end
            add_subtour_constraint!(sv, z_cur, nb_added_subtours)
        end

    # advanced constraint generation
    else
        nb_iterations = 0
        nb_added_subtours = 0
        added_subtours_history = Tuple{Int, Dict{Int, Int}}[]
        x_cur = Dict{Tuple{Int, Int}, Float64}()
        t_cur = Dict{Int, Float64}()
        z_cur = Dict{Int, Int}()
        generate_sub_model!(sv, relax_integrality = true)

        # two steps: 1. LP master 2. MILP master
        for master_relax_state in [true, false]
            generate_master_model!(sv, relax_integrality = master_relax_state)

            if !master_relax_state
                ln1("> Phase 2: MILP master problem")
                # when starting Step 2, add all the constraints added during Step 1
                for st in 1:nb_added_subtours
                    add_subtour_constraint!(sv, added_subtours_history[st][2], st, added_subtours_history[st][1])
                end
            else
                ln1("> Phase 1: LP master problem")
            end

            while true
                nb_iterations += 1

                # solve the master problem
                stdoff()
                optimize!(sv.master)
                stdon()
                ln1("Iteration n°$(nb_iterations) ($(nb_added_subtours) subtour constraints generated so far)")
                ln1("Master objective value: $(value(sv.master[:distance]))")

                # retrieve the solution and update the subproblem model
                for a in sv.inst.feasible_arcs
                    x_cur[a] = value(sv.master[:x][a])
                end
                for i in 1:sv.inst.n
                    t_cur[i] = value(sv.master[:t][i])
                end

                # for each possible pivot, solve a subproblem
                found_new_subtour = false
                for p in setdiff(1:sv.inst.n, sv.inst.I)
                    update_sub_model_pivot_constraint!(sv, p)
                    update_sub_model_objective!(sv, x_cur, t_cur, p)

                    # solve the subproblem
                    stdoff()
                    optimize!(sv.sub)
                    stdon()
                    ln2("Subproblem with p = $p objective value: $(value(sv.sub[:violation]))")
                    if value(sv.sub[:violation]) >= 1e-8
                        nb_added_subtours += 1
                        for i in 1:sv.inst.n
                            z_cur[i] = round(Int, value(sv.sub[:z][i]))
                        end
                        # keep track of subtours detected during Step 2 (needed to initialize Step 2)
                        if master_relax_state
                            push!(added_subtours_history, (copy(p), copy(z_cur)))
                        end
                        add_subtour_constraint!(sv, z_cur, nb_added_subtours, p)
                        found_new_subtour = true
                    end
                end
                ln1("")

                # while loop stops where there is no more subtour
                if !found_new_subtour
                    break
                end
            end
        end
    end

    # save the solution
    save_solution!(sv)
end


"""
Saves the solution as a Solution object
"""
function save_solution!(sv)

    # in advanced constraint generation, the arc (F,I) is fictive and must be ignored
    if args["method"] == "adv-constr-gen"
        sv.sol.score = value(sv.master[:distance]) - sv.inst.D[(sv.inst.F, sv.inst.I)]
    else
        sv.sol.score = value(sv.master[:distance])
    end

    # save selection rate for each feasible arc
    for a in sv.inst.feasible_arcs 
        sv.sol.arc_selection[a] = min(max(0, value(sv.master[:x][a])), 1)
    end

    # in advanced constraint generation, the arc (F,I) is fictive and must be ignored
    if (sv.inst.F, sv.inst.I) in sv.inst.feasible_arcs
        sv.sol.arc_selection[(sv.inst.F, sv.inst.I)] = 0
    end

end