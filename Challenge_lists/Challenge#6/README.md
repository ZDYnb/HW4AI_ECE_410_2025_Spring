# Challenge #6 Logic Neuron Gate
**Eric Zhou**  
**April 13, 2025**

## Objective
In this challenge, I aim to walk myself through the foundational concept of a single neuron — the basic building block of neural networks.

## Background Learning
Today, neural networks are widely used in many real-world applications, and our 410 course is designed around that. But before we jump into deep networks, it's important to ask:
Why is the "neuron" chosen as the fundamental unit in a neural network?
A neuron in a neural network is inspired by the biological neurons. It accepts multiple inputs. Each input then multiplied by a corresponding weight, sums them together and then passes the sum through a **non-linear activation function**. The output is then either used directly or passed as input to another neuron in the next layer.

\[
\text{Output} = \text{ActivationFunction}\left( \sum_{i=1}^{n} w_i \cdot x_i + b \right)
\]

Where:
- \(x_i\) = input values  
- \(w_i\) = weights  
- \(b\) = bias  
- ActivationFunction = non-linear function (e.g., sigmoid)

The designed structure above allows neurons to form the networks. Through different ways of connecting and stacking creates different network architectures based on our demands.

Expectedly, we want to build a powerful system that can map **any input** to our **desired output**.

To achieve this, we introduce **weights** into the structure of the neuron as mentioned in previous fomula. These weights determine how much each input contributes to the final result.

In practice, we don’t manually assign weights — instead, we learn them through a process called backpropagation, which is part of supervised learning.

During training, we compare the actual output with the expected output, calculate the error, and use it to adjust the weights.

Gradient Descent Update Rule (Simplified):

\[
w_i \leftarrow w_i + \eta \cdot (y - \hat{y}) \cdot x_i
\]

Where:
- \(y\) = expected output  
- \(\hat{y}\) = predicted output  
- \(\eta\) = learning rate  
- \(x_i\) = input value  
- \(w_i\) = weight to update

Once we get the updated weight, we will go through our model and gain new predicted outputs and adjust again.

Each training step involves:
1. Forward Pass: Compute predicted output  
2. Error Calculation: Compare with expected output  
3. Backward Pass: Adjust weights to reduce error

We go through the above training process multiple times — each cycle is called an epoch — until we reach a convergence point, where the model's performance becomes stable and the error is sufficiently low.

This convergence indicates that we have trained a good enough system that can reliably map inputs to outputs.

You can view this process as building a function approximator. The network tries to fit the input-output relationship through iterative updates.

Notice I highlight the non-linear activation function in the above context. Why we want an none- activation function? In math, there have been proved that without the activation function or with linear activation function, no matter what strcuture you built around neurons networks, how many layers we adds, the neuron network system will always remain linear.


To learn complex, non-linear patters(like image edges, logic gates), we need our system has the ability to map the **non-linearity**. That’s where  some non-linear activation functions like **sigmoid**, **ReLU**, or **tanh** come in.

To understand this better, I referred to:  
**Jason Brownlee, _A Gentle Introduction to the Sigmoid Function_, [Machine Learning Mastery](https://machinelearningmastery.com/a-gentle-introduction-to-sigmoid-function)**

Sigmoid Formula:

\[
\sigma(x) = \frac{1}{1 + e^{-x}}
\]

- S-shaped curve  
- Flat tails (saturates at 0 and 1)  
- Centered at 0.5 for \(x = 0\)

This signoid acitvation function Takes any real-valued input and map it to the range (0, 1). We can find the output is smooth and differentiable.

Such sigmoid formula introduces the non-liearity to our neuron and has a clear derivative for easy training computing:
 \[
  \sigma'(x) = \sigma(x)(1 - \sigma(x))
  \]

Conclusion:
The non-linear activation function is what gives the neural network power to achieve impresively complex system that can map any value we want to the expected output.

## Experiment: NAND & XOR with a Sigmoid-Based Perceptron
In this challenge, I digged into details about implementing a sigmoid-based perceptron and testing it on logic gates like NAND and XOR. All the code is placed into the code folder in a Jupyter notebook. This was also a vibe code practice for me to better learn from generative AI model. I atteched all my gpt inquire to form the code as below:

-I want to implement a signoid-based perceptron and test it around expression of NAND and XOR. Can you help me build the code into python? I want you show your code properly in process of how you build the dataset for each gate, how you build your function to train. Show me the training carve and the result compared with the expected truth table.



## Key Discoveries
I successfully built and trained the NAND gate, but not the NOR gate.

I then ask my gpt to futher this question:
 -Why? This is besides my expectation. I thought previously the Sigmoid-Based Perceptron is enough to show the non-liearity. So it is a single neuron problem right? It can only create line in the sapce?

gpt suggest:
If you plot these points on a 2D graph, you’ll see:

Points (0,1) and (1,0) are labeled as 1

Points (0,0) and (1,1) are labeled as 0

There’s no single straight line (no linear boundary) that can separate the 1s from the 0s.
This means it's not linearly separable.

The sigmoid activation function itself is non-linear, but a single-layer perceptron with sigmoid is still limited:

It can only represent linear decision boundaries in the input space, even with sigmoid.

So, sigmoid helps transform the data, but without layering, the model can't capture the more complex patterns needed for XOR. 

To learn XOR, you need at least one hidden layer — this is known as a 2-layer neural network. You need more neurons in one layer to achieve non-linearity line.

Example:
Input Layer → Hidden Layer (non-linear) → Output Layer
With this extra layer, the model can:
Create intermediate non-linear features
Combine them in a way that separates XOR correctly

A single neuron, even with a sigmoid activation, can only create a **linear decision boundary** in the input space.

In mathematical terms, the single neuron computes:

\[
\text{Output} = \sigma(w_1 x_1 + w_2 x_2 + b)
\]

This means it separates data based on a straight line in 2D space (or a **hyperplane** in higher dimensions), defined by:
\[
w_1 x_1 + w_2 x_2 + b = 0
\]

Let’s consider the **XOR truth table**:

| Input A | Input B | XOR Output |
|---------|---------|------------|
| 0       | 0       | 0          |
| 0       | 1       | 1          |
| 1       | 0       | 1          |
| 1       | 1       | 0          |

If you plot these on a 2D plane, there's **no straight line** that can separate the `1`s from the `0`s.  
This means XOR is **not linearly separable**, and a single neuron can't learn it.

To solve XOR, we need a **multi-layer perceptron (MLP)** — a neural network with **at least one hidden layer**.

This allows the model to:
- Combine multiple linear boundaries
- Apply **non-linear activation** in between
- Create **non-linear decision boundaries** like curves.

From chatting with GPT, I learned a lot about the importance of non-linearity in building stacked neurons — which helped me understand why we need neural networks in the first place. We need a multi-layer perceptron (MLP) to create non-linear decision boundaries in mathematical space, which empowers the model with the ability to map complex input-output relationships.

To dive deeper into the XOR gate problem, I asked GPT to provide code for visualizing the final decision boundaries of a single-neuron model. Then, I extended the architecture by adding an additional neuron to form a two-layer neural network, which allowed the model to successfully learn the XOR logic gate. The full implementation is shown in the code folder.

Key Takeaway from This Challenge:
Non-linear design is critical in neural network architecture. We can achieve this non-linearity through multiple neurons in an MLP and through the use of non-linear activation functions like sigmoid.