# Example script to demonstrate CoolProp syntax and utility
function varargout=Example()
  T = linspace(-30, 80, 30) + 273; # Create a matrix of temperatures in K
  P = linspace(1e5, 10e5, 10); # Create a matrix of pressures in Pa
  tic();
  rho = CoolProp.PropsSI('D', 'T', T, 'P', P, 'Air'); # Generate a 30x10 matrix of densities, with temperatures on the rows and pressures on the columns
  clf(); hold on; arrayfun(@(pidx) plot(T, rho(:, pidx)), [1:length(P)]); hold off; # Plot the values
  ms=toc()*1000; # Time elapsed for CoolProp to get properties
  fprintf('CoolProp finished all %.f data points in %.2f milliseconds\n', length(T)*length(P), ms);
  xlabel('Temperature (K)'); ylabel('Density (kg/m^3)'); title('Density of Air vs Temperature at Various Pressures'); axis tight; # Assign axis labels
  legend(cellfun(@(p) sprintf('%.1f MPa',p/10^6), num2cell(P), 'UniformOutput', false)); # Set chart legend
endfunction
