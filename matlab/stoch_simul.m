% Copyright (C) 2001 Michel Juillard
%
function info=stoch_simul(var_list)
global M_ options_ oo_ dr_

global it_
  options_ = set_default_option(options_,'TeX',0);  
  options_ = set_default_option(options_,'order',2);
  options_ = set_default_option(options_,'linear',0);
  if options_.linear
    options_.order = 1;
  end
  options_ = set_default_option(options_,'ar',5);
  options_ = set_default_option(options_,'irf',40);
  options_ = set_default_option(options_,'relative_irf',0);
  options_ = set_default_option(options_,'dr_algo',0);
  options_ = set_default_option(options_,'simul_algo',0);
  options_ = set_default_option(options_,'drop',100);
  if options_.order == 1
    options_.replic = 1;
  else
    options_ = set_default_option(options_,'replic',50);
  end
  options_ = set_default_option(options_,'nomoments',0);
  options_ = set_default_option(options_,'nocorr',0);
  options_ = set_default_option(options_,'simul_seed',[]);
  options_ = set_default_option(options_,'hp_filter',0);
  options_ = set_default_option(options_,'hp_ngrid',512);
  options_ = set_default_option(options_,'simul',0);
  options_ = set_default_option(options_,'periods',0);
  options_ = set_default_option(options_,'noprint',0);

  TeX = options_.TeX;

  if options_.simul & ~isempty(iter_) & options_.periods == 0
    options_.periods = iter_;
  end
  iter_ = max(options_.periods,1);
  if M_.exo_nbr > 0
    oo_.exo_simul= ones(iter_ + M_.maximum_lag + M_.maximum_lead,1) * oo_.exo_steady_state';
  end

  check_model;

  [dr_, info] = resol(oo_.steady_state,0);

  if info(1)
    print_info(info);
    return
  end  

  if ~options_.noprint
    disp(' ')
    disp('MODEL SUMMARY')
    disp(' ')
    disp(['  Number of variables:         ' int2str(M_.endo_nbr)])
    disp(['  Number of stochastic shocks: ' int2str(M_.exo_nbr)])
    disp(['  Number of state variables:   ' ...
	  int2str(length(find(dr_.kstate(:,2) <= M_.maximum_lag+1)))])
    disp(['  Number of jumpers:           ' ...
	  int2str(length(find(dr_.kstate(:,2) == M_.maximum_lag+2)))])
    disp(['  Number of static variables:  ' int2str(dr_.nstatic)])
    my_title='MATRIX OF COVARIANCE OF EXOGENOUS SHOCKS';
    labels = deblank(M_.exo_names);
    headers = strvcat('Variables',labels);
    lh = size(labels,2)+2;
    table(my_title,headers,labels,M_.Sigma_e,lh,10,6);
    disp(' ')
    disp_dr(dr_,options_.order,var_list);
  end

  if options_.simul == 0 & options_.nomoments == 0
    disp_th_moments(dr_,var_list); 
  elseif options_.simul == 1
    if options_.periods == 0
      error('STOCH_SIMUL error: number of periods for the simulation isn''t specified')
    end
    if options_.periods < options_.drop
      disp(['STOCH_SIMUL error: The horizon of simulation is shorter' ...
	    ' than the number of observations to be DROPed'])
      return
    end
    oo_.endo_simul = simult(repmat(dr_.ys,1,M_.maximum_lag),dr_);
    dyn2vec;
    if options_.nomoments == 0
      disp_moments(oo_.endo_simul,var_list);
    end
  end



  if options_.irf 
    n = size(var_list,1);
    if n == 0
      n = M_.endo_nbr;
      ivar = [1:n]';
      var_list = M_.endo_names;
      if TeX
	var_listTeX = M_.endo_names_tex;
      end
    else
      ivar=zeros(n,1);
      if TeX
	var_listTeX = [];
      end
      for i=1:n
	i_tmp = strmatch(var_list(i,:),M_.endo_names,'exact');
	if isempty(i_tmp)
	  error (['One of the specified variables does not exist']) ;
	else
	  ivar(i) = i_tmp;
	  if TeX
	    var_listTeX = strvcat(var_listTeX,deblank(M_.endo_names_tex(i_tmp,:)));
	  end
	end
      end
    end
    if TeX
      fidTeX = fopen([M_.fname '_IRF.TeX'],'w');
      fprintf(fidTeX,'%% TeX eps-loader file generated by stoch_simul.m (Dynare).\n');
      fprintf(fidTeX,['%% ' datestr(now,0) '\n']);
      fprintf(fidTeX,' \n');
    end
    olditer = iter_;% Est-ce vraiment utile ? Il y a la m�me ligne dans irf... 
    SS(M_.exo_names_orig_ord,M_.exo_names_orig_ord)=M_.Sigma_e+1e-14*eye(M_.exo_nbr);
    cs = transpose(chol(SS));
    tit(M_.exo_names_orig_ord,:) = M_.exo_names;
    if TeX
      titTeX(M_.exo_names_orig_ord,:) = M_.exo_names_tex;
    end
    for i=1:M_.exo_nbr
      if SS(i,i) > 1e-13
	y=irf(dr_,cs(M_.exo_names_orig_ord,i), options_.irf, options_.drop, ...
	      options_.replic, options_.order);
	if options_.relative_irf
	  y = 100*y/cs(i,i); 
	end
	irfs   = [];
	mylist = [];
	if TeX
	  mylistTeX = [];
	end
	for j = 1:n
	  if max(y(ivar(j),:)) - min(y(ivar(j),:)) > 1e-10
	    irfs  = cat(1,irfs,y(ivar(j),:));
	    mylist = strvcat(mylist,deblank(var_list(j,:)));
	    if TeX
	      mylistTeX = strvcat(mylistTeX,deblank(var_listTeX(j,:)));
	    end
	  end
	end
	number_of_plots_to_draw = size(irfs,1);
	number_of_plots_to_draw
	[nbplt,nr,nc,lr,lc,nstar] = pltorg(number_of_plots_to_draw);
	if nbplt == 0
	elseif nbplt == 1
	  if options_.relative_irf
	    hh = figure('Name',['Relative response to' ...
				' orthogonalized shock to ' tit(i,:)]);
	  else
	    hh = figure('Name',['Orthogonalized shock to' ...
				' ' tit(i,:)]);
	  end
	  for j = 1:number_of_plots_to_draw
	    subplot(nr,nc,j);
	    plot(1:options_.irf,transpose(irfs(j,:)),'-k','linewidth',1);
	    hold on
	    plot([1 options_.irf],[0 0],'-r','linewidth',0.5);
	    hold off
	    xlim([1 options_.irf]);
	    title(deblank(mylist(j,:)),'Interpreter','none');
	    assignin('base',[deblank(mylist(j,:)) '_' deblank(tit(i,:))],transpose(irfs(j,:)));
	  end
	  eval(['print -depsc2 ' M_.fname '_IRF_' deblank(tit(i,:))]);
	  eval(['print -dpdf ' M_.fname  '_IRF_' deblank(tit(i,:))]);
	  saveas(hh,[M_.fname  '_IRF_' deblank(tit(i,:)) '.fig']);
	  if TeX
	    fprintf(fidTeX,'\\begin{figure}[H]\n');
	    for j = 1:number_of_plots_to_draw
	      fprintf(fidTeX,['\\psfrag{%s}[1][][0.5][0]{$%s$}\n'],deblank(mylist(j,:)),deblank(mylistTeX(j,:)));
	    end
	    fprintf(fidTeX,'\\centering \n');
	    fprintf(fidTeX,'\\includegraphics[scale=0.5]{%s_IRF_%s}\n',M_.fname,deblank(tit(i,:)));
	    fprintf(fidTeX,'\\caption{Impulse response functions (orthogonalized shock to $%s$).}',titTeX(i,:));
	    fprintf(fidTeX,'\\label{Fig:IRF:%s}\n',deblank(tit(i,:)));
	    fprintf(fidTeX,'\\end{figure}\n');
	    fprintf(fidTeX,' \n');
	  end
	  %	close(hh)
	else
	  for fig = 1:nbplt-1
	    if options_.relative_irf == 1
	      hh = figure('Name',['Relative response to orthogonalized shock' ...
				  ' to ' tit(i,:) ' figure ' int2str(fig)]);
	    else
	      hh = figure('Name',['Orthogonalized shock to ' tit(i,:) ...
				  ' figure ' int2str(fig)]);
	    end
	    for plt = 1:nstar
	      subplot(nr,nc,plt);
	      plot(1:options_.irf,transpose(irfs((fig-1)*nstar+plt,:)),'-k','linewidth',1);
	      hold on
	      plot([1 options_.irf],[0 0],'-r','linewidth',0.5);
	      hold off
	      xlim([1 options_.irf]);
	      title(deblank(mylist((fig-1)*nstar+plt,:)),'Interpreter','none');
	      assignin('base',[deblank(mylist((fig-1)*nstar+plt,:)) '_' deblank(tit(i,:))],transpose(irfs((fig-1)*nstar+plt,:)));
	    end
	    eval(['print -depsc2 ' M_.fname '_IRF_' deblank(tit(i,:)) int2str(fig)]);
	    eval(['print -dpdf ' M_.fname  '_IRF_' deblank(tit(i,:)) int2str(fig)]);
	    saveas(hh,[M_.fname  '_IRF_' deblank(tit(i,:)) int2str(fig) '.fig']);
	    if TeX
	      fprintf(fidTeX,'\\begin{figure}[H]\n');
	      for j = 1:nstar
		fprintf(fidTeX,['\\psfrag{%s}[1][][0.5][0]{$%s$}\n'],deblank(mylist((fig-1)*nstar+j,:)),deblank(mylistTeX((fig-1)*nstar+j,:)));
	      end
	      fprintf(fidTeX,'\\centering \n');
	      fprintf(fidTeX,'\\includegraphics[scale=0.5]{%s_IRF_%s%s}\n',M_.fname,deblank(tit(i,:)),int2str(fig));
	      if options_.relative_irf
		fprintf(fidTeX,['\\caption{Relative impulse response' ...
				' functions (orthogonalized shock to $%s$).}'],deblank(titTeX(i,:)));
	      else
		fprintf(fidTeX,['\\caption{Impulse response functions' ...
				' (orthogonalized shock to $%s$).}'],deblank(titTeX(i,:)));
	      end
	      fprintf(fidTeX,'\\label{Fig:BayesianIRF:%s:%s}\n',deblank(tit(i,:)),int2str(fig));
	      fprintf(fidTeX,'\\end{figure}\n');
	      fprintf(fidTeX,' \n');
	    end
	    %					close(hh);
	  end
	  hh = figure('Name',['Orthogonalized shock to ' tit(i,:) ' figure ' int2str(nbplt) '.']);
	  m = 0; 
	  for plt = 1:number_of_plots_to_draw-(nbplt-1)*nstar;
	    m = m+1;
	    subplot(lr,lc,m);
	    plot(1:options_.irf,transpose(irfs((nbplt-1)*nstar+plt,:)),'-k','linewidth',1);
	    hold on
	    plot([1 options_.irf],[0 0],'-r','linewidth',0.5);
	    hold off
	    xlim([1 options_.irf]);
	    title(deblank(mylist((nbplt-1)*nstar+plt,:)),'Interpreter','none');
	    assignin('base',[deblank(mylist((nbplt-1)*nstar+plt,:)) '_' deblank(tit(i,:))],transpose(irfs((nbplt-1)*nstar+plt,:)));
	  end
	  eval(['print -depsc2 ' M_.fname '_IRF_' deblank(tit(i,:)) int2str(nbplt)]);
	  eval(['print -dpdf ' M_.fname  '_IRF_' deblank(tit(i,:)) int2str(nbplt)]);
	  saveas(hh,[M_.fname  '_IRF_' deblank(tit(i,:)) int2str(nbplt) '.fig']);
	  if TeX
	    fprintf(fidTeX,'\\begin{figure}[H]\n');
	    for j = 1:m
	      fprintf(fidTeX,['\\psfrag{%s}[1][][0.5][0]{$%s$}\n'],deblank(mylist((nbplt-1)*nstar+j,:)),deblank(mylistTeX((nbplt-1)*nstar+j,:)));
	    end
	    fprintf(fidTeX,'\\centering \n');
	    fprintf(fidTeX,'\\includegraphics[scale=0.5]{%s_IRF_%s%s}\n',M_.fname,deblank(tit(i,:)),int2str(nbplt));
	    if options_.relative_irf
	      fprintf(fidTeX,['\\caption{Relative impulse response functions' ...
			      ' (orthogonalized shock to $%s$).}'],deblank(titTeX(i,:)));
	    else
	      fprintf(fidTeX,['\\caption{Impulse response functions' ...
			      ' (orthogonalized shock to $%s$).}'],deblank(titTeX(i,:)));
	    end
	    fprintf(fidTeX,'\\label{Fig:IRF:%s:%s}\n',deblank(tit(i,:)),int2str(nbplt));
	    fprintf(fidTeX,'\\end{figure}\n');
	    fprintf(fidTeX,' \n');
	  end
	  %				close(hh);
	end
      end
    end
    iter_ = olditer;
    if TeX
      fprintf(fidTeX,' \n');
      fprintf(fidTeX,'%% End Of TeX file. \n');
      fclose(fidTeX);
    end
  end
  % 02/20/01 MJ oo_.steady_state removed from calling sequence for simult (all in dr_)
  % 02/23/01 MJ added dyn2vec()
  % 06/24/01 MJ steady -> steadoo_.endo_simul
  % 08/28/02 MJ added var_list
  % 10/09/02 MJ no simulation and theoretical moments for order 1 
  % 10/14/02 MJ added plot of IRFs
  % 10/30/02 MJ options_ are now a structure
  % 01/01/03 MJ added dr_algo
  % 01/09/03 MJ set default values for options_ (correct absence of autocorr
  %             when order == 1)
  % 01/12/03 MJ removed call to steadoo_.endo_simul as already checked in resol()
  % 02/09/03 MJ oo_.steady_state reset with value declared in initval after computations
  % 02/18/03 MJ removed above change. oo_.steady_state shouldn't be affected by
  %             computations in this function
  %             new option SIMUL computes a stochastic simulation and save
  %             results in oo_.endo_simul and via dyn2vec
  % 04/03/03 MJ corrected bug for simulation with M_.maximum_lag > 1
  % 05/20/03 MJ eliminates exogenous shocks with 0 variance
  % 05/20/03 MJ don't plot IRF if variation < 1e-10
  % 11/14/03 MJ corrected bug on number of replications for IRF when
  %             order=2
  % 11/22/03 MJ replaced IRFs by orthogonalized IRFs
  % 08/30/04 SA The maximum number of plots is not constrained for the IRFs and 
  %			  all the plots are saved in *.eps, *.pdf and *.fig files (added
  % 09/03/04 SA Tex output for IRFs added
