var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = PorewaterDiffusion","category":"page"},{"location":"#PorewaterDiffusion","page":"Home","title":"PorewaterDiffusion","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for PorewaterDiffusion.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [PorewaterDiffusion]","category":"page"},{"location":"#PorewaterDiffusion.PorewaterProperty","page":"Home","title":"PorewaterDiffusion.PorewaterProperty","text":"PorewaterProperty(n::Int, [, x])\n\nstruct to contain sediment column poperties at each node for a prior timestep o and present timestep p.\n\nConstructor function returns an instance of PorewaterProperty with vectors of length n.  Optionally provide a value x <: Number to fill vectors with (otherwise values are undefined). \n\n\n\n\n\n","category":"type"},{"location":"#PorewaterDiffusion.SedimentColumn","page":"Home","title":"PorewaterDiffusion.SedimentColumn","text":"SedimentColumn(n::Int, [, Cl, O])\n\nstruct to contain PorewaterPropertys for the porewater properties of Cl⁻, δ¹⁸O (O), and density (rho).\n\nConstructor function returns an instance of SedimentColumn with PorewaterProperty vectors of length n.  Optionally provide values for Cl, O, and rho (otherwise values are undefined). \n\nsee also: PorewaterProperty, density\n\n\n\n\n\n","category":"type"},{"location":"#PorewaterDiffusion.AND1B-Tuple{}","page":"Home","title":"PorewaterDiffusion.AND1B","text":"AND1B()\n\nGenerate a Seawater instance with coretop values of ANDRILL-1B.\n\nsee also: Seawater\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.AND2A-Tuple{}","page":"Home","title":"PorewaterDiffusion.AND2A","text":"AND2A()\n\nGenerate a Seawater instance with coretop values of ANDRILL-2A.\n\nsee also: Seawater\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.LR04-Tuple{}","page":"Home","title":"PorewaterDiffusion.LR04","text":"LR04()\n\nLoad a NamedTuple containing the Liesiecki & Raymo 2004 benthic stack (data, publication) interpolated for 1 ka timesteps and going forward in time from 5.32 Ma. \n\nfield description\nt time (ka)\nx benthic δ¹⁸O (‰)\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.boundaryconditions-NTuple{11, Any}","page":"Home","title":"PorewaterDiffusion.boundaryconditions","text":"function boundaryconditions(Cl, d18O, x, ocean2freeze,freeze2melt, meltrate, freezerate, seawater, dz, dt)\n\nCalculates sediment surface boundary condition for δ¹⁸O (d18O) and Cl⁻, based on the thermodynamic state described by the current current benthic δ¹⁸O value x and the threshold values corresponding to subglacial freezing ocean2freeze and subglacial melting freeze2melt.\n\nFor melting or freezing states, calculates boundary condition from the assumed meltrate, freezerate, timestep dt, length-step dt, and composition of seawater Clsw and d18Osw.\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.constants-Tuple{}","page":"Home","title":"PorewaterDiffusion.constants","text":"julia     constants( ; k, dt, dz, depth )`\n\nReturns a NamedTuple of constants and coefficients used in diffusion history calculations. The input constants and their default values are listed in the table below. From these it calculates a few convenience variables: the number of nodes nz, a range of interiornodes,  and the product dtdz. \n\nUsing the constants, it calculates the number of nodes  as well as temperature-dependent diffusion coefficients used in diffusionadvection, using the temperature-depth paramterization of Morin+ 2010. These are returned as Vectors of length nz, where each cell corresponds to a depth node. The two coefficients are k1 and k2, both of which are follwed with cl or w to denote Cl⁻ or water, respectively: k1cl, k2cl, k1w, and k2w.\n\nfield description default\nk hydraulic conductivity of sediment column 0.1 m / yr\ndt timestep 10 yrs\ndz node spacing 5 m\ndepth sediment column depth 2000 m\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.density-Tuple{Any}","page":"Home","title":"PorewaterDiffusion.density","text":"density(chlorinity)\n\nCalculates the density of a water parcel with chlorinity in units g/m³ (rather than g/m³ for convenience with velocity)\n\nsee also: velocity\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.diffuseadvectcolumn!-Tuple{SedimentColumn, NamedTuple}","page":"Home","title":"PorewaterDiffusion.diffuseadvectcolumn!","text":"diffuseadvectcolumn!(sc,k)\n\nCalculate diffusive and advective transport of chlorinity and isotope-traced water through a sediment column described by properties in k, a NamedTuple generated by the constants function.\n\nOverwrites the o and p PorewaterProperty fields of sc – a SedimentColumn with pre-existing conditions of Cl, O, and rho in its o fields.\n\nrelies on: velocity, density, diffusionadvection, \n\nsee also: SedimentColumn, constants \n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.diffusionadvection-NTuple{8, Any}","page":"Home","title":"PorewaterDiffusion.diffusionadvection","text":"diffusionadvection(x,above,below,k1,k2,v,dt,dz)\n\nCalculate the property of a node in a vertical profile given the combined effects of diffusion and advection. Returns the property given initial values for the node x, the overlying node above, the underlying node below, diffusion coefficients k1 and k2, vertical advection velocity v, timestep dt, and lengthstep dz. Alternatively provide the product of v * dt * dz for a minor speed-up.\n\n\n\n\n\n","category":"method"},{"location":"#PorewaterDiffusion.velocity-Tuple{Any, Any, Any}","page":"Home","title":"PorewaterDiffusion.velocity","text":"velocity(x, above, k)\n\nCalculate the velocity (m/yr) at a node with density x, given the density of the node above, and the hydraulic conductivity k (m/yr).\n\nsee also: density\n\n\n\n\n\n","category":"method"}]
}
