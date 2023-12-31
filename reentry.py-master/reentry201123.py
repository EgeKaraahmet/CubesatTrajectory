# ===---------------------------------------------------------------------------------------------===
# reentry.py - Simple euler solver for spacecraft reentries.
import math
import numpy as np
from msise_90 import database

atm = database()

rho0   = 1.225         # sea level density of atmosphere (kg/m^3)
R = 287.4              # specific gas constant for air
K = 1.4                # ratio of specific heat of a gas at a constant pressure to heat at a constant volume (1.4 for air)
T0 = 288.15            # K standard temperature at sea level
M = 6
A = 0.01



class Planet(object):
    """ Base class for planetary bodies.
  allows us to define more complex atmospheric models down the road, and to do coordinate system
  conversions.
  """
    radius = 0
    grav_k = 0
    name = ""

    def __init__(self, radius, grav_k):
        self.radius = radius
        self.grav_k = grav_k

    def gravity(self, r):
        return -(self.grav_k / (r ** 2.0))

    def altitude(self, pos):
        return np.linalg.norm(pos) - self.radius

    def cartesian(self, lat, alt):
        r = alt + self.radius
        return r * np.cos(lat), r * np.sin(lat)

    def polar(self, x, y):
        alt = np.sqrt(x ** 2 + y ** 2) - self.radius
        return np.arctan2(x, y), alt

    def density(self, alt):
        return 0


# Scale Height is defined for T=15C (288.15K)
class Earth(Planet):
    def __init__(self):
        Planet.__init__(self, 6371e3, 3.986004418e14)

    def density(self, alt):
        return 1.221 * np.exp(- alt / 8.43e3)




def sim_run141123(sim, planet, craft):
    """ Calculates the trajectory & loads of a craft reentering atmosphere on a planetary body
  Basic models
   - g = GM / r^2               -> towards body centre
   - Drag = 0.5*rho*v^2 / Beta  -> opposite velocity vector
   - Lift = L/D * Drag          -> normal to velocity vector
  """
    # Initialise our position, velocity, and acceleration components
    max_it = sim['max_it']
    dt = sim['delta_t']
    fpa = np.radians(sim['fpa'])

    p = np.array([0, sim['entry_interface'] + planet.radius])
    x = np.zeros(max_it)
    y = np.zeros(max_it)

    v = sim['velocity'] * np.array([np.cos(fpa), np.sin(fpa)])
    vx = np.zeros(max_it)
    vy = np.zeros(max_it)

    ax = np.zeros(max_it)
    ay = np.zeros(max_it)

    t = np.arange(0, max_it * dt, dt)

    # Cb = M / Cd*S

    # beta = craft['ballistic_coef']
    # beta_parachute = craft['ballistic_coef_parachute']
    ld = craft['lift_drag']


    w = 7.2921159 * 1e-5
    earth_rotation = np.array([[0, w], [-w, 0]])

    # (doesn't take parachute into acount -- decent would slow down then)
    k = 0
    for _ in range(0, max_it):
            if k % 50000 == 0:
               print(k)
            p_prev = p
            v_prev = v
            r_prev = np.linalg.norm(p_prev)
            # rho_prev = atm.get_atmospheric_data(planet.altitude(p_prev)/1e3)    # Medium solar activity considered

            alt_km_prev = (planet.altitude(p_prev)/1e3)
            T_prev, rho_prev, p_prev = atm.get_atmospheric_data(alt_km_prev)
            # rho_prev = planet.density(planet.altitude(p_prev))            # exponential model
            v_relative_mag_prev = np.linalg.norm(v_prev - np.dot(earth_rotation, p_prev))
            v_abs_mag_prev = np.linalg.norm(v_prev)                            # absolute velocity mag

            # get CLa, CD0 for Mach number (from tables)
            mach_prev = v_abs_mag_prev / math.sqrt(K * R * T_prev)
            Cd_prev = atm.get_mach_data(mach_prev)  # drag coefficient
            beta_prev = M /(Cd_prev * A)
            normal_prev = np.array([v_prev[1],v_prev[0]])

            # aerodynamic acceleration
            aero_accel_prev = 0.5 * rho_prev * v_relative_mag_prev * (ld * normal_prev / beta_prev - v_prev / beta_prev)

            # gravitational acceleration
            gravity_accel_prev = planet.gravity(r_prev) * (p_prev / r_prev)

            a_prev = aero_accel_prev + gravity_accel_prev

            # Improved Euler's method
            p = p_prev + v_prev * dt
            v = v_prev + a_prev * dt

            r = np.linalg.norm(p)


            alt_km = (planet.altitude(p) / 1e3)
            T, rho, p = atm.get_atmospheric_data(alt_km)
            # rho = planet.density(planet.altitude(p))          # Expoential model
            v_abs_mag = np.linalg.norm(v)
            v_relative_mag = np.linalg.norm(v - np.dot(earth_rotation, p))
            normal = np.array([v[1], v[0]])

            # get CLa, CD0 for Mach number (from tables)
            mach = v_abs_mag / math.sqrt(K * R * T)
            Cd = atm.get_mach_data(mach)  # drag coefficient
            beta = M / (Cd * A)
            # aerodynamic acceleration
            aero_accel = 0.5 * rho * v_relative_mag * (ld * normal / beta - v / beta)

            # gravitational acceleration
            gravity_accel = planet.gravity(r) * (p / r)

            a = aero_accel + gravity_accel
            ax[k], ay[k] = a

            v = v_prev + 0.5 * (a_prev + a) * dt
            vx[k], vy[k] = v
            p = p_prev + 0.5 * (v_prev + v) * dt
            x[k], y[k] = p
            k += 1

            if planet.altitude(p) <= sim['stop_alt']:
                print('done in %d iterations' % k)
                break

    return (
        np.resize(x, k),
        np.resize(y, k),
        np.resize(vx, k),
        np.resize(vy, k),
        np.resize(ax, k),
        np.resize(ay, k),
        np.resize(t, k)
    )


def do_plot(ax,xlabel, x, ylabel, y, label, title):
    """ Basic utility function to simplify plotting
  """
    ax.plot(x, y, label=label)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.legend()
    # plt.savefig(fname, dpi=300)