@ms using LinearAlgebra

"""
Instance data structure definition
"""
mutable struct Instance

    name::String # name of the instance

    n::Int # number of airdromes
    I::Int # departure airdrome
    F::Int # arrival airdrome
    k::Int # minimum number of airdromes to be visited
    m::Int # total number of groups
    R::Array{Int} # association airdrome-group
    coordinates::Array{Tuple{Int, Int}} # geographical coordinates of the airdromes
    D::Dict{Tuple{Int, Int}, Int} # rounded distance between the airdromes
    Δ::Int # maximum distance that can be traveled without landing to refuel
    feasible_arcs::Set{Tuple{Int, Int}} # feasible arcs regarding the threshold distance Δ

    """
    Instance object builder
    """
    function Instance() 

        this = new()

        # initialization of the containers which will be filled dynamically
        this.R = Int[]
        this.coordinates = Tuple{Int, Int}[]
        this.D = Dict{Tuple{Int, Int}, Int}()
        this.feasible_arcs = Set{Tuple{Int, Int}}()

        # read data from the input file
        read_input_file!(this, args["input"])

        # compute integer distances using from coordinates and update the feasible arcs set
        compute_arc_weights!(this)

        return this

    end 

end


"""
Input file reader
"""
function read_input_file!(inst::Instance, path::String)

    # the name of the instance is the name of the file
    base, ext = splitext(basename(path))
    inst.name = base

    # collect lines
    lines = readlines(path)

    # read data 

    inst.n = parse(Int, lines[1])
    inst.I = parse(Int, lines[2])
    inst.F = parse(Int, lines[3])
    inst.k = parse(Int, lines[4])
    inst.m = parse(Int, lines[5])

    for r in split(lines[7])
        push!(inst.R, parse(Int, r))
    end

    inst.Δ = parse(Int, lines[9])

    for i in 11:10+inst.n
        x_str, y_str = split(lines[i])
        push!(inst.coordinates, (parse(Int, x_str), parse(Int, y_str)))
    end

end


"""
Computes the weight of each arc and concludes on their feasibility
"""
function compute_arc_weights!(inst::Instance)

    for i in 1:inst.n
        for j in i+1:inst.n # we use the symmetry of the distance
            
            # compute distance using LinearAlgebra
            inst.D[(i, j)] = round(Int, norm(inst.coordinates[i].-inst.coordinates[j]))
            inst.D[(j, i)] = inst.D[(i, j)]

            # conclude on the feasibility of the arc
            if inst.D[(i, j)] <= inst.Δ
                push!(inst.feasible_arcs, (i,j), (j,i))
            end

        end
    end

end