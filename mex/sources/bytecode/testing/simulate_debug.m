function simulate_debug()
global M_ oo_ options_;
     fid = fopen([M_.fname '_options.txt'],'wt');
     fprintf(fid,'%d\n',options_.periods);
     fprintf(fid,'%d\n',options_.maxit_);
     fprintf(fid,'%6.20f\n',options_.slowc);
     fprintf(fid,'%6.20f\n',options_.markowitz);
     fprintf(fid,'%6.20f\n',options_.dynatol);
     fclose(fid);
     
     fid = fopen([M_.fname '_M.txt'],'wt');
     fprintf(fid,'%d\n',M_.maximum_lag);
     fprintf(fid,'%d\n',M_.maximum_lead);
     fprintf(fid,'%d\n',M_.maximum_endo_lag);
     fprintf(fid,'%d\n',M_.param_nbr);
     fprintf(fid,'%d\n',size(oo_.exo_simul, 1));
     fprintf(fid,'%d\n',size(oo_.exo_simul, 2));
     fprintf(fid,'%d\n',M_.endo_nbr);
     fprintf(fid,'%d\n',size(oo_.endo_simul, 2));
     fprintf(fid,'%d\n',M_.exo_det_nbr);
     fprintf(fid,'%6.20f\n',M_.params);

     fclose(fid);
     fid = fopen([M_.fname '_oo.txt'],'wt');
     fprintf(fid,'%6.20f\n',oo_.endo_simul);
     fprintf(fid,'%6.20f\n',oo_.exo_simul);
     fclose(fid);
     