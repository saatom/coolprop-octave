# Made by Wyatt Richards
# My attempt at making an Octave wrapper for Python CoolProp
# It ain't pretty but it works for what I need it for. To any unsuspecting dev who stumbles upon this cursed concoction, I am sorry you had to see this.
# CoolProp() returns a struct of functions whose names mimic those used in the Python library, thus the syntax should be more or less identical.
# Usage:
#   [output] = CoolProp.function_name(input_parameters)
#
#   Providing numeric inputs (up to two) as column matrices with lengths N and M will produce a result with dimensions NxM. Note that the first variable defines the rows and the second one defines the columns. If you want to swap them, just switch places.
#   Example:
#     Tmat=linspace(200, 400, 20);
#     Pmat=linspace(1e5, 5e5, 10);
#     [mu] = CoolProp.PropsSI('viscosity', 'T', Tmat, 'P', Pmat, 'Air')
#     >> size(mu)
#     >> ans = 
#         20  10
#
# Examples:
#   [mu] = CoolProp.PropsSI('V', 'T', 273, 'P', 101300, 'Water')
#   CoolProp.getstring("parameter_list")
function flist=CoolProp() # Create a struct with the various coolprop functions
  function varargout=PropsSI(varargin)
    varargout=__coolprop__("PropsSI", varargin{:}){:};
  endfunction
  flist.PropsSI=@PropsSI;
  flist.Props1SI=@PropsSI;

  function varargout=get_global_param_string(varargin)
    varargout=__coolprop__("get_global_param_string", varargin{:}){:};
  endfunction
  flist.get_global_param_string=@get_global_param_string;
  flist.getstring=@get_global_param_string;

  function varargout=PhaseSI(varargin)
    varargout=__coolprop__("PhaseSI", varargin{:}){:};
  endfunction
  flist.PhaseSI=@PhaseSI;

  function varargout=HAPropsSI(varargin)
    varargout=__coolprop__("HAPropsSI", varargin{:}){:};
  endfunction
  flist.HAPropsSI=@HAPropsSI; 

  function init()
    __coolprop__()
  endfunction
  flist.init=@init; 
endfunction

function out=__coolprop__(fname, varargin) # Interpret coolprop instructions into Python
  #tic()
  global coolprop_python_initialized
  if isempty(coolprop_python_initialized)
    pkg load pythonic
    pkg load parallel
    loaded=pkg('list');
    for idx=1:length(loaded)
      p=loaded{idx};
      if strcmpi(p.name,'symbolic') && p.loaded==true # Fix symbolic package quirks
        disp("CoolProp: package 'symbolic' is loaded resetting Python environment to accommodate it")
        sympref ipc popen2
        sympref reset
        break;
      endif
    endfor
    disp("initializing python environment and associated modules")
    pyexec("from CoolProp import AbstractState");
    pyexec("from CoolProp.CoolProp import PropsSI, PhaseSI, get_global_param_string");
    pyexec("from CoolProp.HumidAirProp import HAPropsSI");
    #pyexec("import sympy")
    coolprop_python_initialized=true;
  endif
  if length(varargin)==0
    return
  endif
  # Have equivalent property names for ease of code writing
  equivalents={'mu', 'viscosity'; 'rho', 'D'; 'cp', 'CMASS'; 'k', 'CONDUCTIVITY'; 'pr', 'Prandtl'}; 
  %initstr=sprintf('from __future__ import print_function\nfrom CoolProp import AbstractState\nfrom CoolProp.CoolProp import PhaseSI, PropsSI, get_global_param_string\nimport CoolProp.CoolProp as CoolProp\nfrom CoolProp.HumidAirProp import HAPropsSI\nfrom math import sin\n'); # Initialize python libraries
  initstr='';

  #{
  [fid name msg]=mkstemp("tmp_coolprop_XXXXXX", true); # Make a temporary file to run the python code
  fopen(fid);
  fputs(fid, initstr);
  #}

  numeric=find(cellfun('isnumeric', varargin)); # Find which of the inputs are numeric
  lengths=cellfun('length', varargin(numeric)); # Find the lengths of the numeric input
  if !iscell(varargin{1})
    varargin{1}={varargin{1}};
  endif

  if length(lengths) > 2 && length(find(lengths>1)) > 2
    error("more than two array inputs not yet supported\n")
  endif
  #{
  if isempty(lengths) || true(lengths(1)==lengths)==1 # Check if all numerical entries have the same length
  elseif length(find(lengths==1))==length(lengths)-1 # Check if all numerical entries have length 1 except for one
    lmax=max(lengths);
    longone=find(lengths==lmax);
    for idx=1:length(lengths)
      if idx!=longone
        varpos=numeric(idx);
        varargin{varpos} = ones(lmax, 1)(:)*varargin{varpos};
      endif
    endfor
  else
    error("numerical entries have incompatible sizes\n")
  endif
  #}

  #if iscell(varargin{1}) && length(varargin{1})>1 # Check how many outputs are expected; use recursion if it's more than one
  if 1==0
    %out=parcellfun(nproc, @(prop) __coolprop__(fname, prop, orig{2:end}){1}, orig{1}, 'uniformoutput', true) # Parallel processing for more efficient data grabbing
    for jdx=1:length(varargin{1})
      prop=varargin{1}{jdx};
      newargs=varargin;
      newargs{1}=prop;
      data=__coolprop__(fname, newargs{:});
      out{jdx}=data{:};
    endfor
  elseif ismember(lower(varargin{1}), {'nu', 'kv'}) # Special case for kinematic viscosity (just mu/rho)
    #in=varargin; in{1}='D';
    #in2=varargin; in2{1}='V';
    [rhos mus]=CoolProp.PropsSI({'D', 'V'}, varargin{2:end});
    nus=mus./rhos;
    out{1}={nus};
  else # Handle single output cases
    if !iscell(varargin{1}) # If the first argument is not a cell array, make it into a 1x1 cell for compatibility with indexing functions
      varargin{1}={varargin{1}};
    endif

    if length(lengths) > 1 # Check how many numerical inputs there are
      len1=lengths(1); len2=lengths(2);
    elseif length(lengths) == 1
      len1=1; len2=lengths(1);
    else
      len1=1; len2=1;
    endif
    for jdx=1:length(varargin{1}) # Loop through the different outputs
      firstval=varargin{1}{jdx};
      subs=ismember(firstval, equivalents(:,1));
      if subs>0 # Check if an alias property was used and substitute it for a CoolProp compatible name
        firstval=equivalents{find(subs==1), 2};
        fprintf("CoolProp - substituting property '%s' for '%s'\n", varargin{1}{jdx}, firstval);
      endif
      for wdx=1:len1 # Loop through array input 1
        for vdx=1:len2 # Loop through array input 2
          %instr=sprintf("print(%s(", fname);
          instr=sprintf("py.%s(", fname);
          # Put together
          for idx=1:nargin-1 # Create one line in the python file
            in={firstval varargin{2:end}}{idx};
            if length(in)>1 && ismember(idx, numeric) # Alter the indices for the first numeric entries
              switch find(idx==numeric)
                case 1
                  in=in(wdx);
                case 2
                  in=in(vdx);
                otherwise
                  error("Something is wrong")
              endswitch
            endif
            if idx > 1
              instr=[instr ", "];
            endif
            if ischar(in)
              instr=[instr "'" in "'"];
            elseif isnumeric(in)
              instr=[instr num2str(in, 10)];
            endif
          endfor
          instr=sprintf("%s)", instr);
          datapoint=eval(instr);
          if isnumeric(datapoint)
            out{1}{jdx}(wdx, vdx)=datapoint;
          else
            out{1}{jdx}=datapoint;
          endif
            #{
          if vdx<len2
            instr=sprintf("%s), end=',')\n", instr);
          elseif vdx>=len2 && wdx<len1
            instr=sprintf("%s), end=';')\n", instr);
          else
            instr=sprintf("%s), end='\\n')\n", instr);
          endif
          fputs(fid, instr);
          #}
        endfor
      endfor
    endfor
    #fclose(fid);
    #delete(name);
    return
    #{
    switch fname
      case {'PhaseSI'}
      case {'get_global_param_string'}
        switch lower(varargin{1})
          case {'parameter_list', 'fluidslist'}
            splt=strsplit(pyout,',');
            if length(splt) > 1
              pyout=strjoin(sort(splt), ', ');
            endif
        endswitch
      otherwise
        split1=strsplit(pyout, '\n')(1:end-1); # Separate the data into its respective output variable
        for idx=1:length(split1)
          dat=split1{idx};
          split2=strsplit(dat, ';'); # Split the main string into rows from the input
          split3=cellfun(@(prop) strsplit(prop, ','), split2, 'UniformOutput', false); # First split the strings into one cell array for each property
          nums=cellfun(@(numarr) cellfun(@(num) str2num(num), numarr, 'UniformOutput', false), split3, 'UniformOutput', false); # Convert each cell array of strings into numbers
          out{1}{idx}=cell2mat(cell2mat(nums(:)));
          #pyout=cellfun(@(prop) cell2mat(prop), nums, 'UniformOutput', false) # Convert the cell arrays of numbers into a matrix
        endfor
        return
    endswitch
    if !iscell(pyout)
      pyout={pyout};
      out{1}=pyout;
    endif
  #}
  endif
endfunction
