# Challenge #18
**Eric Zhou**  
**April 29, 2025**

# Intro:
How really go down to the pysical lever?
In this challenge, we want to first get some

# Openlane 2 tool trial

Openlane 2 is an open source design work flow tool for ASIC VLSI design. The design flow tools cover all process from RTL model to layout.

To get a sense, I visit the link below provided by offical website to walk myself through the whole design:
https://colab.research.google.com/github/efabless/openlane2/blob/main/notebook.ipynb

Attempting OpenLane 2 on My Design:
After completing the example, I tried to apply OpenLane 2 to my own design from Challenge #15. However, I encountered persistent synthesis errors. Upon further investigation (including asking Claude for advice), I realized that my Verilog design accidentally mixed in SystemVerilog features (e.g., parameter loading and array-style port declarations)
Yosys, which is used for synthesis in OpenLane, only supports pure Verilog, not SystemVerilog.

Due to time constraints and the scope of my existing codebase, I concluded that I wouldn't be able to fully refactor and adapt my design to make it OpenLane-compatible.

Although I couldn't complete the full backend flow, I made a realistic assumption for hardware clock speed based on comparable ASIC benchmarks:
Target Clock Frequency: 20 MHz

This assumption will be used for performance estimation in other parts of the project, such as evaluating latency and throughput per sequence (see Challenge #15 results).