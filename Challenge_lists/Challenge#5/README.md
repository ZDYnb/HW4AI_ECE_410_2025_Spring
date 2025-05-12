# Challenge #5 Python Workload Analysis
**Eric Zhou**  
**April 3, 2025 -**
In Week 1 of the codefest, I chose **Challenge #5** as my first exploration topic for this class — a warm-up to dive into AI/ML workload profiling and parallelism.

This challenge was about analyzing how AI and ML Python code actually executes behind the scenes. It encouraged us to try out **“vibe coding”** — writing and testing code freely — and observe the resulting low-level behavior, including bytecode and potential parallelism in its execution.

---

## Workloads Chosen

I selected **three different Python workloads** for analysis:

1. **differential equation solver**
2. **convolutional neural network (CNN)**
3. **Quicksort**

To speed up the process, I used ChatGPT as my TA to generate template code for all three workloads. Then, following the task instructions, I compiled the Python code into bytecode using the `py_compile` module. This created `.pyc` files in the `__pycache__` directory.

---

## Bytecode & Assembly Exploration

Before this challenge, I wasn't fully aware of how Python executes code step by step. I disassembled the `.pyc` files to inspect the bytecode and dug into the underlying instruction set.

One key observation: each bytecode instruction was 2 bytes long, indicating that Python operates as a stack-based virtual machine. This means most instructions operate by pushing and popping from an implicit stack rather than using direct memory addressing.

I then compared the instruction distributions across the three workloads. *(Analysis still in progress – TBD.)*

---

## Profiling with `cProfile` and `snakeviz`

To measure code performance, I used `cProfile`, which collects statistics on time and resource usage. I saved the profiling data and visualized it using **`snakeviz`**, which gave me colorful, interactive graphs to understand time hotspots and function call hierarchy.

This helped me identify where most time was being spent — valuable for later parallelism analysis.

---

## Attempting Parallelism Analysis

My next goal was to analyze **algorithmic structure and data dependencies** to explore opportunities for parallel execution.

I initially asked ChatGPT to analyze the disassembled assembly instructions, but it wasn't effective — the analysis lacked depth and accuracy. I then shifted focus to the original Python code instead.

I aimed to build a tool that could **analyze code dynamically**, as it executes — line by line — and identify `read` and `write` dependencies between variables. My dream was to construct a **data dependency graph** for the code’s control flow, highlighting parallelizable regions.

However, the analyzer I built could only process code sequentially — from the top of the file to the bottom — and struggled to simulate execution order accurately like an interpreter would. Despite generating execution traces, analyzing bytecode-level parallelism remained a challenge.

Still, I gained useful insights on which code regions might be independent and could potentially benefit from **parallel execution strategies**.


---

## Thoughts for different instruction architectures
(1) Neural Nets / CNN – SIMT (Single Instruction, Multiple Threads), like a GPU
(2) Quicksort or Recursive Algorithm – MIMD (Multiple Instruction, Multiple Data), or Multi-core CPU
(3) Math-heavy tasks like RK4 Solver – SIMD / Vector instructions (e.g., AVX, NEON, or GPU)

The list above is what I got from GPT, but honestly, I'm not 100% sure about the details. I do believe all code can benefit from redesigning and be executed more efficiently in parallel, but when it comes to choosing the right instruction architecture, I feel I still need to learn more to understand what best fits each workload.

I think it should be more related to the logical and algorithmic structure from the beginning of the coding. Yes, digging into bytecode and understanding how the code runs gives a good overview of instruction distribution and potential parallelism. But when it comes to real optimization, I think we should go back to the core math or logic design at the start — that's where the roadmap for parallel execution and later optimization should begin.



## key Takeaway

While my analyzer wasn't perfect, this challenge gave me a much deeper appreciation of:

- How Python executes AI/ML workloads
- The structure of Python’s bytecode
- Profiling with tools like `cProfile`
- The complexity of identifying fine-grained parallelism
- How later different instruction architectures can be beneficial!

It also opened up me interesting questions for further exploration — like how to better simulate execution and generate **adaptive optimization strategies** based on instruction dependencies of my code. I feel excited to build and futher around that in the future!