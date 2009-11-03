function y_=simult_(y0,dr,ex_,iorder)
% function y_=simult_(y0,dr,ex_,iorder)
%
% Simulates the model, given the path of exogenous variables and the
% decision rules.
%
% INPUTS
%    y0:       starting values
%    dr:       structure of decisions rules for stochastic simulations
%    ex_:      matrix of shocks
%    iorder=0: first-order approximation
%    iorder=1: second-order approximation
%
% OUTPUTS
%    y_:       stochastic simulations results
%
% SPECIAL REQUIREMENTS
%    none

% Copyright (C) 2001-2007 Dynare Team
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

global M_ options_ it_
  iter = size(ex_,1);
  if ~isempty(dr.ghu)
      nx = size(dr.ghu,2);
  end
  y_ = zeros(size(y0,1),iter+M_.maximum_lag);
  
  y_(:,1:M_.maximum_lag) = y0;
  k1 = [M_.maximum_lag:-1:1];
  k2 = dr.kstate(find(dr.kstate(:,2) <= M_.maximum_lag+1),[1 2]);
  k2 = k2(:,1)+(M_.maximum_lag+1-k2(:,2))*M_.endo_nbr;
  k3 = M_.lead_lag_incidence(1:M_.maximum_lag,:)';
  k3 = find(k3(:));
  k4 = dr.kstate(find(dr.kstate(:,2) < M_.maximum_lag+1),[1 2]);
  k4 = k4(:,1)+(M_.maximum_lag+1-k4(:,2))*M_.endo_nbr;
  
  if iorder == 1    
      if ~isempty(dr.ghu)
          for i = M_.maximum_lag+1: iter+M_.maximum_lag
              tempx1 = y_(dr.order_var,k1);
              tempx2 = tempx1-repmat(dr.ys(dr.order_var),1,M_.maximum_lag);
              tempx = tempx2(k2);
                  y_(dr.order_var,i) = dr.ys(dr.order_var)+dr.ghx*tempx+dr.ghu* ...
                      ex_(i-M_.maximum_lag,:)';
              k1 = k1+1;
          end
      else
          for i = M_.maximum_lag+1: iter+M_.maximum_lag
              tempx1 = y_(dr.order_var,k1);
              tempx2 = tempx1-repmat(dr.ys(dr.order_var),1,M_.maximum_lag);
              tempx = tempx2(k2);
                  y_(dr.order_var,i) = dr.ys(dr.order_var)+dr.ghx*tempx;
              k1 = k1+1;
          end
      end
  elseif iorder == 2
    for i = M_.maximum_lag+1: iter+M_.maximum_lag
      tempx1 = y_(dr.order_var,k1);
      tempx2 = tempx1-repmat(dr.ys(dr.order_var),1,M_.maximum_lag);
      tempx = tempx2(k2);
      tempu = ex_(i-M_.maximum_lag,:)';
      %tempuu = kron(tempu,tempu);
      %	tempxx = kron(tempx,tempx);
      %	tempxu = kron(tempx,tempu);
      %y_(dr.order_var,i) = dr.ys(dr.order_var)+dr.ghs2/2+dr.ghx*tempx+ ...
      %	    dr.ghu*tempu+0.5*(dr.ghxx*tempxx+dr.ghuu*tempuu)+dr.ghxu* ...
      %      tempxu;
        y_(dr.order_var,i) = dr.ys(dr.order_var)+dr.ghs2/2+dr.ghx*tempx+ ...
	    dr.ghu*tempu+0.5*(A_times_B_kronecker_C(dr.ghxx,tempx)+A_times_B_kronecker_C(dr.ghuu,tempu))+A_times_B_kronecker_C(dr.ghxu,tempx,tempu);
      k1 = k1+1;
    end
  end

% MJ 08/30/02 corrected bug at order 2