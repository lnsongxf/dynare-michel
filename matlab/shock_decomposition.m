function z = shock_decomposition(M_,oo_,varlist)
% function z = shock_decomposition(R,epsilon,varlist)
% Computes shocks contribution to a simulated trajectory
%
% INPUTS
%    R:         mm*rr matrix of shock impact
%    epsilon:   rr*nobs matrix of shocks
%    varlist:   list of variables
%
% OUTPUTS
%    z:         nvar*rr*nobs shock decomposition
%
% SPECIAL REQUIREMENTS
%    none

% Copyright (C) 2009 Dynare Team
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
    
% number of variables
    endo_nbr = M_.endo_nbr;

% number of shocks
    nshocks = M_.exo_nbr;

    % indices of endogenous variables
    [i_var,nvar] = varlist_indices(varlist);

    % reduced form
    dr = oo_.dr;

    % data reordering
    order_var = dr.order_var;
    inv_order_var = dr.inv_order_var;


    % coefficients
    A = dr.ghx;
    B = dr.ghu;
    
    % initialization
    for i=1:nshocks
        epsilon(i,:) = eval(['oo_.SmoothedShocks.' M_.exo_names(i,:)]);
    end
    gend = size(epsilon,2);
    
    z = zeros(endo_nbr,nshocks+2,gend);
    for i=1:endo_nbr
        z(i,end,:) = eval(['oo_.SmoothedVariables.' M_.endo_names(i,:)]);
    end

    maximum_lag = M_.maximum_lag;
    lead_lag_incidence = M_.lead_lag_incidence;
    for i=1:gend
        if i > 1 & i <= maximum_lag+1
            lags = min(i-1,maximum_lag):-1:1;
            k2 = dr.kstate(find(dr.kstate(:,2) <= min(i,maximum_lag)+1),[1 2]);
            i_state = order_var(k2(:,1))+(min(i,maximum_lag)+1-k2(:,2))*M_.endo_nbr;
        end
        
        if i > 1
            tempx = permute(z(:,1:nshocks,lags),[1 3 2]);
            m = min(i-1,maximum_lag);
            tempx = [reshape(tempx,endo_nbr*m,nshocks); zeros(endo_nbr*(maximum_lag-i+1),nshocks)];
            z(:,1:nshocks,i) = A(inv_order_var,:)*tempx(i_state,:);
            lags = lags+1;
        end

        z(:,1:nshocks,i) = z(:,1:nshocks,i) + B(inv_order_var,:).*repmat(epsilon(:,i)',nvar,1);
        z(:,nshocks+1,i) = z(:,nshocks+2,i) - sum(z(:,1:nshocks,i),2);
    end
    
    
    