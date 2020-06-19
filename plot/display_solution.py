import networkx as nx
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import math

# input
instance = "n150"
cost = 449

# read instance file
instance_file = open("../data/" + instance + ".txt", mode="r")
lines = instance_file.readlines()
instance_file.close()

lines = [line.replace("\n","") for line in lines if line != "\n"]
n = eval(lines[0])
nodes = [i+1 for i in range(n)]
m = eval(lines[4])
zones = {i:None for i in nodes}
for i,z in enumerate(lines[5].split(" ")):
    zones[i+1] = eval(z)
coord = [None for _ in range(n)]
for i in range(n):
    x,y = lines[7+i].split(" ")
    coord[i] = (eval(x), eval(y))

# read result file
result_file = open("../solutions/" + instance + "_cost=" + str(cost) + ".sol", mode="r")
lines = result_file.readlines()
result_file.close()

lines = [line.replace("\n","") for line in lines if line != "\n"]
total_length = eval(lines[0])
selected_edges = []
for line in lines[1:]:
    u,v = line.split(" ")
    selected_edges.append((eval(u), eval(v)))

# generate direct graph
G = nx.MultiDiGraph()
G.add_nodes_from(nodes)
G.add_edges_from(selected_edges)

# node colors depending on zones
palette = sns.hls_palette(m+1)
node_color = [palette[zones[i]] for i in nodes]

# plot
sns.set_style("whitegrid")
fig = plt.figure(figsize=(9,9))
ax = fig.add_subplot()
nx.draw_networkx(G,
                pos={i:coord[i-1] for i in nodes},
                node_color=node_color,
                labels={i:"${}$".format(i) for i in nodes},
                ax=ax,
                font_size=11,
                width=2)
ax.tick_params(labelleft=True, labelbottom=True)
ax.set_xlabel("x", fontsize=14)
ax.set_ylabel("y", fontsize=14, rotation=0)
ax.set_title("Instance {} - Total length = {}".format(instance, total_length), fontsize=16)
plt.savefig(instance + "_cost=" + str(cost) + ".png", bbox_inches="tight")