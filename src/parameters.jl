

"""

    seawater(Cl, O)

Returns a NamedTuple with values of chlorinity `Cl` and δ¹⁸O `O`(necessarily `Float64`s). 

see also: [`mcmurdoshelf`](@ref), [`mcmurdosound`](@ref), [`PorewaterDiffusion.Seawater`](@ref)

"""

seawater(Cl::Number,O::Number) = (; Cl=float(Cl), O=float(O))

"""
    Seawater

`DataType` declared as a shorthand for `NamedTuple{(:Cl, :O), Tuple{Float64,Float64}}` because Graham likes the splatting functionality of NamedTuples and structs don't have it!

see also: [`seawater`](@ref)
    
"""
const Seawater = NamedTuple{(:Cl, :O), Tuple{Float64,Float64}}

"""
    mcmurdoshelf()

Generate a [`seawater`](@ref) NamedTuple with coretop porewater compositions from the McMurdo ice shelf. Pairs with core ANDRILL-1B.

see also: [`seawater`](@ref), [`andrill1b`](@ref)

"""
mcmurdoshelf() = seawater(19.2657,-0.33)

"""
    mcmurdosound()

Generate a [`seawater`](@ref) NamedTuple with southern McMurdo Sound seawater compositions. Pair with core ANDRILL-2A.

see also: [`seawater`](@ref), [`andrill2a`](@ref)

"""
mcmurdosound() = seawater(19.81655,-1.0)



"""

    CoreData(z, mCl, σCl, mO, σO)

Returns an  `CoreData` struct with sediment core data formatted for [`porewatermetropolis`](@ref) — `(; z, Cl = (mu, sig), O = (mu, sig))`. Inputs are Vectors for values of sample depths `z` (meters below sea floor), measured (mean) chlorinity `mCl` and 1σ uncertainty `σCl`, and measured (mean) δ¹⁸O `mO` and 1σ uncertainties `σO`. 

Vectors must all be of the same length. If Cl and δ¹⁸O sampling is not 1:1, use `NaN` or anything that is not a subtype of Number (e.g. `missing`, `nothing`). While `NaN` is used internally, `CoreData` does this conversion for you.

---

    CoreData(z, m, σ, measurement)

Same as above, but for a core with only chlorinity or δ¹⁸O data (the other Vectors are empty to return null values in [`log-likelihood`](@ref) calculations). Provide sample depths `z`, measured means `m`, 1σ uncertainties `σ`, and the `measurement` as a symbol, e.g. `:Cl` or `:O`. 

---

`PorewaterDiffusion.jl` comes loaded with convenient functions to generate data for [`andrill2a`](@ref) from Tracy+ 2010 ([doi:10.1130/G30849.1](https://doi.org/10.1130/G30849.1)) and [`andrill1b`](@ref) from Pompilio+ 2007 (https://digitalcommons.unl.edu/andrillrespub/37). 

"""
struct CoreData
    z::Vector{Float64}
    Cl::NamedTuple{(:mu, :sig), Tuple{Vector{Float64}, Vector{Float64}}}
    O::NamedTuple{(:mu, :sig), Tuple{Vector{Float64}, Vector{Float64}}}
end


function CoreData(z::Vector{<:Number}, mCl::AbstractVector, σCl::AbstractVector, μO::AbstractVector, σO::AbstractVector)
    @assert length(z) == length(mCl) == length(σCl) == length(μO) == length(σO)

    @inbounds for i= eachindex(z)
        mCl[i] = ifelse(typeof(mCl[i])<:Number, mCl[i], NaN)
        σCl[i] = ifelse(typeof(σCl[i])<:Number, σCl[i], NaN)
        μO[i] = ifelse(typeof(μO[i])<:Number, μO[i], NaN)
        σO[i] = ifelse(typeof(σO[i])<:Number, σO[i], NaN)
    end

    CoreData(float.(z), (mu=float.(mCl), sig = float.(σCl)), (mu=float.(μO), sig=float.(σO)))
end
function CoreData(z::Vector{<:Number}, m::AbstractVector, σ::AbstractVector, s::Symbol)
    
    @assert length(z) == length(m) == length(σ)
    
    chlorine, oxygen = (:Cl, :CL, :chlorine, :chlorinity), (:O, :oxygen, :water, :d18O, :δ18O, :δ¹⁸O, :d¹⁸O) 
    
    @assert s ∈ (chlorine..., oxygen...)

    @inbounds for i= eachindex(z)
        m[i] = ifelse(typeof(m[i])<:Number, m[i], NaN)
        σ[i] = ifelse(typeof(σ[i])<:Number, σ[i], NaN)
    end
    x = (mu=float.(m), sig = float.(σ))
    xx = Vector{eltype(x.mu)}(undef,0)
    xx = (mu = xx, sig = xx)

    s ∈ chlorine ? CoreData(float.(z), x, xx) : CoreData(float.(z), xx, x)
