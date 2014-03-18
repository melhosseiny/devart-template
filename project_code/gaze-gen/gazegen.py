import csv
import json

import threading
import time
import random

import numpy as np

from sklearn import datasets, svm, metrics
from sklearn.feature_extraction import DictVectorizer
from sklearn.hmm import GaussianHMM

from socketIO_client import SocketIO, BaseNamespace
from websocket import create_connection


gaze_data_from_csv = []

with open('gaze.csv') as f:
    reader = csv.DictReader(f, delimiter=' ')
    for row in reader:
        if int(row['lv']) != 4 and int(row['rv'] != 4):
            gaze_data_from_csv.append({k:float(row[k]) for k in ('r2x','r2y','rp','rprx','rpry','rprz','l2x','l2y','lp','lprx','lpry','lprz')})

print(gaze_data_from_csv[34])

gaze_data = [{
    'r_x' : 0.6390924214040297, 
    'r_y' : 0.5460149920045296,
    'l_x' : 0.6390924214040297, 
    'l_y' : 0.5460149920045296
},
{
    'r_x' : 0.6436546567699679, 
    'r_y' : 0.6436546567699679,
    'l_x' : 0.5051205613533511, 
    'l_y' : 0.5542632769991087
},
{
    'r_x' : 0.2497963067335149, 
    'r_y' : 0.3879226037188346,
    'l_x' : 0.5051205613533511, 
    'l_y' : 0.4671378801542687
}]

vec = DictVectorizer()
#print(vec.fit_transform(gaze_data).toarray())
#print(vec.get_feature_names())

X = vec.fit_transform(gaze_data_from_csv).toarray()
print(X)

###############################################################################
# Run Gaussian HMM
print("fitting to HMM and decoding ...", end='')
n_components = 9

# make an HMM instance and execute fit
model = GaussianHMM(n_components, 'full')
print('trying to fit')
model.fit([X])

# predict the optimal sequence of internal hidden state
hidden_states = model.predict(X)

print("done\n")

###############################################################################
# print trained parameters and plot
print("Transition matrix")
print(model.transmat_)
print()

print("means and vars of each hidden state")
for i in range(n_components):
    print("%dth hidden state" % i)
    print("mean = ", model.means_[i])
    print("var = ", np.diag(model.covars_[i]))
    print()

#mainSocket = SocketIO('localhost', 8080)
ws = create_connection("ws://localhost:8080/ws")

def generate():
    threading.Timer(30, generate).start()
    samples = model.sample(1000, random.randint(0,9999999))
    #print(samples)
    for sample in samples[0]:
        print(sample)
        #mainSocket.emit('gaze', sample.tolist())
        ws.send(json.dumps(sample.tolist()).encode('utf-8'))
        time.sleep(0.03)

generate()