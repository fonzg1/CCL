#include <stdlib.h>

/**
 * Enable math.h/cmath constants on Windows
*/
#ifdef _WIN32
#define _USE_MATH_DEFINES
#endif
#include <math.h>

#include <complex.h>
#include <fftw3.h>

#include <gsl/gsl_sf_result.h>
#include <gsl/gsl_sf_gamma.h>

#include "fftlog.h"

#ifndef M_PI
  #define M_PI 3.14159265358979323846
#endif

/* This code is FFTLog, which is described in arXiv:astro-ph/9905191 */

static complex_double lngamma_fftlog(complex_double z)
{
  gsl_sf_result lnr, phi;
  gsl_sf_lngamma_complex_e(creal(z), cimag(z), &lnr, &phi);
#ifdef _MSC_VER
  complex_double retval = { lnr.val, phi.val };
  return retval;
#else
  return lnr.val + I * phi.val;
#endif
}

static complex_double gamma_fftlog(complex_double z)
{
  return cexp(lngamma_fftlog(z));
}

static complex_double polar (double r, double phi)
{
#ifdef _MSC_VER
  complex_double retval = { r * cos(phi),  (r * sin(phi)) };
  return retval;
#else
  return (r * cos(phi) + I * (r * sin(phi)));
#endif
}

static void lngamma_4(double x, double y, double* lnr, double* arg)
{
#ifdef _MSC_VER
  complex_double tmp = { x,  y };
  complex_double w = lngamma_fftlog(tmp);
#else
    complex_double w = lngamma_fftlog(x + y * I);
#endif
  if(lnr) *lnr = creal(w);
  if(arg) *arg = cimag(w);
}

static double goodkr(int N, double mu, double q, double L, double kr)
{
  double xp = (mu+1+q)/2;
  double xm = (mu+1-q)/2;
  double y = M_PI*N/(2*L);
  double lnr, argm, argp;
  lngamma_4(xp, y, &lnr, &argp);
  lngamma_4(xm, y, &lnr, &argm);
  double arg = log(2/kr) * N/L + (argp + argm)/M_PI;
  double iarg = round(arg);
  if(arg != iarg)
    kr *= exp((arg - iarg)*L/N);
  return kr;
}

void compute_u_coefficients(int N, double mu, double q, double L, double kcrc, complex_double u[])
{
  double y = M_PI/L;
  double k0r0 = kcrc * exp(-L);
  double t = -2*y*log(k0r0/2);

  if(q == 0) {
    double x = (mu+1)/2;
    double lnr, phi;
    for(int m = 0; m <= N/2; m++) {
      lngamma_4(x, m*y, &lnr, &phi);
      u[m] = polar(1.0,m*t + 2*phi);
    }
  }
  else {
    double xp = (mu+1+q)/2;
    double xm = (mu+1-q)/2;
    double lnrp, phip, lnrm, phim;
    for(int m = 0; m <= N/2; m++) {
      lngamma_4(xp, m*y, &lnrp, &phip);
      lngamma_4(xm, m*y, &lnrm, &phim);
      u[m] = polar(exp(q*log(2) + lnrp - lnrm), m*t + phip - phim);
    }
  }

  for(int m = N/2+1; m < N; m++)
    u[m] = conj(u[N-m]);
  if ((N % 2) == 0) {
#ifdef _MSC_VER
    complex_double tmp = { creal(u[N / 2]),  0.0f };
    u[N / 2] = tmp;
#else
    u[N / 2] = (creal(u[N / 2]) + I * 0.0);
#endif
  }

}

