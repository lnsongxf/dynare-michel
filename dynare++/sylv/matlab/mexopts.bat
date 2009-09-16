@echo off
rem $Header: /var/lib/cvs/dynare_cpp/sylv/matlab/mexopts.bat,v 1.1.1.1 2004/06/04 13:01:13 kamenik Exp $
rem Tag $Name:  $
rem c:\ondra\wk\sylv\matlab\mexopts.bat
rem Generated by gnumex.m script in c:\fs\gnumex
rem gnumex version: 1.08
rem Compile and link options used for building MEX etc files with
rem the Mingw/Cygwin tools.  Options here are:
rem Cygwin (cygwin*.dll) linking
rem Mex file creation
rem Standard (safe) linking to temporary libraries
rem Language C / C++
rem Matlab version 6.5
rem
set MATLAB=C:\MATLAB~2
set GM_PERLPATH=C:\MATLAB~2\sys\perl\win32\bin\perl.exe
set GM_UTIL_PATH=c:\fs\gnumex
set PATH=C:\fs\cygwin\bin;%PATH%
rem
rem Added libraries for linking
set GM_ADD_LIBS=
rem
rem Type of file to compile (mex or engine)
set GM_MEXTYPE=mex
rem
rem Language for compilation
set GM_MEXLANG=c
rem
rem def files to be converted to libs
set GM_DEFS2LINK=libmx.def;libmex.def;libmat.def;_libmatlbmx.def;
rem
rem dlltool command line
set GM_DLLTOOL=c:\fs\gnumex\mexdlltool -E --as C:\fs\cygwin\bin\as.exe
rem
rem compiler options; add compiler flags to compflags as desired
set NAME_OBJECT=-o
set COMPILER=gcc
set COMPFLAGS=-c -DMATLAB_MEX_FILE 
set OPTIMFLAGS=-O3 -mcpu=pentium -malign-double
set DEBUGFLAGS=-g
set CPPCOMPFLAGS=%COMPFLAGS% -x c++ 
set CPPOPTIMFLAGS=%OPTIMFLAGS%
set CPPDEBUGFLAGS=%DEBUGFLAGS%
rem
rem NB Library creation commands occur in linker scripts
rem
rem Linker parameters
set LINKER=%GM_PERLPATH% %GM_UTIL_PATH%\linkmex.pl
set LINKFLAGS=
set CPPLINKFLAGS= --driver-name c++ 
set LINKOPTIMFLAGS=-s
set LINKDEBUGFLAGS=-g
set LINK_FILE=
set LINK_LIB=
set NAME_OUTPUT=-o %OUTDIR%%MEX_NAME%.dll
rem
rem Resource compiler parameters
set RC_COMPILER=%GM_PERLPATH% %GM_UTIL_PATH%\rccompile.pl --unix -o %OUTDIR%mexversion.res
set RC_LINKER=