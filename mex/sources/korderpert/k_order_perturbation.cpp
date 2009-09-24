/*
 * Copyright (C) 2008-2009 Dynare Team
 *
 * This file is part of Dynare.
 *
 * Dynare is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Dynare is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Dynare.  If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************
   // k_order_perturbation.cpp : Defines the entry point for the k-order perturbation application DLL.
   //
   // called from Dynare dr1_k_order.m, (itself called form resol.m instead of regular dr1.m)
   //            if options_.order < 2 % 1st order only
   //                [ysteady, ghx_u]=k_order_perturbation(dr,task,M_,options_, oo_ , ['.' mexext]);
   //            else % 2nd order
   //                [ysteady, ghx_u, g_2]=k_order_perturbation(dr,task,M_,options_, oo_ , ['.' mexext]);
   // inputs:
   //			dr,		- Dynare structure
   //			task,  - check or not, not used
   //			M_		- Dynare structure
   //			options_ - Dynare structure
   //			oo_		- Dynare structure
   //			['.' mexext] Matlab dll extension
   // returns:
   //			 ysteady steady state
   //			ghx_u - first order rules packed in one matrix
   //			g_2 - 2nd order rules packed in one matrix
 **********************************************************/

#include "k_ord_dynare.h"
#include "dynamic_dll.h"
#include "math.h"
#include <cstring>

#include <cctype>

#ifdef  _MSC_VER  //&&WINDOWS

BOOL APIENTRY
DllMain(HANDLE hModule,
        DWORD  ul_reason_for_call,
        LPVOID lpReserved
        )
{
  switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
      break;
    }
  return TRUE;
}

// Some MS Windows preambles
// This is an example of an exported variable
K_ORDER_PERTURBATION_API int nK_order_perturbation = 0;

// This is an example of an exported function.
K_ORDER_PERTURBATION_API int
fnK_order_perturbation(void)
{
  return 42;
}
// This is the constructor of a class that has been exported.
// see k_order_perturbation.h for the class definition
CK_order_perturbation::CK_order_perturbation()
{
  return;
}

#endif // _MSC_VER && WINDOWS

