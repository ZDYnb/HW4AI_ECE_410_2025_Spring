import numpy as np
import matplotlib.pyplot as plt

# === Define Differential Equations ===
def ode1(t, y):  # dy/dt = -2y
    return -2 * y

def ode2(t, y):  # dy/dt = sin(t)
    return np.sin(t)

def ode3(t, y):  # dy/dt = y^2 - 1
    return y**2 - 1

# === Analytical (Exact) Solutions ===
def exact1(t):  # y(t) = exp(-2t), from dy/dt = -2y, y(0)=1
    return np.exp(-2 * t)

def exact2(t):  # y(t) = 1 - cos(t), from dy/dt = sin(t), y(0)=0
    return 1 - np.cos(t)

# === RK4 Solver ===
def runge_kutta_4(f, t0, y0, t_end, h):
    t_values = [t0]
    y_values = [y0]

    t = t0
    y = y0

    while t < t_end:
        k1 = f(t, y)
        k2 = f(t + h/2, y + h * k1 / 2)
        k3 = f(t + h/2, y + h * k2 / 2)
        k4 = f(t + h, y + h * k3)

        y += h * (k1 + 2*k2 + 2*k3 + k4) / 6
        t += h

        t_values.append(t)
        y_values.append(y)

    # ✅ Only print final result
    print(f"✅ Final value for {f.__name__}: y({t_end}) = {y:.6f}")
    return np.array(t_values), np.array(y_values)

# === Solve and Plot with Optional Exact Solution ===
def solve_and_plot(f, y0, title, true_solution=None):
    t0 = 0
    t_end = 5
    h = 0.2
    t_vals, y_vals = runge_kutta_4(f, t0, y0, t_end, h)

    # Plot RK4 result
    plt.plot(t_vals, y_vals, 'o-', label=title + " (RK4)")

    if true_solution is not None:
        true_vals = true_solution(t_vals)
        plt.plot(t_vals, true_vals, '--', label=title + " (Exact)", alpha=0.7)
        max_err = np.max(np.abs(true_vals - y_vals))
        print(f"🧪 Max Error for {title}: {max_err:.6f}")
    else:
        print(f"❗ No exact solution provided for: {title}")

# === Main Plot ===
plt.figure(figsize=(10, 6))

solve_and_plot(ode1, 1, "dy/dt = -2y", true_solution=exact1)
solve_and_plot(ode2, 0, "dy/dt = sin(t)", true_solution=exact2)
solve_and_plot(ode3, 0.5, "dy/dt = y^2 - 1")  # No known exact solution

plt.title("RK4 Solution vs Analytical Solution")
plt.xlabel("t")
plt.ylabel("y(t)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()

