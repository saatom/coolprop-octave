# coolprop-octave

***DESCRIPTION***
Octave script to interface with Python wrapper of CoolProp
Made by Wyatt Richards

The official Octave wrapper wasn't working right so I whipped this cursed thing together to help me get some work done. I encourage you to make any improvements you can come up with. I am in no way affiliated with the creators or maintainers of CoolProp, this is merely a side project.

***OVERVIEW***
Calling ```CoolProp``` will return a struct containing functions that mirror the high-level function names in the official Python library. The primary advantage of this script is that it allows not only multiple outputs at a time, but it also supports matrix inputs as well for functions like ```CoolProp.PropsSI```

***EXAMPLE CODE***
```octave
T = linspace(-30, 80, 30) + 273; # Create a matrix of temperatures in K
P = linspace(1e5, 10e5, 10); # Create a matrix of pressures in Pa
rho = CoolProp.PropsSI('D', 'T', T, 'P', P, 'Air') # Generate a 30x10 matrix of densities, with temperatures on the rows and pressures on the columns
clf(); hold on; arrayfun(@(pidx) plot(T, rho(:, pidx)), [1:length(P)]); hold off; # Plot the values
xlabel('Temperature (K)'); ylabel('Density (kg/m^3)'); title('Density of Air vs Temperature at Various Pressures'); axis tight; # Assign axis labels
legend(cellfun(@(p) sprintf('%.1f MPa',p/10^6), num2cell(P), 'UniformOutput', false)); # Set legend
```
The above code produces the following figure

***DEPENDENCIES***
This script requires Octave's 'parallel' and 'pythonic' packages, both of which can be installed from Octave's public package library. 
Note: I have included parallel as a dependency because I intend to implement parallel computing capabilities for large matrix inputs but it is unused at the moment.

It also requires a working version of the Python wrapper for CoolProp, either built from source or installed using
```pip install CoolProp```
Make sure to update your system path such that Python can find your CoolProp files
