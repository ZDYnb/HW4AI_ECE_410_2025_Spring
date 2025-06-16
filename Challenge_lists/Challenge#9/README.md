# Challenge #9
**Eric Zhou**  
**April 13, 2025 -**
Topic choice: implementing TinyGPT LLMs on a chiplet

Here in Challenge #9, I profiled the Python workflow for my project.
The framework I chose is based on TinyGPT. Their code is known for being clean and easy to read, which made it a great starting point. I selected the smallest model (124M) for my project 

In this challenge, I actually made two attempts, which are organized into separate subfolders. The first attempt is under the [Code/Progress](./Code/Progress/) folder, where I worked with the actual GPT2 model and performed a more complete run. I experimented with as many of the profiling tools mentioned in the instructions as possible. For a more modular test, you can check the `transformer.ipynb` file inside that folder.

The actual profiling results that we will compare later are documented in the `tiny_transformer.ipynb` file, which focuses on the scaled-down transformer design.

# Key insight 
The profiling results clearly highlight that the most significant acceleration opportunities lie in the blocks that are both *repeatedly executed* and *highly parallelizable*—these are ideal for pipelining and hardware acceleration. When a computation block is used over and over, especially if it can be parallelized or pipelined, it becomes a prime candidate for hardware co-design. In contrast, blocks that are only used once or are lightweight generally don't justify the overhead of building a dedicated accelerator.

In the GPT2 structure, the repeating unit is clearly the Transformer block. Even in the smallest version (124M), the transformer block repeats 12 times — each time processing with different weights. So this repeating structure is the most promising candidate for acceleration.

Profiling is indeed a very useful tool to visualize bottlenecks and verify our assumptions.
But personally, I think real bottlenecks should already be observable from just reading the source algorithm itself — profiling isn’t “plug-and-play” magic. It works best when you already have some hypothesis and want to confirm it.

Most modern LLM code is modular, clean, and class-based — and often wrapped in libraries. But for profiling to work well, it ideally wants to trace from top to bottom in a full run. So you really need to understand the algorithm well before you profile.

However, when I started trying to map my accelerator ideas into Verilog, I ran into problems.
I initially tried to work with large matrix multiplications — like 786×786 — but it quickly became unmanageable. I wasn’t confident progressing further with that scale, especially given my current skills and the complexity of debugging such large modules.

Even though I had already put in a lot of effort, the design became too messy and hard to test.
So I decided to take a step back and simplify the design: instead of scaling up, I scaled really down.

I shifted my focus to building a tiny 16×16 transformer, processing only a small matrix block at a time.
Given my current skillset, I felt this was the maximum complexity I could realistically manage.
By scaling down the design, I hoped to walk through the full design iteration — from software profiling to RTL implementation — without getting stuck in massive debugging loops.

I also realized that even with GPT's help, I couldn’t make meaningful progress on large designs without solid ASIC fundamentals. GPT can assist with syntax, structure, and even some design ideas, but once things get complicated — especially in debugging — real hardware experience becomes essential.

You can find the corresponding profiler notebook in the [`tiny_transformer.ipynb`](./Code/Progress/tiny_transformer.ipynb) file.

It documents the reasoning behind my scale-back decision, includes detailed profiling data for the simplified transformer block, and later served as a reference for both RTL module design and performance comparison.

Overall, after scaling back to the smaller transformer design, my profiling showed an average processing time of 21.877 ms per sample, which serve as our baseline to outperform!