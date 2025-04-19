# Challenge #10
**Eric Zhou**  
**April 16, 2025**

intro:
In challenge #9, we start to brainstorm the potential topic we will go through this term in the left 7 weeks. However, as we didn't have enough confidence and clear mind about how really we will play around our co-design, in this challenge we will walk ourself through the co-design process of a basic Reinforcement learning algorithm for FrozenLake problem. Compeleting this challenge will empower us a sense about how we can analyze our choosing algorithm and how we can implement our hardware co-design through HDL. The code we used was from this repo: https://github.com/ronanmmurphy/Q-Learning-Algorithm
Basically our task is to using RL to train a model to run a robot across the Frozen lake envirment. For training the model, RL in this task will go through thousands of Q-learning loops of computing mutiple and accumlating in its updating process. So I predict the main job in optizing of such algorithm will mainly focus on that.
basic algurithm analysis:
For optimizing our code into hardware, we should first get a sense of how the algorithm run.
Instead of traditional way digging ourselve into the code, first we could just do rough analysis with our expert - GPT. We could just ask GPT about potential bottleneck in our code by shipping the code into the chat prompt:
Hey chat, Can you help me anayze computational bottlenecks of my code?(attechment is the code)
it pointed out to the 🔁 Main Training Loop (Agent.Q_Learning())
The training logic is executed in a loop:
while(x < episodes):
    ...
This loop runs up to 10,000 times (based on user-defined episodes). We analyze each major component inside this loop for computational cost.

📦 Q-Table Copy
self.Q = self.new_Q.copy()
Runs every episode or transition.

Involves copying a dictionary with 5×5×4 = 100 entries.

⚠️ Minor Bottleneck: Could be optimized by updating only changed keys instead of copying the whole table.

🖨️ Debug Printing
print(self.Q)
Large dictionary (100 entries) printed to console.

Extremely slow when called during or after training.

⛔ Significant Bottleneck for console I/O. Recommend commenting this out during batch training.

above is the pointed out bottleneck. How to deal with the operation in the loop will be critical. As above it pointed out, the main bottleneck comes from pringting result and Q-table copy. It make sense as printing our did slow down the process as you will take tiem to show the result in the terminal. But it does not make sense that printing debug result is the main concern because it not actually quite a part of computing... I asked got to give me some senses of why it choose this as such bottleneck, it pointed out that print(self.Q) is an  an I/O bottleneck that can drastically slow down your training loop. There are different kinds of bottleneck:
Type	Example	Affects
Compute-bound	Matrix ops, value updates	CPU/GPU usage
Memory-bound	Copying big arrays	RAM access
I/O-bound	print(), disk writes	Output speed
Algorithmic	Nested loops over big data	Total ops
In order to get my expected answer, I keep asking: “What is the true computational bottleneck of this code — in terms of the algorithm itself, not terminal output?”
Your code runs Q-learning over episodes = 10,000. Each episode consists of:

Repeatedly:

Choosing an action via epsilon-greedy

Transitioning to the next state

Calculating reward

Updating Q-values

Until terminal state is reached (either win or hole)

This happens again and again for each episode. So what makes it slow?
Let’s look at the core operations of each episode:

⚙️ Agent.Q_Learning() core loop
for a in self.actions:
    q_value = (1 - alpha) * Q[state, action] + alpha * (reward + gamma * Q[next_state, a])
Per step: Loop over 4 actions → Small

But this is done many steps per episode, and 10000 episodes.

So individually fast, but over time this accumulates.

🔁 🔁 Loop Depth Analysis
Let's define:
S = average steps per episode (e.g., ~10–25 if grid is small)
E = number of episodes (e.g., 10,000)
A = number of actions (always 4)
Then:
Total core Q-value update operations = S × E × A
                                     ≈ 25 × 10000 × 4 = 1,000,000 ops
For Python + dictionaries, 1M updates is not super fast — especially since:

You're using dict lookup: self.Q[(i, j, a)]

Python dictionaries are fast, but still slower than NumPy arrays or native types

❗ (3) Actual Computational Bottlenecks

Component	Bottleneck Level	Why
Q[(i, j, a)] dict access	⚠️ Moderate	~1M lookups over episodes → Python dicts are slow vs arrays
self.Q = self.new_Q.copy()	⚠️ Moderate	Redundant full copy, 100 keys, every episode
Q-value update math	✅ Efficient	Simple formula; fast
epsilon-greedy selection	✅ Efficient	Only 4 actions; fast
🚀 (4) How to Fix / Optimize
Option 1: Replace dict with NumPy arrays
Replace:
self.Q = {}
self.Q = np.zeros((5, 5, 4))
Then access with:
q_value = self.Q[i, j, a]
✅ Much faster memory access and computation.