end


"""

    andrill2a

Generate a [`CoreData`](@ref) instance with data from core ANDRILL-2A (from Tracy+ 2010, [doi:10.1130/G30849.1](https://doi.org/10.1130/G30849.1)). 

see also: [`CoreData`](@ref)

"""
function andrill2a()
    z = [9.67, 30.09, 37.41, 43.72, 51.3, 57.21, 62.66, 73.15, 81.03, 92.97, 116.22, 155.76, 235.66, 293.3, 336.18, 353.53, 545.01, 619.35, 779.69, 809.84, 963.44]

    Clm = (35.45/1000) .* [654, 576, 612, 659, 693, 692, 691, 821, 722, 740, 804, 1117, 1974, 2100, 2303, 2253, 2771, 2728, 2895, 2722, 3091]

    Cls = .03Clm # 3-5 % reported reproducibility. We choose the lower bound given the ±2% precision reported in Pompilio+ 2007.

    Om = [-1.3, -2.7, -5.6, -8.1, -9.8, -10.0, -10.6, -10.3, missing, -10.9, -5.2, -8.5, -9.7, -10.6, -10.2, missing, -9.3, missing, missing, missing, missing]

    Os = fill(0.1, length(Om))

    CoreData(z, Clm,Cls, Om, Os)
end



"""

    andrill1b

Generate a [`CoreData`](@ref) instance with data from core ANDRILL-1B (from Pompilio+ 2007 (https://digitalcommons.unl.edu/andrillrespub/37)). 

see also: [`CoreData`](@ref)

"""
function andrill1b()
    z = [0.,]

    Clm = (35.45/1000) .* [0.,]

    Cls = .02Clm # ±2% precision reported

    Om = @. 30.92 + 1.03092 * [0.] # will need to be converted from carbonate values in vpdb to water values in vsmow. Not too hard, just need to know temperature. 

    # δ18O(VSMOW) = 1.03092 × δ18O(VPDB) + 30.92 # [Kim+ 2015](https://doi.org/10.1016/j.gca.2015.02.011)

    Os = fill(0.1, length(Om)) # based on UCSC isotope lab.

    CoreData(z, Clm,Cls, Om, Os)
end


"""

    PorewaterProperty(n::Int, [, x])

`struct` to contain sediment column poperties at each node for a prior timestep `o` and present timestep `p`.

Constructor function returns an instance of `PorewaterProperty` with vectors of length `n`.  Optionally provide a value `x <: Number` to fill vectors with (otherwise values are undefined). 

"""
struct PorewaterProperty
    o::Vector{Float64}
    p::Vector{Float64}
end

PorewaterProperty(n::Int) = PorewaterProperty(Vector{Float64}(undef,n), Vector{Float64}(undef,n))

function PorewaterProperty(n::Int, x::Number)
    v=fill(float(x),n)
    PorewaterProperty(v,copy(v))
end





"""

    SedimentColumn(n::Int, [, Cl, O])

`struct` to contain `PorewaterProperty`s for the porewater properties of [Cl⁻] (`Cl`), δ¹⁸O (`O`), and density (`rho`).

Constructor function returns an instance of `SedimentColumn` with `PorewaterProperty` vectors of length `n`.  Optionally provide values for `Cl`, `O`, and `rho` (otherwise values are undefined). 

see also: [`PorewaterProperty`](@ref), [`density`](@ref)

"""
struct SedimentColumn
    Cl::PorewaterProperty
    O::PorewaterProperty
    rho::PorewaterProperty
end

SedimentColumn(n::Int) = SedimentColumn(PorewaterProperty(n), PorewaterProperty(n), PorewaterProperty(n))

SedimentColumn(n::Int, c::Number, o::Number) = SedimentColumn(PorewaterProperty(n,c), PorewaterProperty(n,o), PorewaterProperty(n,density(c)))





"""

    LR04()

Generate a NamedTuple instance containing the Liesiecki & Raymo 2004 benthic stack ([data](https://lorraine-lisiecki.com/stack.html), [publication](https://doi.org/10.1029/2004PA001071)) interpolated for 1 ka timesteps and going forward in time from 5.32 Ma. 

| field | description |
| :---- | :---------- | 
| `t`   | time (ka)  |
| `x`   | benthic δ¹⁸O (‰) |
| `n`   | timesteps in `t` |

"""
function LR04()
    a = DelimitedFiles.readdlm(string(@__DIR__,"/../data/LR04-interpolated-1ka.csv"),',')
    @assert a[2,1] - a[1,1] ≈ 1
    t = a[end,1] : -1 : a[1,1]
    x = reverse(a[:,2])
    (; t, x, n=length(t))
end




