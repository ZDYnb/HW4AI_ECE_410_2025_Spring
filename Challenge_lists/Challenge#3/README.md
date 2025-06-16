# Challenge #3

**Eric Zhou**  
**April 13, 2025**

## Challenge Overview

Leverage the power of the internet and large language models (LLMs) to identify physical systems that inherently solve differential equations through their physical properties—without executing instructions like a traditional processor.

The goal: Discover natural or engineered systems that solve differential equations without digital logic, CPUs, or stored instructions.

---

## Examples of Physical Systems Solving Differential Equations

### 1. RC and RLC Circuits

#### RC Circuit (First-Order ODE)

An RC circuit (resistor and capacitor in series) inherently solves a first-order linear ordinary differential equation (ODE):

```
V_in(t)
 ┌───┬────R────┬────┐
 │   │         │    │
 │  (+)       [C]   │
 │   │         │    │
 └───┴─────────┴────┘
          V_out(t)
```

- **Kirchhoff’s Voltage Law:**  
  \[
  V_{\text{in}}(t) = V_R(t) + V_C(t)
  \]
- **Ohm’s Law:**  
  \( V_R = i \cdot R \)
- **Capacitor Current-Voltage Relationship:**  
  \( i = C \frac{dV_C}{dt} \)
- **Combined:**  
  \[
  V_{\text{in}}(t) = RC \frac{dV_C}{dt} + V_C(t)
  \]

This is a **first-order linear ODE**.

---

#### RLC Circuit (Second-Order ODE)

A series RLC circuit (resistor, inductor, capacitor) solves a second-order linear ODE:

- **KVL:**  
  \[
  V_{\text{in}}(t) = V_R + V_L + V_C
  \]
- **Component Laws:**  
  - \( V_R = iR \)
  - \( V_L = L \frac{di}{dt} \)
  - \( V_C = \frac{1}{C} \int i \, dt \)
- **Differentiated:**  
  \[
  L \frac{d^2 i}{dt^2} + R \frac{di}{dt} + \frac{1}{C} i = \frac{dV_{\text{in}}}{dt}
  \]

This is a **second-order linear ODE**.

---

### 2. Op-Amp Analog Computers

Op-amp-based analog computers can solve arbitrary linear and some nonlinear ODEs by configuring networks of amplifiers, summers, and integrators:

```
[INPUT u(t)] --> [×c gain amp] --+
                         |
                      [SUMMING NODE]
                      /     |     \
                     ↓      ↓      ↓
                   -a×dx   -b×x   → d²x/dt²
                      |      |       ↓
                      |      |   [INTEGRATOR]
                      |      |       ↓
                   [GAIN]  [GAIN]   [dx/dt]
                      |      |       ↓
                      +------┴----> [INTEGRATOR] --> x(t)
```

---

### 3. Water Tank System

A vertical cylindrical water tank with inflow and outflow models rate equations (ODEs) through fluid dynamics. The water level changes according to the difference between inflow and outflow rates, inherently solving a first-order ODE.

---

### 4. Mechanical Integrators

Mechanical devices (e.g., ball-and-disk integrators) use physical motion—rotation, position, and friction—to represent variables and perform integration:

- Entirely mechanical—no electricity or logic circuits.
- Used in WWII fire-control computers for real-time trajectory calculations.
- Solves integration continuously and in real time.

---

## Summary

Physical systems—electrical, mechanical, and fluidic—can inherently solve differential equations by exploiting their natural laws, offering real-time, continuous solutions without digital computation.
