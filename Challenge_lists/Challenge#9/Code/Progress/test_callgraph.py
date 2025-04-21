from pycallgraph2 import PyCallGraph
from pycallgraph2.output import GraphvizOutput

def foo():
    for i in range(2):
        bar()

def bar():
    print("bar")

graphviz = GraphvizOutput()
graphviz.output_file = 'output.png'

with PyCallGraph(output=graphviz):
    foo()
