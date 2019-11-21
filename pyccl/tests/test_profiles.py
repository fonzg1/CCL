import numpy as np
import pytest
import pyccl as ccl


COSMO = ccl.Cosmology(
    Omega_c=0.27, Omega_b=0.045, h=0.67, sigma8=0.8, n_s=0.96,
    transfer_function='bbks', matter_power_spectrum='linear')
M200 = ccl.halos.MassDef(200, 'critical')


def smoke_assert_prof_real(profile):
    sizes = [(0, 0),
             (2, 0),
             (0, 2),
             (2, 3),
             (1, 3),
             (3, 1)]
    shapes = [(),
              (2,),
              (2,),
              (2, 3),
              (1, 3),
              (3, 1)]
    for (sr, sm), sh in zip(sizes, shapes):
        if sr == 0:
            r = 0.5
        else:
            r = np.linspace(0., 1., sr)
        if sm == 0:
            m = 1E12
        else:
            m = np.geomspace(1E10, 1E14, sm)
        p = profile._profile_real(COSMO, r, m, 1., M200)
        assert np.shape(p) == sh


def test_profile_defaults():
    p = ccl.halos.HaloProfile()
    with pytest.raises(NotImplementedError):
        p.profile_real(None, None, None, None)
    with pytest.raises(NotImplementedError):
        p.profile_fourier(None, None, None, None)


def test_profile_nfw_smoke():
    with pytest.raises(TypeError):
        p = ccl.halos.HaloProfileNFW(None)

    c = ccl.halos.ConcentrationDuffy08(M200)
    p = ccl.halos.HaloProfileNFW(c)
    smoke_assert_prof_real(p)


def test_profile_gaussian_smoke():
    def r_s(cosmo, M, a, mdef):
        return mdef.get_radius(cosmo, M, a)

    def rho0(cosmo, M, a, mdef):
        return M

    p = ccl.halos.HaloProfileGaussian(rho0, r_s)
    smoke_assert_prof_real(p)


def test_profile_gaussian_accuracy():
    def one_f(cosmo, M, a, mdef):
        if np.ndim(M) == 0:
            return 1
        else:
            return np.ones(M.size)

    def fk(k):
        return np.pi**1.5 * np.exp(-k**2 / 4)

    p = ccl.halos.HaloProfileGaussian(one_f, one_f)
    p.update_precision_fftlog(fac_lo=0.01,
                              fac_hi=100.,
                              n_per_decade=10000)

    k_arr = np.logspace(-3, 2, 1024)
    fk_arr = p.profile_fourier(COSMO, k_arr, 1., 1.)
    fk_arr_pred = fk(k_arr)
    res = np.fabs(fk_arr - fk_arr_pred)
    assert np.all(res < 5E-3)


@pytest.mark.parametrize('alpha', [-1.2, -2., -2.8])
def test_profile_plaw_accuracy(alpha):
    from scipy.special import gamma

    prefac = (2.**(3+alpha) * np.pi**1.5 *
              gamma((3 + alpha) / 2) /
              gamma(-alpha / 2))

    def one_f(cosmo, M, a, mdef):
        if np.ndim(M) == 0:
            return 1
        else:
            return np.ones(M.size)

    def alpha_f(cosmo, M, a, mdef):
        return alpha * one_f(cosmo, M, a, mdef)

    def fk(k):
        return prefac / k**(3 + alpha)

    p = ccl.halos.HaloProfilePowerLaw(one_f, alpha_f)
    p.update_precision_fftlog(epsilon=1.5 + alpha)

    k_arr = np.logspace(-3, 2, 1024)
    fk_arr = p.profile_fourier(COSMO, k_arr, 1., 1.)
    fk_arr_pred = fk(k_arr)
    res = np.fabs(fk_arr / fk_arr_pred - 1)
    assert np.all(res < 5E-3)
