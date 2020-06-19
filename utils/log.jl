global std = stdout


function lg(minlevel::Int, vals... ;  
            prefix::String="", suffix::String="", doflush=true)
    global args
    if args["verbosity"] >= minlevel
        if !isempty(vals)
            print(prefix, join(vals, ""), suffix)
            doflush && flush(stdout)
        end
        return true
    else
        return false
    end
end


"""
Disables log messages
"""
function stdoff()

    global args
    global std
    std = stdout
    redirect_stdout()

end


"""
Enables log messages
"""
function stdon()

    global args
    global std
    redirect_stdout(std)

end


# functions depending on the verbosity level
lg0(vals...; kwargs... ) = lg(0, vals...; kwargs... )
lg1(vals...; kwargs... ) = lg(1, vals...; kwargs... )
lg2(vals...; kwargs... ) = lg(2, vals...; kwargs... )

ln0(vals...; kwargs... ) = lg(0, vals...; kwargs..., suffix="\n" )
ln1(vals...; kwargs... ) = lg(1, vals...; kwargs..., suffix="\n" )
ln2(vals...; kwargs... ) = lg(2, vals...; kwargs..., suffix="\n" )