Option 2: Avoid full copy of new_Q
Right now you're doing:
self.Q = self.new_Q.copy()
Instead:
Update values in-place
Or just use self.Q only — no need for new_Q
🧠 Summary: Real Computational Bottlenecks
True Bottleneck	Why it matters
Python dict Q-table	Slower than arrays. Causes latency when accessed 1M+ times.
Unnecessary copy	self.Q = self.new_Q.copy() done frequently, adds extra cost.
Interpretive overhead	Python is slow compared to C/NumPy for tight loops; minor for small grids.

As mentioned above, every operation in the loop would be a concern, especially the memory table access. Surely we should not ignore the computation of updating Q and exploring environment. Based on that, I ask it to propose a HW implementation of the bottleneck.
Reply:
Software Bottleneck	Hardware Perspective	Why It's Costly in HW
Q[(i, j, a)] access	RAM access (lookup latency)	Dict-style access = random access in memory
Q-update computation	FMA ops (add + mul)	Needs fast arithmetic, usually pipelined
Epsilon-greedy action choice	Comparator & random logic	Needs max Q-selection + RNG decision logic
So in hardware, these map to:

🔁 Loop computation =
Access Q-table memory

Compute Q update

Choose next action

Repeat

🧠 (2) HW Block Diagram: Accelerated Q-Learning Engine
🎯 Goal:
Design a custom hardware block (e.g. in FPGA or ASIC) that does:

Fast Q-table access

Pipelined update

Parallel action evaluation

┌──────────────────────────────────────────────┐
│              Q-Learning Accelerator          │
├──────────────────────────────────────────────┤
│                                              │
│  ┌────────────┐    ┌─────────────┐           │
│  │ State ROM  │    │ RNG + Epsilon│           │
│  └────────────┘    └─────────────┘           │
│         │                  │                 │
│         ▼                  ▼                 │
│     ┌───────────────┐   ┌───────────────┐     │
│     │ Q-Table (SRAM)│<--│ Max/Compare   │<────┘
│     └───────────────┘   └───────────────┘      
│          │  ▲                 ▲                
│          │  └─────┐      ┌────┘                
│          ▼        ▼      ▼                     
│     ┌────────────────────────┐                 
│     │   Q-value Update Unit   │ ◄─ Reward       │
│     └────────────────────────┘                 
│           │                                     
│           ▼                                     
│    Updated Q-values → Back to SRAM             
└──────────────────────────────────────────────┘
⚙️ (3) Breakdown of Hardware Modules
📚 Q-Table Memory (SRAM)
3D structure: Q[state_row][state_col][action]

Stores 5x5x4 = 100 entries

32-bit fixed-point recommended

Use dual-port SRAM to read + write simultaneously

➕ Q-value Update Unit
Implements this equation:

