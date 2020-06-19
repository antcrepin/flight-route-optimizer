function ms()

    global MS_START
    if ! @isdefined MS_START
        MS_START = time()
    end
    ms = round(Int, 1000*(time() - MS_START))
    return (ms/1000)

end


function ms_reset()

    global MS_START = time()

end


macro ms(cmd)

    cmdstr = string(cmd)
    # information about the file that called this macro
    if isinteractive()
        # interactive mode => no file to call
        fileinfo = "(mode repl)"
    else
        # retrieve the relative name of the file that called this macro
        fname = string(__source__.file)
        fname = fname[length("$APPDIR")+2 : end]
        # retrieve the line number where the macro is called
        fline = string(__source__.line)
        fileinfo = "$(fname):$fline"
    end
     
    quote
        local t0 = time()
        print("@ms START ", round(ms(), digits=3), "s ", $fileinfo, ":", $(cmdstr)) 
        println(" ... ") 
        local val = $(esc(cmd))
        local t1 = time()
        print("@ms END ", round(ms(), digits=3), "s ", $fileinfo, ":", $(cmdstr)) 
        println(" in ", round(t1-t0, digits=3), "s")
        val
    end

end

# start the chronometer
ms()