void fht(int N, const double r[], const complex_double a[], double k[], complex_double b[], double mu,
         double q, double kcrc, int noring, complex_double* u)
{
  double L = log(r[N-1]/r[0]) * N/(N-1.);
  complex_double* ulocal = NULL;
  if(u == NULL) {
    if(noring)
      kcrc = goodkr(N, mu, q, L, kcrc);
    ulocal = malloc (sizeof(complex_double)*N);
    compute_u_coefficients(N, mu, q, L, kcrc, ulocal);
    u = ulocal;
  }

  /* Compute the convolution b = a*u using FFTs */
  fftw_plan forward_plan = fftw_plan_dft_1d(N, (fftw_complex*) a, (fftw_complex*) b,  -1, FFTW_ESTIMATE);
  fftw_plan reverse_plan = fftw_plan_dft_1d(N, (fftw_complex*) b, (fftw_complex*) b, +1, FFTW_ESTIMATE);
  fftw_execute(forward_plan);
  for (int m = 0; m < N; m++) {
#ifdef _MSC_VER
    complex_double tmp = { creal(u[m]) / (double)N, cimag(u[m]) / (double)N };
    b[m] = _Cmulcc(b[m], tmp);
#else
    b[m] *= u[m] / (double)(N);       // divide by N since FFTW doesn't normalize the inverse FFT
#endif
  }
  fftw_execute(reverse_plan);
  fftw_destroy_plan(forward_plan);
  fftw_destroy_plan(reverse_plan);

  /* Reverse b array */
  complex_double tmp;
  for(int n = 0; n < N/2; n++) {
    tmp = b[n];
    b[n] = b[N-n-1];
    b[N-n-1] = tmp;
  }

  /* Compute k's corresponding to input r's */
  double k0r0 = kcrc * exp(-L);
  k[0] = k0r0/r[0];
  for(int n = 1; n < N; n++)
    k[n] = k[0] * exp(n*L/N);

  free(ulocal);
}

void fftlog_ComputeXi2D(double bessel_order,int N,const double l[],const double cl[],
			double th[], double xi[])
{
  complex_double* a = malloc(sizeof(complex_double)*N);
  complex_double* b = malloc(sizeof(complex_double)*N);

  for (int i = 0; i < N; i++) {
#ifdef _MSC_VER
      complex_double tmp = { l[i] * cl[i], 0.0f };
      a[i] = tmp;
#else
    a[i] = l[i] * cl[i];
#endif
  }
  
  fht(N,l,a,th,b,bessel_order,0,1,1,NULL);

  for (int i = 0; i < N; i++) {
#ifdef _MSC_VER
    xi[i] = creal(b[i]) / (2 * M_PI * th[i]);
#else
    xi[i] = creal(b[i] / (2 * M_PI * th[i]));
#endif
  } 

  free(a);
  free(b);
}

void fftlog_ComputeXiLM(double l, double m, int N, const double k[], const double pk[],
			double r[], double xi[])
{
  complex_double* a = malloc(sizeof(complex_double)*N);
  complex_double* b = malloc(sizeof(complex_double)*N);

  for (int i = 0; i < N; i++) {
#ifdef _MSC_VER
    complex_double tmp = { pow(k[i], m - 0.5) * pk[i], 0.0f };
    a[i] = tmp;
#else
    a[i] = pow(k[i], m - 0.5) * pk[i];
#endif
  }

  fht(N, k, a, r, b, l + 0.5, 0, 1, 1, NULL);
  
  for (int i = 0; i < N; i++) {
#ifdef _MSC_VER
    xi[i] = pow(2 * M_PI * r[i], -(m - 0.5)) * creal(b[i]);
#else
    xi[i] = creal(pow(2 * M_PI * r[i], -(m - 0.5)) * b[i]);
#endif
  }
  
  free(a);
  free(b);
}

void pk2xi(int N, const double k[], const double pk[], double r[], double xi[])
{
  fftlog_ComputeXiLM(0, 2, N, k, pk, r, xi);
}

void xi2pk(int N, const double r[], const double xi[], double k[], double pk[])
{
  static const double TwoPiCubed = 8*M_PI*M_PI*M_PI;
  fftlog_ComputeXiLM(0, 2, N, r, xi, k, pk);
  for(int j = 0; j < N; j++)
    pk[j] *= TwoPiCubed;
}
