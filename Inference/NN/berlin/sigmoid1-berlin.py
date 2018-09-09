
from __future__ import print_function

import tensorflow as tf
import matplotlib.pyplot as plt

import numpy as np
from numpy import loadtxt

pred_window = 60
#obs_links = np.arange(2,25,1)
obs_links = np.array([2,21])

#load data
xt_real = loadtxt("../xt_real_train.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_train.csv", comments="#", delimiter=",", unpack=False)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
train_data = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
train_target = xt_real[pred_window:,:]/capacity_xt
train_data=np.nan_to_num(train_data)
train_target=np.nan_to_num(train_target)

xt_real = loadtxt("../xt_real_test.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_test.csv", comments="#", delimiter=",", unpack=False)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
test_data = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
test_target = xt_real[pred_window:,:]/capacity_xt
test_data=np.nan_to_num(test_data)
test_target=np.nan_to_num(test_target)

'''
xt_real = loadtxt("../xt_real.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt.csv", comments="#", delimiter=",", unpack=False)
td = loadtxt("../td.csv", comments="#", delimiter=",", unpack=False)
#capacity_xt = np.array([2000,2000,36000,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  1000,  1000,  1000,  1000,  1000,  1000,  1000,  1000,  1000, 36000, 36000, 36000, 36000])
#capacity_yt = np.array([2000,2000,36000,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  3600,  1000,  1000,  1000,  1000,  1000,  1000,  1000,  1000,  1000, 36000, 36000, 36000, 36000])
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
capacity_td = td.max(axis=0)
input_data = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
#time_data = np.array([td[:xt_real.shape[0]-pred_window]/capacity_td])
#input_data = np.concatenate((xt_data,time_data.transpose()),axis=1)
input_target = xt_real[pred_window:,:]/capacity_xt
input_data=np.nan_to_num(input_data)
input_target=np.nan_to_num(input_target)

#training and testing
#index = np.random.choice(input_data.shape[0],int(input_data.shape[0]*0.8),replace=False)
index = np.arange(0,2803,1)
train_data = input_data[index,:]
train_target = input_target[index,:]
test_data = np.delete(input_data,index,axis=0)
test_target = np.delete(input_target,index,axis=0)
'''

# Parameters
learning_rate = 0.001
training_epochs = 300
batch_size = 100
display_step = 1

# Network Parameters
dropout = 0.75
n_hidden_1 = 32 # 1st layer number of features
n_hidden_2 = 16 # 2nd layer number of features
n_hidden_3 = 512
n_hidden_last = n_hidden_1
n_input = train_data.shape[1] # MNIST data input (img shape: 28*28)
n_output = train_target.shape[1] # MNIST total classes (0-9 digits)

# tf Graph input
x = tf.placeholder("float", [None, n_input])
y = tf.placeholder("float", [None, n_output])
keep_prob = tf.placeholder(tf.float32)

# Create model
def multilayer_perceptron(x, weights, biases, dropout):
    # Hidden layer with sigmoid activation
    layer_1 = tf.add(tf.matmul(x, weights['h1']), biases['b1'])
    layer_1 = tf.sigmoid(layer_1)
    layer_1 = tf.nn.dropout(layer_1, dropout)
    # Hidden layer with sigmoid activation
    #layer_2 = tf.add(tf.matmul(layer_1, weights['h2']), biases['b2'])
    #layer_2 = tf.sigmoid(layer_2)
    #layer_2 = tf.nn.dropout(layer_2, dropout)
    # Hidden layer with sigmoid activation
    #layer_3 = tf.add(tf.matmul(layer_2, weights['h3']), biases['b3'])
    #layer_3 = tf.sigmoid(layer_3)
    # Output layer with sigmoid activation
    out_layer = tf.matmul(layer_1, weights['out']) + biases['out']
    out_layer = tf.sigmoid(out_layer)
    
    return out_layer

# Store layers weight & bias
weights = {
    'h1': tf.Variable(tf.random_normal([n_input, n_hidden_1],stddev=1/np.sqrt(n_input))),
    'h2': tf.Variable(tf.random_normal([n_hidden_1, n_hidden_2],stddev=1/np.sqrt(n_hidden_1))),
    'h3': tf.Variable(tf.random_normal([n_hidden_2, n_hidden_3],stddev=1/np.sqrt(n_hidden_2))),
    'out': tf.Variable(tf.random_normal([n_hidden_last, n_output],stddev=1/np.sqrt(n_hidden_last)))
}
biases = {
    'b1': tf.Variable(tf.random_normal([n_hidden_1])),
    'b2': tf.Variable(tf.random_normal([n_hidden_2])),
    'b3': tf.Variable(tf.random_normal([n_hidden_3])),
    'out': tf.Variable(tf.random_normal([n_output]))
}

# Construct model
pred = multilayer_perceptron(x, weights, biases, keep_prob)

# Define loss and optimizer
#cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=pred, labels=y))
#cost = tf.reduce_mean(tf.nn.sigmoid_cross_entropy_with_logits(logits=pred,targets=y))
cost = tf.sqrt(tf.reduce_mean(tf.square(pred-y)))
#cost = tf.nn.l2_loss(pred,y)
#cost = tf.contrib.losses.sigmoid_cross_entropy(pred,y)
optimizer = tf.train.AdamOptimizer(learning_rate=learning_rate).minimize(cost)

# Initializing the variables
init = tf.initialize_all_variables()

# Launch the graph` 
with tf.Session() as sess:
    sess.run(init)
    
    # Training cycle
    for epoch in range(training_epochs):
        avg_cost = 0.
        total_batch = int(train_data.shape[0]/batch_size)
        # Loop over all batches
        for i in range(total_batch):
            batch_x = train_data[(i*batch_size):((i+1)*batch_size-1)]
            batch_y = train_target[(i*batch_size):((i+1)*batch_size-1)]
            # Run optimization op (backprop) and cost op (to get loss value)
            _, c = sess.run([optimizer, cost], feed_dict={x: batch_x,
                            y: batch_y, keep_prob: dropout})
                            # Compute average loss
            avg_cost += c / total_batch
        # Display logs per epoch step
        if epoch % display_step == 0:
            print ("Epoch:", '%04d' % (epoch+1), "cost=", \
                "{:.9f}".format(avg_cost))
        #print ("Optimization Finished!")
        # Calculate accuracy
        correct_prediction = tf.abs(pred-y)*capacity_xt
        accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))
        print ("Accuracy:", accuracy.eval({x: test_data, y: test_target, keep_prob: 1.}))
        #raw_diff = correct_prediction.eval({x: train_data, y: train_target})
        raw_predict = pred.eval({x: test_data, y: test_target, keep_prob: 1.})
        raw_target = test_target

#test plot
plt.plot(raw_predict[0:650,1])
plt.plot(raw_target[0:650,1])

plt.plot(raw_predict[0:650,0])
plt.plot(raw_target[0:650,0])

plt.plot(raw_predict[0:650,2])
plt.plot(raw_target[0:650,2])