Q(s,a) = (1 - α) * Q(s,a) + α * (r + γ * max_a' Q(s',a'))

Hardware needs:
2 multipliers
2 adders
Pipeline latency ~2–3 cycles

🎲 Epsilon-Greedy Unit
RNG unit (e.g. LFSR) to generate [0,1] float

Compare with ε to decide:

Explore → choose random action

Exploit → choose argmax Q(s,a)

🔍 Max Q Selector
Compares all 4 Q-values at s

Returns best action + value

Done in 3 comparator stages (log2(4))

💡 (4) Optimization Strategy
Option 1: Fully pipelined
One episode step per clock cycle (after pipeline fill)

High throughput

Option 2: Loop unrolling for multiple agents
Run many agents in parallel to speed up convergence (like in DQN)

Each agent has its own Q-table slice

🧪 (5) Practical Feasibility

Platform	Feasibility	Notes
FPGA	✅ Very good	Fast, flexible. Use BRAMs + fixed-point units
ASIC	✅ Excellent	Can hard-wire reward function, learning rates
GPU	⚠️ Not ideal	Good for batch training, not small grid logic
📌 Conclusion
Your Q-learning bottleneck (Q-table access and update) maps well to a custom hardware accelerator design:


Target	Purpose
SRAM	Fast Q-value lookup (Q[s,a])
Arithmetic unit	Pipelined Q-update
RNG + comparator	Epsilon-greedy policy execution
This kind of accelerator could easily outperform software implementations on embedded agents, and is a great candidate for research (esp. tiny RL ASICs or on-chip learning controllers).
Would you like a Verilog-style block template, or a diagram of a single-cycle Q-update engine as a next step?

Great output generated from gpt! As it reach out, I also couldn't wait it to generate me the code for a test 

Awesome! Let's generate a SystemVerilog module that captures the core of the Q-learning update logic, based on your algorithm:
✅ What This Module Implements:
Q-table stored in BRAM (modeled as a 3D array: state_row, state_col, action)

Inputs:

state, action, reward, next_state

Control signals:

start to trigger update

done to signal finish

Parameters:

ALPHA and GAMMA as constants

📦 Assumptions:
State grid: 5x5, Actions: 4 → Q-table = [5][5][4]

Data type: fixed-point (Qm.n, here simplified as 16-bit integers for clarity)

You can later upgrade this to full fixed-point/floating-point support.

🧠 SystemVerilog Module: q_update_unit.sv
systemverilog

module q_update_unit #(
    parameter STATE_W = 3,         // log2(5) = 3 bits
    parameter ACTION_W = 2,        // log2(4) = 2 bits
    parameter Q_WIDTH = 16,        // fixed-point Q-value width
    parameter ALPHA = 16'd3277,    // ~0.05 in Q1.15 format
    parameter GAMMA = 16'd29491    // ~0.9 in Q1.15 format
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic [STATE_W-1:0] curr_row,
    input  logic [STATE_W-1:0] curr_col,
    input  logic [ACTION_W-1:0] curr_action,
    input  logic signed [Q_WIDTH-1:0] reward,
    input  logic [STATE_W-1:0] next_row,
    input  logic [STATE_W-1:0] next_col,
    output logic done
);

    // Q-table
    logic signed [Q_WIDTH-1:0] Q_table [0:4][0:4][0:3];

    // Internal registers
    logic signed [Q_WIDTH-1:0] Q_sa, Q_max_next;
    logic [1:0] a;
    logic [2:0] state;

    typedef enum logic [1:0] {
        IDLE, READ_MAX, CALC_UPDATE, WRITE_BACK
    } state_t;

    state_t curr_state, next_state;

    // Control logic FSM
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end

    // FSM transitions
    always_comb begin
        case (curr_state)
            IDLE:       next_state = start ? READ_MAX : IDLE;
            READ_MAX:   next_state = CALC_UPDATE;
            CALC_UPDATE:next_state = WRITE_BACK;
            WRITE_BACK: next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    // FSM output logic
    always_ff @(posedge clk) begin
        if (rst) begin
            Q_max_next <= 0;
            done <= 0;
        end else begin
            case (curr_state)
                READ_MAX: begin
                    Q_max_next <= Q_table[next_row][next_col][0];
                    for (a = 1; a < 4; a++) begin
                        if (Q_table[next_row][next_col][a] > Q_max_next)
                            Q_max_next <= Q_table[next_row][next_col][a];
                    end
                end

                CALC_UPDATE: begin
                    Q_sa <= Q_table[curr_row][curr_col][curr_action];

                    // Q_new = (1 - alpha) * Q_sa + alpha * (r + gamma * Q_max_next)
                    // Using fixed-point multiplication approximation
                    Q_sa <= ((Q_sa * (16'd32767 - ALPHA)) >> 15)
                          + (ALPHA * (reward + ((GAMMA * Q_max_next) >> 15)) >> 15);
                end

                WRITE_BACK: begin
                    Q_table[curr_row][curr_col][curr_action] <= Q_sa;
                    done <= 1;
                end

                IDLE: done <= 0;
            endcase
        end
    end

endmodule
✅ Features:
Fully pipelined FSM: IDLE → READ → CALC → WRITE

Uses fixed-point math (Q1.15 format for multipliers)

Easily scalable to different grid sizes or deeper pipelines

🧪 Next Steps:
Testbench? Want me to generate a Verilog testbench to simulate it?

Multi-agent version? We can extend it for many agents or batches.

Resource estimate? I can estimate LUT/BRAM/FF usage on FPGA for this.

Let me know if you want the testbench or want to synthesize for an FPGA (e.g., Xilinx or Intel)!


Great! Then I ask "We have gone through analysis of bottleneck and HW implementation of verilog, how should I test my verilog code and compare with my orginal code?"

xcellent question, Eric — you’ve now reached the hardware/software co-verification stage, which is a critical step in testing and validating your custom Verilog implementation against the original Python code.

Let’s break this into concrete, engineering-level steps for testing and comparison:

✅ Objective
You want to verify that your SystemVerilog Q-update module behaves identically (or very closely) to the logic in your Python Q-learning code — particularly the core Q-value update step.

🧩 Step-by-step Plan to Test and Compare Verilog vs Python
🧠 Part 1: Identify the comparable logic
Let’s isolate the most important Q-learning update rule from your Python code:

q_value = (1 - alpha) * Q[(i,j,action)] + alpha * (reward + gamma * Q[(next_i, next_j, a)])
Your Verilog code implements this using fixed-point math. So, the goal is to test:

For a given (s, a, s', r) input tuple,

The Verilog and Python modules should produce the same (or very close) new Q(s,a).

🛠️ Part 2: Generate input vectors (from Python)
Create a Python script that exports Q-update test vectors to a file for Verilog testbench.

✔️ Example:
import numpy as np
import csv

# fixed test input
alpha = 0.5
gamma = 0.9

# test data
test_cases = [
    # curr_row, curr_col, curr_action, next_row, next_col, reward, Q(s,a), max_a(Q(s'))
    (1, 1, 2, 2, 2, -1, 0.5, 0.9),
    (0, 0, 1, 0, 1, -1, 0.2, 0.4),
    (2, 3, 3, 4, 4, 1, 0.0, 1.0),
    (4, 2, 0, 4, 3, -5, 0.8, 0.3),
]

with open("test_vectors.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["s_row", "s_col", "action", "next_row", "next_col", "reward", "Q_sa", "Q_max_next"])
    for case in test_cases:
        writer.writerow(case)
✅ This gives you structured inputs for Verilog.

💻 Part 3: Create a Verilog Testbench to read vectors
Create a Verilog testbench (tb_q_update_unit.sv) that:

Reads values from a file

Applies them to the DUT (your q_update_unit)

Captures output Q′

Logs results for comparison

Here’s a template for that:

systemverilog
复制
编辑
module tb_q_update_unit;

    // Parameters
    parameter Q_WIDTH = 16;

    // DUT inputs
    logic clk = 0, rst = 0, start = 0;
    logic [2:0] curr_row, curr_col, next_row, next_col;
    logic [1:0] curr_action;
    logic signed [Q_WIDTH-1:0] reward;

    // DUT output
    logic done;

    // Instantiate DUT
    q_update_unit dut (
        .clk(clk), .rst(rst), .start(start),
        .curr_row(curr_row), .curr_col(curr_col),
        .curr_action(curr_action), .reward(reward),
        .next_row(next_row), .next_col(next_col),
        .done(done)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        $display("Starting Verilog test...");

        // Read from test_vectors.csv converted to .mem or .hex if needed
        // OR hardcode a few vectors here for testing

        // Example test
        rst = 1; #10; rst = 0;
        curr_row = 3;
        curr_col = 2;
        curr_action = 1;
        next_row = 3;
        next_col = 3;
        reward = -16'd1;  // Fixed-point representation

        start = 1; #10; start = 0;

        wait (done == 1);
        $display("Test completed");
        $finish;
    end
endmodule
Optional: use $readmemb() to preload test data.

🔬 Part 4: Compare outputs in Python
Capture Verilog’s output (Q′) and compare with:

python
复制
编辑
q_prime = (1 - alpha) * Q_sa + alpha * (reward + gamma * Q_max_next)
Use numpy.isclose() with a tolerance to account for fixed-point rounding errors.

📊 Part 5: Performance Benchmark
If you want to compare performance, you can:

Measure Python code execution time:

python
复制
编辑
import time
start = time.perf_counter()
# Run Q_Learning()
end = time.perf_counter()
print(f"Python Q-learning time: {end - start:.4f} s")
For Verilog:

Count clock cycles between start and done

Multiply by clock period (e.g., 10 ns)

✅ Summary

Task	Purpose
Dump test vectors from Python	Gives known-good reference data
Simulate Verilog DUT	Runs your Q-update hardware
Compare outputs	Verifies correctness
Measure performance	Compares software vs hardware
💡 Let me help you next:
Convert test_vectors.csv to .mem for Verilog? ✅

Full Verilog testbench with readmemh? ✅

Python script to auto-verify Verilog output? ✅

Which part would you like to tackle now?


I mapping my process of getting in Code folder.
