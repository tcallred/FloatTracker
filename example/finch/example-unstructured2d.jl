#=
# Import a simple triangle or quad mesh from a .msh file.
=#

### If the Finch package has already been added, use this line #########
using Finch # Note: to add the package, first do: ]add "https://github.com/paralab/Finch.git"

include("../../src/FloatTracker.jl")
using .FloatTracker: TrackedFloat64, write_log_to_file, set_inject_nan, set_logger, set_exclude_stacktrace
fns = []
set_inject_nan(true, 1, 1, fns)
set_logger("tf-unstructured", 5)
set_exclude_stacktrace([:prop])

### If not, use these four lines (working from the examples directory) ###
# if !@isdefined(Finch)
#     include("../Finch.jl");
#     using .Finch
# end
##########################################################################

init_finch("unstruct2dtest");

useLog("unstruct2dlog", level=3)

domain(2, grid=UNSTRUCTURED)
functionSpace(order=2)

# This rectangle covers [0, 0.1]x[0, 0.3]
# Uncomment the desired mesh.
mesh("utriangle.msh")  # Using triangles
#mesh("uquad.msh")     # Using quads

u = variable("u")
testSymbol("v")

boundary(u, 1, DIRICHLET, 0)

coefficient("f", "(-10-(x+1)*200*pi*pi)*sin(10*pi*x)*sin(10*pi*y) + 10*pi*cos(10*pi*x)*sin(10*pi*y)")
coefficient("k", "x+1")
coefficient("C", "10")
weakForm(u, "k*dot(grad(u), grad(v)) + C*u*v+ f*v")

solve(u);

finalize_finch();

# exact solution is sin(10*pi*x)*sin(10*pi*y)
# check error
maxerr = 0;
exact(x,y) = sin(10*pi*x)*sin(10*pi*y);

for i=1:size(Finch.grid_data.allnodes,2)
    x = TrackedFloat64(Finch.grid_data.allnodes[1,i]);
    y = TrackedFloat64(Finch.grid_data.allnodes[2,i]);
    err = abs(u.values[i] - exact(x,y));
    global maxerr;
    maxerr = max(err,maxerr);
end
println("max error = "*string(maxerr));
write_log_to_file()
