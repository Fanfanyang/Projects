
from __future__ import print_function

import tensorflow as tf
import matplotlib.pyplot as plt

import numpy as np
from numpy import loadtxt

hist_window = 10
pred_window = 60
#obs_links = np.arange(2,25,1)
obs_links = np.array([2,21])

#load data
#add time, accum
def diag_concatenate(tmp,hist_window):
    for i in range(hist_window):
        if i==0:
            data = tmp[hist_window:,:]
        else:
            data = np.concatenate((tmp[hist_window-i:tmp.shape[0]-i,:],data),axis=1)
    return data

xt_real = loadtxt("../xt_real_train.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_train.csv", comments="#", delimiter=",", unpack=False)
td = loadtxt("../td_train.csv", comments="#", delimiter=",", unpack=False)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
capacity_td = td.max(axis=0)
time_data = np.array([td[:xt_real.shape[0]-pred_window]/capacity_td])
train_data_tmp = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
train_data = diag_concatenate(train_data_tmp,hist_window)
#train_data = np.concatenate((train_data,time_data[:,hist_window:].transpose()),axis=1)
train_target_tmp = xt_real[pred_window:,:]/capacity_xt
train_target = diag_concatenate(train_target_tmp,hist_window)
train_data=np.nan_to_num(train_data)
train_target=np.nan_to_num(train_target)

xt_real = loadtxt("../xt_real_test.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_test.csv", comments="#", delimiter=",", unpack=False)
td = loadtxt("../td_test.csv", comments="#", delimiter=",", unpack=False)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
capacity_td = td.max(axis=0)
time_data = np.array([td[:xt_real.shape[0]-pred_window]/capacity_td])
test_data_tmp = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
test_data = diag_concatenate(test_data_tmp,hist_window)
#test_data = np.concatenate((test_data,time_data[:,hist_window:].transpose()),axis=1)
test_target_tmp = xt_real[pred_window:,:]/capacity_xt
test_target = diag_concatenate(test_target_tmp,hist_window)
test_data=np.nan_to_num(test_data)
test_target=np.nan_to_num(test_target)

#test_data = train_data[:600,:]
#test_target = train_target[:600,:]

# Global config variables
num_steps = hist_window # number of truncated backprop steps ('n' in the discussion above)
batch_size = 500
num_classes = 25
state_size = 32
learning_rate = 0.01
training_epochs = 100

"""
Placeholders
"""

n_input = train_data.shape[1] 
n_output = train_target.shape[1] 

# tf Graph input
x = tf.placeholder("float", [batch_size, n_input])
y = tf.placeholder("float", [batch_size, n_output])
init_state = tf.zeros([batch_size, state_size])

"""
RNN Inputs
"""

# Turn our x placeholder into a list of one-hot tensors:
# rnn_inputs is a list of num_steps tensors with shape [batch_size, num_classes]
#x_one_hot = tf.one_hot(x, num_classes)
#rnn_inputs = tf.unpack(x_one_hot, axis=1)
#rnn_inputs = tf.unpack(x,axis=0)
rnn_inputs = tf.split(1,num_steps,x)

"""
RNN
"""

cell = tf.nn.rnn_cell.BasicRNNCell(state_size)
rnn_outputs, final_state = tf.nn.rnn(cell, rnn_inputs, initial_state=init_state)

"""
Predictions, loss, training step
"""

with tf.variable_scope('softmax'):
    W = tf.get_variable('W', [state_size, num_classes])
    b = tf.get_variable('b', [num_classes], initializer=tf.constant_initializer(0.0))
logits = [tf.matmul(rnn_output, W) + b for rnn_output in rnn_outputs]
predictions = [tf.nn.softmax(logit) for logit in logits]
pred = predictions[0]
               
y_as_list = tf.split(1, num_steps, y)

losses = [tf.reduce_sum(tf.square(logit-label)) for \
          logit, label in zip(predictions, y_as_list)]

total_loss = tf.reduce_mean(losses)
train_step = tf.train.AdagradOptimizer(learning_rate).minimize(total_loss)   



# Initializing the variables
init = tf.initialize_all_variables()

# Launch the graph` 
with tf.Session() as sess:
    sess.run(init)
    
    # Training cycle
    training_losses = []
    for epoch in range(training_epochs):
        #print(epoch)
        avg_cost = 0.
        training_loss = 0
        total_batch = int(train_data.shape[0]/batch_size)
        training_state = np.zeros((batch_size, state_size))
        # Loop over all batches
        for i in range(total_batch):
            batch_x = train_data[(i*batch_size):((i+1)*batch_size)]
            batch_y = train_target[(i*batch_size):((i+1)*batch_size)]
            # Run optimization op (backprop) and cost op (to get loss value)
            tr_losses, training_loss_, training_state, _ = \
                    sess.run([losses,
                              total_loss,
                              final_state,
                              train_step],
                                  feed_dict={x:batch_x, y:batch_y, init_state:training_state})
                            # Compute average loss
            training_loss += training_loss_
        print('epoch: ', epoch, ' training loss: ',training_loss)
        
        raw_predict = pred.eval({x: test_data[:batch_size,:], y: test_target[:batch_size,:], init_state:training_state})
        raw_target = test_target























# Parameters
learning_rate = 0.01
training_epochs = 200
batch_size = 200
display_step = 1

# Network Parameters
beta = 1e-6
dropout = 0.75
n_hidden_1 = 128 # 1st layer number of features
n_hidden_2 = 256 # 2nd layer number of features
n_hidden_3 = 64
n_hidden_last = n_hidden_3
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
    layer_2 = tf.add(tf.matmul(layer_1, weights['h2']), biases['b2'])
    layer_2 = tf.sigmoid(layer_2)
    layer_2 = tf.nn.dropout(layer_2, dropout)
    # Hidden layer with sigmoid activation
    layer_3 = tf.add(tf.matmul(layer_2, weights['h3']), biases['b3'])
    layer_3 = tf.sigmoid(layer_3)
    layer_3 = tf.nn.dropout(layer_3, dropout)
    # Output layer with sigmoid activation
    out_layer = tf.matmul(layer_3, weights['out']) + biases['out']
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
cost = (tf.reduce_sum(tf.square(pred-y)) + beta*(tf.nn.l2_loss(weights['h1'])+tf.nn.l2_loss(weights['h2'])+tf.nn.l2_loss(weights['h3']) + tf.nn.l2_loss(weights['out'])))
#cost = tf.sqrt(tf.reduce_mean(tf.square(pred-y)))
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
plt.plot(raw_predict[:,1])
plt.plot(raw_target[:,1])

plt.plot(raw_predict[:,0])
plt.plot(raw_target[:,0])

plt.plot(raw_predict[:,2])
plt.plot(raw_target[:,2])












