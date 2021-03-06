function o = addPage(o, varargin)
% function o = addPage(o, varargin)
% Sections Class Constructor
%
% INPUTS
%   o              [pages]  pages object
%   varargin                options to @page.page
%
% OUTPUTS
%   o              [pages] pages object
%
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2013 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

disp(['Processing Page: ' num2str(numPages(o)+1)]);
o.objArray = o.objArray.addObj(page(varargin{:}));
end