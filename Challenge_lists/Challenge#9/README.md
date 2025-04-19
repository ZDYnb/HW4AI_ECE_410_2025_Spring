# Challenge #9
**Eric Zhou**  
**April 13, 2025 -**
Topic choice: implementing TinyGPT LLMs on a chiplet

Heilmeier Questions
What are you trying to do? Articulate your objectives using absolutely no jargon.
I am trying to design a chiplet accelerator for the key computing part of a Transformer. I will use a well-known GPT code repository—nanoGPT—as my reference. Eventually, I will test a small model running on this chiplet and compare its performance with a CPU and some GPU.

How is it done today, and what are the limits of current practice?
Today, LLMs are usually trained and run on GPUs, which are powerful but expensive and consume a lot of power. GPUs can handle many types of neural networks, but they may not be that efficient for every specific operation.

What is new in your approach and why do you think it will be successful?
Instead of using general-purpose devices, I want to explore the feasibility of running Transformers on a specially designed chip. I believe this will be successful because language models rely heavily on this computation block. If we can optimize it, the overall cost and power usage could be significantly reduced.

Who cares? If you are successful, what difference will it make?
If I can achieve this, I believe future employers and professors will be impressed, since accelerating LLMs is a hot topic right now.

What are the risks?
This could be very difficult, since I’ve never gone through a complete ASIC design process before, and I’m not yet very familiar with the Transformer architecture. Most of the time consumption may actually come from data movement. It might still be hard to beat the speed of modern GPUs, as they’ve already been optimized a lot—but I think it’s worth trying, and I’m curious to see what I can learn.

How much will it cost?
For software, it will cost $0—I’ll either use campus-provided tools or open-source ones.
For hardware verification, it might also be $0, since I plan to use the capstone lab’s FPGA.

How long will it take?
I will learn while building. I think it’s worthwhile to spend the rest of the term (around 7 weeks) on this project.

What are the mid-term and final “exams” to check for success?
Mid-term: Get simulation results working.
Final: Demonstrate the chiplet running with real test data and compare the performance with CPU/GPU.