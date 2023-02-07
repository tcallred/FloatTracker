# 2023-02-07: runs without TF, error with TF
# ERROR: LoadError: MethodError: no method matching floatmin(::Type{TrackedFloat64})
# Closest candidates are:
#   floatmin() at float.jl:878
#   floatmin(::T) where T<:AbstractFloat at float.jl:852
#   floatmin(::Type{ForwardDiff.Dual{T, V, N}}) where {T, V, N} at ~/.julia/packages/ForwardDiff/pDtsf/src/dual.jl:789
#   ...
# Stacktrace:
#   [1] floatmin2(#unused#::Type{TrackedFloat64})
#     @ LinearAlgebra ~/code/julia/julia-1.8.0/usr/share/julia/stdlib/v1.8/LinearAlgebra/src/givens.jl:67
#   [2] givensAlgorithm(f::TrackedFloat64, g::TrackedFloat64)
#     @ LinearAlgebra ~/code/julia/julia-1.8.0/usr/share/julia/stdlib/v1.8/LinearAlgebra/src/givens.jl:82
#   [...clipped...]

#=
# 1D Poisson, Dirichlet bc
# CG, Linear element
# Simplest test possible
=#

### If the Finch package has already been added, use this line #########
using Finch # Note: to add the package, first do: ]add "https://github.com/paralab/Finch.git"

include("../../src/FloatTracker.jl")
using .FloatTracker: TrackedFloat64, FunctionRef, write_log_to_file, set_inject_nan, set_logger, set_exclude_stacktrace
# fns = []
# TODO why inf loop??!
fns = [FunctionRef(:mesh, Symbol("finch_interface.jl"))]
set_inject_nan(false, 1, 1, fns)
set_logger(filename="tf-poisson")
set_exclude_stacktrace([:prop])

### If not, use these four lines (working from the examples directory) ###
# if !@isdefined(Finch)
#     include("../Finch.jl");
#     using .Finch
# end
##########################################################################

initFinch("poisson1d", TrackedFloat64);
useLog("poisson1dlog", level=3)

# Set up the configuration
domain(1) # dimension

mesh(LINEMESH, elsperdim=180)   # build uniform LINEMESH with 180 elements

u = variable("u")              # make a scalar variable with symbol u
testSymbol("v")                # sets the symbol for a test function

boundary(u, 1, DIRICHLET, 0)  # boundary condition for BID 1 is Dirichlet with value 0

# Write the weak form 
coefficient("f", "-100*pi*pi*sin(10*pi*x)*sin(pi*x) - pi*pi*sin(10*pi*x)*sin(pi*x) + 20*pi*pi*cos(10*pi*x)*cos(pi*x)")
weakForm(u, "-grad(u)*grad(v) - f*v")

# exportCode("poisson1dcode");
# importCode("poisson1dcode");

solve(u);

finalizeFinch()

## exact solution is sin(10*pi*x)*sin(pi*x)
## check error
#allerr = zeros(size(Finch.grid_data.allnodes,2));
#
#for i=1:size(Finch.grid_data.allnodes,2)
#    x = Finch.grid_data.allnodes[1,i];
#    exact = sin(10*pi*x)*sin(pi*x);
#    allerr[i] = abs(u.values[i] - exact);
#end
#maxerr = maximum(abs, allerr);
#println("max error = "*string(maxerr));
#
#### uncomment below to plot ###
#
## # solution is stored in the variable's "values"
## using Plots
## pyplot();
## display(plot(Finch.grid_data.allnodes[:], u.values[:], markershape=:circle, legend=false))

write_log_to_file()