"""
    ClimateHistory

`DataType` declared as a shorthand for 
    NamedTuple{(:t, :x, :n), Tuple{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int64}, Vector{Float64}, Int64}}
    
The type generated by [`LR04`](@ref), which is used for (perhaps unnecessary) type stability and code readability

see also: [`LR04`](@ref)

"""
ClimateHistory = NamedTuple{(:t, :x, :n), Tuple{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}, Int}, Vector{Float64}, Int}}





"""

```julia
    Constants( ; k, dt, dz, depth )
````

Returns a `Constants` struct containing constants and coefficients used in diffusion history calculations. The inputs and their default values are listed in the table below. From these it calculates a few convenient variables---the product `dt * dz` (`dtdz`), a Range of node depths `z` (in m), the number of nodes `nz`, and the `penultimate_node`---as well as temperature-dependent diffusion coefficients used in `diffusionadvection`, using the temperature-depth paramterization of [Morin+ 2010](https://doi.org/10.1130/GES00512.1). These are returned as Vectors of length `nz`, where each cell corresponds to a depth node in `z`. The two coefficients are `k1` and `k2`, both of which are follwed with `cl` or `w` to denote Cl⁻ or water, respectively: `k1cl`, `k2cl`, `k1w`, and `k2w`.

| field | description | default |
| :---- | :---------- | ----: |
| `k`   | hydraulic conductivity of sediment column | 0.1 m / yr
| `dt` | timestep | 10 yrs |
| `dz` | node spacing | 5 m |
| `depth` | sediment column depth | 2000 m |

"""
struct Constants

    k::Float64
    dz::Float64
    dt::Float64
    depth::Float64
    dtdz::Float64
    z::AbstractRange{Float64}
    nz::Int
    penultimate_node::Int
    k1cl::Vector{Float64}
    k2cl::Vector{Float64}
    k1w::Vector{Float64}
    k2w::Vector{Float64}
end

function Constants(; k::Number=0.1, dt::Number=10., dz::Number=5.,  depth::Number=2000.)

    depth = ifelse( iszero(depth % dz), depth, depth - depth % dz)

    k, dz, dt = float.((k, dz, dt))

    z = 0.0 : dz : depth
    depth=last(z)
    nz = length(z)

    T = @. (0.0767 * z ) + 270.75  # Morin et al. 2010 || in K  (270.75  = 273.15 - 2.4)
    κCl = @. exp(3.8817 - (2.2854e3 / T)) # m² / yr
    κwater = @. exp(4.2049 - ( 2.2699e3 / T)) # m² / yr

    k1cl = κCl .* (dt / (dz * dz))
    k1w = κwater  .* (dt / (dz * dz))

    k2cl = Vector{eltype(T)}(undef,nz)
    k2w = similar(k2cl)
    k2w[1] = k2cl[1] = zero(eltype(T))

    @inbounds for i = 2:nz
        x = dt / dz
        k2cl[i] = (κCl[i] - κCl[i-1]) * x
        k2w[i] = (κwater[i] - κwater[i-1]) * x 
    end

    Constants(k, dz, dt, depth, dt*dz, z, nz, nz-1, k1cl, k2cl, k1w, k2w)
end 


"""

    Proposals(onset, dfrz, dmlt, sea2frz, frz2mlt)

Immutable struct to hold proposed parameters. 

| field | description | units |
| :---- | :---------- | :----
|`onset`| onset of model | ka |
| `dfrz`| freezing rate | m/yr |
| `dmlt`| melting rate | m/yr |
| `sea2frz` | Benthic δ¹⁸O threshold for subglacial freezing | ‰ |
| `frz2mlt` | Benthic δ¹⁸O threshold for subglacial melting | ‰ |

"""
struct Proposal
    onset::Float64
    dfrz::Float64
    dmlt::Float64
    sea2frz::Float64
    frz2mlt::Float64
end


function update(x::Proposal, f::Symbol,v::Number)

    o = ifelse(f==:onset, v, x.onset)
    df = ifelse(f==:dfrz, v, x.dfrz)
    dm = ifelse(f==:dmlt, v, x.dmlt)
    s = ifelse(f==:sea2frz, v, x.sea2frz)
    f = ifelse(f==:frz2mlt, v, x.frz2mlt)
    
    Proposal(o,df,dm,s,f)
end





"""
    getproposal(p, s)

Returns the value corresponding to field the field of Symbol `s` in [`Proposal`](@ref) instance `p`. Use in lieu of `getproperty` to avoid allocations. 

"""
function getproposal(x::Proposal,f::Symbol)
    y=0.
    y = ifelse(f==:onset, x.onset,y)
    y = ifelse(f==:dfrz, x.dfrz, y)
    y = ifelse(f==:dmlt, x.dmlt, y)
    y = ifelse(f==:sea2frz, x.sea2frz, y)
    y = ifelse(f==:frz2mlt, x.frz2mlt, y)
    y
end