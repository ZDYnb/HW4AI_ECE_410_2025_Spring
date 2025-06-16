# Challenge #6: Logic Neuron Gate
**Eric Zhou**  
**April 13, 2025**

---

## Objective

Walk through the foundational concept of a single neuron — the basic building block of neural networks.

---

## Background Learning

Neural networks are widely used in real-world applications, and our ECE 410 course is designed around them. But before diving into deep networks, it's important to ask:

> **Why is the "neuron" chosen as the fundamental unit in a neural network?**

A neuron in a neural network is inspired by biological neurons. It:
- Accepts multiple inputs
- Multiplies each input by a corresponding weight
- Sums them together
- Passes the sum through a **non-linear activation function**
- Outputs the result (used directly or as input to the next neuron)

\[
\text{Output} = \text{ActivationFunction}\left( \sum_{i=1}^{n} w_i \cdot x_i + b \right)
\]

Where:
- \(x_i\): input values  
- \(w_i\): weights  
- \(b\): bias  
- ActivationFunction: non-linear function (e.g., sigmoid)

This structure allows neurons to form networks. By connecting and stacking neurons in different ways, we create various architectures to meet our needs.

The goal: **Build a system that can map any input to our desired output.**

To achieve this, we introduce **weights**. These determine how much each input contributes to the final result. In practice, we don’t manually assign weights — we learn them through **backpropagation** (supervised learning).

During training:
- Compare actual output with expected output
- Calculate the error
- Adjust the weights

**Gradient Descent Update Rule (Simplified):**

\[
w_i \leftarrow w_i + \eta \cdot (y - \hat{y}) \cdot x_i
\]

Where:
- \(y\): expected output  
- \(\hat{y}\): predicted output  
- \(\eta\): learning rate  
- \(x_i\): input value  
- \(w_i\): weight to update

Each training step involves:
1. **Forward Pass:** Compute predicted output  
2. **Error Calculation:** Compare with expected output  
3. **Backward Pass:** Adjust weights to reduce error

Repeat for multiple epochs until convergence (error is sufficiently low).

> **This process builds a function approximator. The network fits the input-output relationship through iterative updates.**

### Why Non-Linear Activation?

Without a non-linear activation function, no matter how many layers we add, the network remains linear. To learn complex, non-linear patterns (like image edges or logic gates), we need non-linearity.

**Common non-linear activation functions:**  
- Sigmoid  
- ReLU  
- Tanh

#### Reference

> Jason Brownlee, _A Gentle Introduction to the Sigmoid Function_, [Machine Learning Mastery](https://machinelearningmastery.com/a-gentle-introduction-to-sigmoid-function)

**Sigmoid Formula:**

\[
\sigma(x) = \frac{1}{1 + e^{-x}}
\]

- S-shaped curve  
- Saturates at 0 and 1  
- Centered at 0.5 for \(x = 0\)

The sigmoid activation maps any real-valued input to (0, 1). It is smooth and differentiable.

**Derivative:**
\[
\sigma'(x) = \sigma(x)(1 - \sigma(x))
\]

**Conclusion:**  
Non-linear activation functions give neural networks the power to model complex relationships.

---

## Experiment: NAND & XOR with a Sigmoid-Based Perceptron

I implemented a sigmoid-based perceptron and tested it on logic gates like NAND and XOR. All code is in the `code` folder (Jupyter notebook). This was also a great coding practice using generative AI.  
I attached my GPT inquiry for code generation:

> I want to implement a sigmoid-based perceptron and test it on NAND and XOR. Can you help me build the code in Python? Please show the process: dataset creation for each gate, training function, training curve, and results compared with the expected truth table.

---

## Key Discoveries

- Successfully built and trained the **NAND** gate, but **not the XOR** gate.

I then asked GPT:

> Why? I thought a Sigmoid-Based Perceptron could show non-linearity. Is it a single neuron problem? Can it only create a line in space?

**GPT explained:**

- If you plot the XOR truth table, you’ll see:
  - (0,1) and (1,0) labeled as 1
  - (0,0) and (1,1) labeled as 0
- There’s **no single straight line** (linear boundary) that separates the 1s from the 0s.
- The sigmoid activation is non-linear, but a single-layer perceptron (even with sigmoid) is limited to **linear decision boundaries**.

To learn XOR, you need at least one hidden layer (a 2-layer neural network):

**Example:**
```
Input Layer → Hidden Layer (non-linear) → Output Layer
```
- This allows the model to create intermediate non-linear features and combine them to separate XOR correctly.

**Mathematical Formulation (Single Neuron):**
\[
\text{Output} = \sigma(w_1 x_1 + w_2 x_2 + b)
\]
- This creates a linear boundary:  
  \(w_1 x_1 + w_2 x_2 + b = 0\)

**XOR Truth Table:**

| Input A | Input B | XOR Output |
|---------|---------|------------|
| 0       | 0       | 0          |
| 0       | 1       | 1          |
| 1       | 0       | 1          |
| 1       | 1       | 0          |

- No straight line can separate the 1s from the 0s.
- XOR is **not linearly separable**; a single neuron can't learn it.

**Solution:**  
A **multi-layer perceptron (MLP)** (at least one hidden layer) is needed. This enables:
- Multiple linear boundaries
- Non-linear activations between layers
- Non-linear decision boundaries (curves)

---

## Summary & Takeaways

- **Non-linear design is critical** in neural network architecture.
- Achieve non-linearity through:
  - Multiple neurons in an MLP
  - Non-linear activation functions (e.g., sigmoid)
- A single neuron (even with sigmoid) can only create linear decision boundaries.
- Multi-layer networks can model complex, non-linear relationships (like XOR).

---

*See the code folder for full implementation and visualizations.*