#ifdef MATLAB_MEX_FILE  // exclude mexFunction for other applications
extern "C" {

  // mexFunction: Matlab Inerface point and the main application driver

  void
  mexFunction(int nlhs, mxArray *plhs[],
              int nrhs, const mxArray *prhs[])
  {
    if (nrhs < 5)
      mexErrMsgTxt("Must have at least 5 input parameters.\n");
    if (nlhs == 0)
      mexErrMsgTxt("Must have at least 1 output parameter.\n");

    const mxArray *dr = prhs[0];
    const int check_flag = (int) mxGetScalar(prhs[1]);
    const mxArray *M_ = prhs[2];
    const mxArray *options_ =  (prhs[3]);
    const mxArray *oo_ =  (prhs[4]);

    mxArray *mFname = mxGetField(M_, 0, "fname");
    if (!mxIsChar(mFname))
      {
        mexErrMsgTxt("Input must be of type char.");
      }
    const char *fName = mxArrayToString(mFname);
    const char *dfExt = NULL; //Dyanamic file extension, e.g.".dll" or .mexw32;
    if (prhs[5] != NULL)
      {
        const mxArray *mexExt = prhs[5];
        dfExt = mxArrayToString(mexExt);
      }

#ifdef DEBUG
    mexPrintf("k_order_perturbation: check_flag = %d ,  fName = %s , mexExt=%s.\n", check_flag, fName, dfExt);
#endif
    int kOrder;
    mxArray *mxFldp = mxGetField(options_, 0, "order");
    if (mxIsNumeric(mxFldp))
      kOrder = (int) mxGetScalar(mxFldp);
    else
      kOrder = 1;

    double qz_criterium = 1+1e-6;
    mxFldp = mxGetField(options_, 0, "qz_criterium");
    if (mxIsNumeric(mxFldp))
      qz_criterium = (double) mxGetScalar(mxFldp);

    mxFldp      = mxGetField(M_, 0, "params");
    double *dparams = (double *) mxGetData(mxFldp);
    int npar = (int) mxGetM(mxFldp);
    Vector *modParams =  new Vector(dparams, npar);
#ifdef DEBUG
    mexPrintf("k_ord_perturbation: qz_criterium=%g, nParams=%d .\n", qz_criterium, npar);
    for (int i = 0; i < npar; i++)
      {
        mexPrintf("k_ord_perturbation: Params[%d]= %g.\n", i, (*modParams)[i]);
      }
    //	for (int i = 0; i < npar; i++) {
    //        mexPrintf("k_ord_perturbation: params_vec[%d]= %g.\n", i, params_vec[i] );   }
#endif

    mxFldp      = mxGetField(M_, 0, "Sigma_e");
    dparams = (double *) mxGetData(mxFldp);
    npar = (int) mxGetN(mxFldp);
    TwoDMatrix *vCov =  new TwoDMatrix(npar, npar, dparams);

    //		mxFldp  = mxGetField(oo_, 0,"steady_state" ); // use in order of declaration
    mxFldp      = mxGetField(dr, 0, "ys");  // and not in order of dr.order_var
    //		mxFldp  = mxGetField(oo_, 0,"dyn_ys" );  // and NOT extended ys
    dparams = (double *) mxGetData(mxFldp);
    const int nSteady = (int) mxGetM(mxFldp);
    Vector *ySteady =  new Vector(dparams, nSteady);

    mxFldp = mxGetField(dr, 0, "nstatic");
    const int nStat = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(dr, 0, "npred");
    int nPred = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(dr, 0, "nspred");
    const int nsPred = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(dr, 0, "nboth");
    const int nBoth = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(dr, 0, "nfwrd");
    const int nForw = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(dr, 0, "nsfwrd");
    const int nsForw = (int) mxGetScalar(mxFldp);

    mxFldp = mxGetField(M_, 0, "exo_nbr");
    const int nExog = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(M_, 0, "endo_nbr");
    const int nEndo = (int) mxGetScalar(mxFldp);
    mxFldp = mxGetField(M_, 0, "param_nbr");
    const int nPar = (int) mxGetScalar(mxFldp);
    // it_ should be set to M_.maximum_lag
    mxFldp = mxGetField(M_, 0, "maximum_lag");
    const int nMax_lag = (int) mxGetScalar(mxFldp);

    nPred -= nBoth; // correct nPred for nBoth.

    mxFldp      = mxGetField(dr, 0, "order_var");
    dparams = (double *) mxGetData(mxFldp);
    npar = (int) mxGetM(mxFldp);
    if (npar != nEndo)    //(nPar != npar)
      {
        mexErrMsgTxt("Incorrect number of input var_order vars.\n");
        //return;
      }
    vector<int> *var_order_vp = (new vector<int>(nEndo)); //nEndo));
    for (int v = 0; v < nEndo; v++)
      {
        (*var_order_vp)[v] = (int)(*(dparams++)); //[v];
#ifdef DEBUG
        mexPrintf("var_order_vp)[%d] = %d .\n", v, (*var_order_vp)[v]);
#endif
      }

    // the lag, current and lead blocks of the jacobian respectively
    mxFldp      = mxGetField(M_, 0, "lead_lag_incidence");
    dparams = (double *) mxGetData(mxFldp);
    npar = (int) mxGetN(mxFldp);
    int nrows = (int) mxGetM(mxFldp);
#ifdef DEBUG
    mexPrintf("ll_Incidence nrows=%d, ncols = %d .\n", nrows, npar);
#endif
    TwoDMatrix *llincidence =  new TwoDMatrix(nrows, npar, dparams);
    if (npar != nEndo)
      {
        mexPrintf("Incorrect length of lead lag incidences: ncol=%d != nEndo =%d .\n", npar, nEndo);
        return;
      }
#ifdef DEBUG
    for (int j = 0; j < nrows; j++)
      {
        for (int i = 0; i < nEndo; i++)
          {
            mexPrintf("llincidence->get(%d,%d) =%d .\n",
                      j, i, (int) llincidence->get(j, i));
          }
      }
#endif

    //get NNZH =NNZD(2) = the total number of non-zero Hessian elements 
    mxFldp = mxGetField(M_, 0, "NNZDerivatives");
    dparams = (double *) mxGetData(mxFldp);
    Vector *NNZD =  new Vector (dparams, (int) mxGetM(mxFldp));
#ifdef DEBUG
    mexPrintf("NNZH=%d, \n", (int) (*NNZD)[1]);
#endif

    const int jcols = nExog+nEndo+nsPred+nsForw; // Num of Jacobian columns
    mexPrintf("k_order_perturbation: jcols= %d .\n", jcols);

    mxFldp = mxGetField(M_, 0, "var_order_endo_names");
    mexPrintf("k_order_perturbation: Get nendo .\n");
    const int nendo = (int) mxGetM(mxFldp);
    const int widthEndo = (int) mxGetN(mxFldp);
    const char **endoNamesMX = DynareMxArrayToString(mxFldp, nendo, widthEndo);

#ifdef DEBUG
    for (int i = 0; i < nEndo; i++)
      {
        mexPrintf("k_ord_perturbation: EndoNameList[%d][0]= %s.\n", i, endoNamesMX[i]);
      }
#endif
    mxFldp      = mxGetField(M_, 0, "exo_names");
    const int nexo = (int) mxGetM(mxFldp);
    const int widthExog = (int) mxGetN(mxFldp);
    const char **exoNamesMX = DynareMxArrayToString(mxFldp, nexo, widthExog);

#ifdef DEBUG
    for (int i = 0; i < nexo; i++)
      {
        mexPrintf("k_ord_perturbation: ExoNameList[%d][0]= %s.\n", i, exoNamesMX[i]);
      }
#endif
    if ((nEndo != nendo) || (nExog != nexo))    //(nPar != npar)
      {
        mexErrMsgTxt("Incorrect number of input parameters.\n");
        return;
      }

#ifdef DEBUG
    for (int i = 0; i < nEndo; i++)
      {
        mexPrintf("k_ord_perturbation: EndoNameList[%d]= %s.\n", i, endoNamesMX[i]);
      }
    //    for (int i = 0; i < nPar; i++) {
    //        mexPrintf("k_ord_perturbation: Params[%d]= %g.\n", i, (*modParams)[i]);  }
    for (int i = 0; i < nSteady; i++)
      {
        mexPrintf("k_ord_perturbation: ysteady[%d]= %g.\n", i, (*ySteady)[i]);
      }

    mexPrintf("k_order_perturbation: nEndo = %d ,  nExo = %d .\n", nEndo, nExog);
#endif
    /* Fetch time index */
    //		int it_ = (int) mxGetScalar(prhs[3]) - 1;

    const int nSteps = 0; // Dynare++ solving steps, for time being default to 0 = deterministic steady state
    const double sstol = 1.e-13; //NL solver tolerance from

    THREAD_GROUP::max_parallel_threads = 2; //params.num_threads;

    try
      {
        // make journal name and journal
        std::string jName(fName); //params.basename);
        jName += ".jnl";
        Journal journal(jName.c_str());
#ifdef DEBUG
        mexPrintf("k_order_perturbation: Calling dynamicDLL constructor.\n");
#endif
        //			DynamicFn * pDynamicFn = loadModelDynamicDLL (fname);
        DynamicModelDLL dynamicDLL(fName, nEndo, jcols, nMax_lag, nExog, dfExt);

        // intiate tensor library
#ifdef DEBUG
        mexPrintf("k_order_perturbation: Call tls init\n");
#endif
        tls.init(kOrder, nStat+2*nPred+3*nBoth+2*nForw+nExog);

#ifdef DEBUG
        mexPrintf("k_order_perturbation: Calling dynare constructor .\n");
#endif
        // make KordpDynare object
        KordpDynare dynare(endoNamesMX,  nEndo, exoNamesMX,  nExog, nPar, // paramNames,
                           ySteady, vCov, modParams, nStat, nPred, nForw, nBoth,
                           jcols, NNZD, nSteps, kOrder, journal, dynamicDLL, 
                           sstol, var_order_vp, llincidence, qz_criterium);

        // construct main K-order approximation class
#ifdef DEBUG
        mexPrintf("k_order_perturbation: Call Approximation constructor with qz_criterium=%f \n", qz_criterium);
#endif
        Approximation app(dynare, journal,  nSteps, false, qz_criterium);
        // run stochastic steady
#ifdef DEBUG
        mexPrintf("k_order_perturbation: Calling walkStochSteady.\n");
#endif
        app.walkStochSteady();

        ConstTwoDMatrix ss(app.getSS());
        // open mat file
        std::string matfile(fName); //(params.basename);
        matfile += ".mat";
        FILE *matfd = NULL;
        if (NULL == (matfd = fopen(matfile.c_str(), "wb")))
          {
            fprintf(stderr, "Couldn't open %s for writing.\n", matfile.c_str());
            exit(1);
          }

        std::string ss_matrix_name(fName); //params.prefix);
        ss_matrix_name += "_steady_states";
        //			ConstTwoDMatrix(app.getSS()).writeMat4(matfd, ss_matrix_name.c_str());
        ss.writeMat4(matfd, ss_matrix_name.c_str());

        // write the folded decision rule to the Mat-4 file
        app.getFoldDecisionRule().writeMat4(matfd, fName); //params.prefix);

        fclose(matfd);

        /* Write derivative outputs into memory map */
        map<string, ConstTwoDMatrix> mm;
        app.getFoldDecisionRule().writeMMap(mm, string());

#ifdef DEBUG
        app.getFoldDecisionRule().print();
        mexPrintf("k_order_perturbation: Map print: \n");
        for (map<string, ConstTwoDMatrix>::const_iterator cit = mm.begin();
             cit != mm.end(); ++cit)
          {
            mexPrintf("k_order_perturbation: Map print: string: %s , g:\n", (*cit).first.c_str());
            (*cit).second.print();
          }
#endif

        // get latest ysteady
        double *dYsteady = (dynare.getSteady().base());
        ySteady = (Vector *)(&dynare.getSteady());

        // developement of the output.
#ifdef DEBUG
        mexPrintf("k_order_perturbation: Filling outputs.\n");
#endif

        double  *dgy, *dgu, *ysteady;
        int nb_row_x;

        ysteady = NULL;
        if (nlhs >= 1)
          {
            /* Set the output pointer to the output matrix ysteady. */
            plhs[0] = mxCreateDoubleMatrix(nEndo, 1, mxREAL);
            /* Create a C pointer to a copy of the output ysteady. */
            TwoDMatrix tmp_ss(nEndo, 1, mxGetPr(plhs[0]));
            tmp_ss = (const TwoDMatrix &)ss;
#ifdef DEBUG
            //				tmp_ss.print();  !! This print Crashes???
#endif
          }
        if (nlhs >= 2)
          {
            /* Set the output pointer to the combined output matrix gyu = [gy gu]. */
            int ii = 1;
            for (map<string, ConstTwoDMatrix>::const_iterator cit = mm.begin();
                 ((cit != mm.end()) && (ii < nlhs)); ++cit)
              {
                //if ((*cit).first!="g_0")
                {
                  plhs[ii] = mxCreateDoubleMatrix((*cit).second.numRows(), (*cit).second.numCols(), mxREAL);
                  TwoDMatrix dgyu((*cit).second.numRows(), (*cit).second.numCols(), mxGetPr(plhs[ii]));
                  dgyu = (const TwoDMatrix &)(*cit).second;
#ifdef DEBUG
                  mexPrintf("k_order_perturbation: cit %d print: \n", ii);
                  (*cit).second.print();
                  mexPrintf("k_order_perturbation: dguy %d print: \n", ii);
                  //                      dgyu.print(); !! This print Crashes???
#endif
                  ++ii;
                }
              }
          }
      }
    catch (const KordException &e)
      {
        printf("Caugth Kord exception: ");
        e.print();
        mexPrintf("Caugth Kord exception: %s", e.get_message());
        std::string errfile(fName); //(params.basename);
        errfile += "_error.log";
        FILE *errfd = NULL;
        if (NULL == (errfd = fopen(errfile.c_str(), "wb")))
          {
            fprintf(stderr, "Couldn't open %s for writing.\n", errfile.c_str());
            return; // e.code();
          }
        fprintf(errfd, "Caugth Kord exception: %s", e.get_message());
        fclose(errfd);
        return; // e.code();
      }
    catch (const TLException &e)
      {
        printf("Caugth TL exception: ");
        e.print();
        return; // 255;
      }
    catch (SylvException &e)
      {
        printf("Caught Sylv exception: ");
        e.printMessage();
        return; // 255;
      }
    catch (const DynareException &e)
      {
        printf("Caught KordpDynare exception: %s\n", e.message());
        mexPrintf("Caugth Dynare exception: %s", e.message());
        std::string errfile(fName); //(params.basename);
        errfile += "_error.log";
        FILE *errfd = NULL;
        if (NULL == (errfd = fopen(errfile.c_str(), "wb")))
          {
            fprintf(stderr, "Couldn't open %s for writing.\n", errfile.c_str());
            return; // e.code();
          }
        fprintf(errfd, "Caugth KordDynare  exception: %s", e.message());
        fclose(errfd);
        return; // 255;
      }
    catch (const ogu::Exception &e)
      {
        printf("Caught ogu::Exception: ");
        e.print();
        mexPrintf("Caugth general exception: %s", e.message());
        std::string errfile(fName); //(params.basename);
        errfile += "_error.log";
        FILE *errfd = NULL;
        if (NULL == (errfd = fopen(errfile.c_str(), "wb")))
          {
            fprintf(stderr, "Couldn't open %s for writing.\n", errfile.c_str());
            return; // e.code();
          }
        e.print(errfd);
        fclose(errfd);
        return; // 255;
      }  //catch
  }; // end of mexFunction()
}; // end of extern C
#endif // ifdef MATLAB_MEX_FILE  to exclude mexFunction for other applications





