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

I launch my initial test below in deployment mode:

I run below in the shell:
python sample.py --init_from=gpt2 --start="What is the answer to life, the universe, and everything?" --num_samples=5 --max_new_tokens=100   

generating first inital result:
(baseconda activate nanogptE_410_2025_Spring\Challenge_lists\Challenge#9\Code\nanoGPT>
(nanogpt) PS D:\AI4Hardware_ECE_410_2025_Spring\Challenge_lists\Challenge#9\Code\nanoGPT> python sample.py --init_from=gpt2 --start="What is the answer to life, the universe, and everything?" --num_samples=5 --max_new_tokens=100
Overriding: init_from = gpt2
Overriding: start = What is the answer to life, the universe, and everything?
Overriding: num_samples = 5
Overriding: max_new_tokens = 100
loading weights from pretrained gpt: gpt2
forcing vocab_size=50257, block_size=1024, bias=True
overriding dropout rate to 0.0
number of parameters: 123.65M
No meta.pkl found, assuming GPT-2 encodings...
⏱️ Sample 1 | Time: 2.734s | 100 tokens | 27.34 ms/token
What is the answer to life, the universe, and everything? Have any of the answers to life have anything to do with God?   

What is the answer to life? Have any of the answers to life have anything to do with God? Could there be a God?

Could there be a God? What is the future?

What is the future? Are there any problems with the universe?


I am a Christian.

I am a Christian. I'm a Christian. I've never participated in any religion.


---------------
⏱️ Sample 2 | Time: 1.848s | 100 tokens | 18.48 ms/token
What is the answer to life, the universe, and everything?<|endoftext|>Prime Minister John Key faces a potential deal with Labour MPs who accused him of "double standards" by promising to continue a Labour government funded by taxpayers.        

Key's election strategy would include a "major increase in spending on public services", as well as a promise that all MPs would be paid 1 per cent of wages.

The pledge is a dig at Mr Miliband's claim, which is based on a study last month which found that the government's public services were spending more on public
---------------
⏱️ Sample 3 | Time: 1.847s | 100 tokens | 18.47 ms/token
What is the answer to life, the universe, and everything?


Notes's previous articles on the subject have provided some excellent historical analysis.

Some of your previous articles, posted by Michael Fassbender for The New York Times, appear in The New York Times Magazine.


Please note that The New York Times' 'Daily Digest' section is not endorsed by the Society of Professional Journalists. Content contained in this section may be found elsewhere on the Internet.<|endoftext|>The M83's are designed to take their name from a French M83-R
---------------
⏱️ Sample 4 | Time: 1.870s | 100 tokens | 18.70 ms/token
What is the answer to life, the universe, and everything? Just as the scriptures instructs us to love and obey God, so the scriptures teach us to believe in and obey God. If we believe in God, why do we believe in others? Does God put a stop to our faith in God? Is God willing to give us the information we need to be fully spiritual beings? Is God willing to make us gain the benefit of their eternal existence? Why, then, do we worship God so much? Because we are His creatures. The scriptures tell us
---------------
⏱️ Sample 5 | Time: 1.829s | 100 tokens | 18.29 ms/token
What is the answer to life, the universe, and everything? This question has been raised in many of the ancient cultures where ancient gods were often worshipped, but many people have an erroneous view…

(We should probably ask a few questions here and there to see what he knows about the ancient gods and what they stand for)

Why does it seem that someone who claims that there is something supernatural is not right? Why is there such a huge difference in how we think about the universe? Are all the gods fair and decent? This is something very
---------------

✅ Benchmark Summary:
Total time: 10.135 seconds
Average per sample: 2.027 seconds
Average per token: 20.27 ms/token
Tokens per second: 49.34 tokens/s

I do 5 sample test, benchmark sumary as shown above!

After initial benchmark, I got a sense of my runing gpt2. It runs sample as a test and acutually generate the token through its output. Token by token, the generating sentence forms!

To better my sense of how really the token pop up and sample generated, I use a .ipynb file to line by line dig into my source code. Reconstruct code in ipynb allow me to explore the code struction in a more clear way, other than switching back and forth in different source code folder. You can find my process of analysis of nanogpt code construction in Code/Progress folder.

Key achievement:



