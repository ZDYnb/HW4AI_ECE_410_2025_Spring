# Challenge #3 
**Eric Zhou**  
**April 13, 2025**

Challenge #3
Use the power of the internet and of LLMs to identify a physical system that solves differential equations inherently, through its physical properties, without executing instructions as a traditional processor does.

In this challenge, we discover any natural system to solve the differential equations, without any use of digital logic, CPUs, or stored instructions.

Based on searching and asking around gpt and internet:
RC / RLC Circuits -1st/2nd-order ODEs
RC
  V_in(t)
   ┌───┬────R────┬────┐
   │   │         │    │
   │  (+)       [C]   │
   │   │         │    │
   └───┴─────────┴────┘
               V_out(t)

1. **Kirchhoff’s Voltage Law:**
   \[
   V_{\text{in}}(t) = V_R(t) + V_C(t)
   \]

2. **Ohm’s Law:**  
   \( V_R = i \cdot R \)

3. **Capacitor Relationship:**  
   \( i = C \frac{dV_C}{dt} \)

4. **Substitute:**
   \[
   V_{\text{in}}(t) = RC \frac{dV_C}{dt} + V_C(t)
   \]

This is a **first-order linear ODE**.

RLC circuit
A resistor (R), inductor (L), and capacitor (C) in series:

1. Apply KVL:
   \[
   V_{\text{in}}(t) = V_R + V_L + V_C
   \]

2. Component Laws:
   - \( V_R = iR \)
   - \( V_L = L \frac{di}{dt} \)
   - \( V_C = \frac{1}{C} \int i \, dt \)

3. Differentiate both sides:
   \[
   \frac{dV_{\text{in}}}{dt} = R \frac{di}{dt} + L \frac{d^2i}{dt^2} + \frac{i}{C}
   \]

Or rearranged:
   \[
   L \frac{d^2 i}{dt^2} + R \frac{di}{dt} + \frac{1}{C} i = \frac{dV_{\text{in}}}{dt}
   \]

This is a **second-order linear ODE**.

---

Op-Amp Analog Computers - Arbitrary linear/nonlinear ODEs

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


Water Tank System -Rate equations (ODEs)

Imagine a vertical cylindrical water tank with inflow and outflow.

Mechanical Integrators (e.g., Ball-and-Disk) ∫f(t)dt


Use physical motion — such as rotation, position, and friction — to represent mathematical variables and perform integration through geometry and kinematics.

Completely mechanical — no electricity or logic circuits!

Used in WWII fire-control computers to calculate projectile trajectories.

Solves integration in real time, continuous and accurate (for its time).

