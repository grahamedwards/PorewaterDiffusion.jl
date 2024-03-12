# Diffusion functions and support
# boundaryconditions
# 



"""

```julia
function boundaryconditions(Cl, d18O, x, sea2freeze,freeze2melt, meltrate, freezerate, Clsw, d18Osw, dz, dt)
```
Calculates sediment surface boundary condition for δ¹⁸O (`d18O`) and chloridity (`Cl`), based on the thermodynamic state described by the current current benthic δ¹⁸O value `x` and the threshold values corresponding to subglacial freezing `sea2freeze` and subglacial melting `freeze2melt`.

For melting or freezing states, calculates boundary condition from the assumed `meltrate`, `freezerate`, timestep `dt`, length-step `dt`, and composition of seawater `Clsw` and `d18Osw`.

"""
function boundaryconditions(Cl::Float64, d18O::Float64, x, sea2freeze, freeze2melt, meltrate, freezerate, Clsw, d18Osw, dz, dt)
    
    if x < sea2freeze # low δ18O -> warm -> seawater
        Cl, d18O = Clsw, d18Osw

    elseif x > freeze2melt # high δ18O -> cold -> warm-based
        ϕdz = 0.4dz
        melt = meltrate * dt
        
        Cl *= ϕdz / (ϕdz + melt)
        d18O = (d18O * ϕdz - 40melt) / (ϕdz+melt)
    
    else # mid δ18O -> mid temps -> cold-based
        ϕdz = 0.4dz # scaled for porosity
        frz = freezerate*dt
    
        Cl *= ϕdz / (ϕdz - frz) 
        d18O +=  1.59 * log(1 - (frz / ϕdz)) # simplified from eqn 2 of Toyota et al. (2017)
    end
    
    (Cl, d18O, density(Cl))
end



"""

    diffusionadvection(x,above,below,k1,k2,v,dt,dz)

Calculate the property of a node in a vertical profile given the combined effects of diffusion and advection. Returns the property given initial values for the node `x`, the overlying node `above`, the underlying node `below`, (`dt`/`dz`-scaled) diffusion coefficients `k1` and `k2`, vertical advection velocity `v`, timestep `dt`, and lengthstep `dz`. Alternatively provide the product of `v * dt * dz` for a minor speed-up.

"""
diffusionadvection(x,above,below,k1,k2,v,dt,dz) = x + k1 * (above - 2x + below) + k2 * (above - x) - (v*dt*dz) * (x - above)

diffusionadvection(x,above,below,k1,k2,vdtdz) = x + k1 * (above - 2x + below) + k2 * (above - x) - vdtdz * (x - above)


"""

    diffusion(x,above,below,k)

Calculate the property of a node in a vertical profile given the effect of diffusion, alone. Returns the property given initial values for the node `x`, the overlying node `above`, the underlying node `below`, and (`dt`/`dz`²-scaled) diffusion coefficient `k`.

"""
diffusion(x,above,below,k) = x + k * (above - 2x + below)


"""

    density(chlorinity)

Calculates the density of a water parcel with `chlorinity` in units g/m³ (rather than kg/m³ for convenience with `velocity`)

see also: [`velocity`](@ref)

"""
density(chlorinity) = (chlorinity * 0.0018) + 1





"""

    velocity(x, above, k)

Calculate the velocity (m/yr) at a node with density `x`, given the density of the node `above`, and the hydraulic conductivity `k` (m/yr).

see also: [`density`](@ref)

"""
velocity(x, above, k) = ifelse(above < x, zero(x), k * (above - x) / x)




"""

```julia
diffuseadvectcolumn!(sc, k, flr)
```

Calculate diffusive and advective transport of chlorinity and isotope-traced water through a sediment column described by properties in `k`, a NamedTuple generated by the [`Constants`](@ref) function.

Overwrites the `o` and `p` PorewaterProperty fields of `sc` -- a [`SedimentColumn`](@ref) with pre-existing conditions of `Cl`, `O`, and `rho` in its `o` fields.

relies on: [`velocity`](@ref), [`density`](@ref), [`diffusionadvection`](@ref), 

see also: [`SedimentColumn`](@ref), [`Constants`](@ref) 

"""
function diffuseadvectcolumn!(sc::SedimentColumn, k::Constants, flr::Float64)

    iflr = round(Int, flr / k.dz + 1)
    iflr = ifelse(iflr >= k.nz, k.penultimate_node, iflr) # make sure iflr is no deeper than the penultimate node. 
    iflr -= ifelse(k.z[iflr] > flr, 1,0)

    sc.Cl.p[1] = sc.Cl.o[1]
    sc.O.p[1] = sc.O.o[1]

    @inbounds @simd for i = 2:iflr

        above = i-1
        below = i+1

        vdtdz = velocity(sc.rho.o[i], sc.rho.o[above],k.k) * k.dtdz

        sc.Cl.p[i] = diffusionadvection(sc.Cl.o[i],sc.Cl.o[above], sc.Cl.o[below], k.k1cl[i], k.k2cl[i], vdtdz) 

        sc.rho.p[i] = density(sc.Cl.p[i])

        sc.O.p[i] = diffusionadvection(sc.O.o[i],sc.O.o[above], sc.O.o[below], k.k1w[i], k.k2w[i], vdtdz) 
    end

# And time steps forward, replacing o with p.
    sc.O.o .= sc.O.p
    sc.Cl.o .= sc.Cl.p
    sc.rho.o .= sc.rho.p
    
end



"""

```julia
equilibratecolumn!(sc, seawater, basalwater, z, flr)
```

Calculate an equilibrium linear profile for all SedimentColumn vectors in `sc` between a seafloor `seawater` and `basalwater` composition, given node depths `z` and diffusion-dominated column depth `flr`.

"""
function equilibratecolumn!(sc::SedimentColumn, seawater::Water,basalwater::Water, z::StepRangeLen, flr::Float64)

    mO = (basalwater.O - seawater.O) / flr
    mCl = (basalwater.Cl - seawater.Cl) / flr

    @inbounds @simd for i = eachindex(z)
        zi = z[i]
        zcl = ifelse(zi > flr, basalwater.Cl, mCl * zi + seawater.Cl)
        sc.Cl.p[i] = sc.Cl.o[i] = zcl
        sc.O.p[i] =  sc.O.o[i] = ifelse(zi > flr, basalwater.O, mO * zi + seawater.O)
        sc.rho.p[i] = sc.rho.o[i] = density(zcl)
    end
    
    mO,mCl
end