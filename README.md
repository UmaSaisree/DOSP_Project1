



Uma Sai Sree Avula - UFID : 38554667
Bhanu Rekha Musuluri - UFID : 98477459

This project deals with Bitcoins. We have a server that works on backend and generates a key. We have multiple clients hitting the server to generate the secret key for Bitcoin. 
We use SHA-256 hash to encrypt the given code to give the output which is the key. The program that we wrote becomes a "worker" and then calls the server to the work done. We define a worker that performs the job and a boss that keeps the track of all the worker programs.

Execution Steps - 

Create a node for the server using the command -

erl -name uavula@192.168.0.105

Compile the module using the command -

c(toast).

To start the compiled program and enable the server use the command - 

toast:actor_start().

To enable the workers process use the command 

toast:toasting('uavula@192.168.0.105',6). 


Determining the size of Unit -

We have plotted a graph and noted down the number of workers and ratios of CPU time to real time. We have observed that the values got to the maximum and then declined.
The maxima is determined as the size of the unit. 

Observed Values
Workers - 8 CPU time: 86 Real Time: 114 Ratio - 0.7543859649122807
Workers - 7 CPU TIME : 81 REAL TIME : 71 RATIO : 1.1408450704225352 
Workers - 6 CPU TIME : 101 REAL TIME : 77 RATIO : 1.3116883116883118 
Workers - 5 CPU TIME : 78 REAL TIME : 74 RATIO : 1.054054054054054 
Workers - 4 CPU TIME : 63 REAL TIME : 71 RATIO : 0.8873239436619719
Workers - 3 CPU TIME : 59 REAL TIME : 68 RATIO : 0.8676470588235294
Workers - 2 CPU TIME : 64 REAL TIME : 67 RATIO : 0.9552238805970149

The result of Running the Program for Input 4 - 
4 leading Zeroes 
CPU Time: 
Real Time: 
Ratio:  
<img width="1172" alt="image" src="https://user-images.githubusercontent.com/57837608/192126177-adbf1413-f0e8-43d4-bc15-9c3c7dac4d4b.png">


The coin with max Zeros - 
We found the following coin with maximum zeros - 



