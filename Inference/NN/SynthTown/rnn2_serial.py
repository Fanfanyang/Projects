# The RNN model accumulates past observations to track or predict vehicles.
# The basic element in RNN is RNN cell. Each cell contains input, latent state, and output. Input includes the
# observations of the current time step and inputs from previous latent state. The output is the predicted number
# of vehicles. We use a length of 10 RNN cells. We trained it for 30 days and use another single day for testing.


from __future__ import print_function

import tensorflow as tf
import matplotlib.pyplot as plt

import numpy as np
from numpy import loadtxt

import os
os.chdir('/Users/fanyang/Documents/Research/2017_spring/NN/toy_0/tensorflow')

hist_window = num_steps = 60
pred_window = 10
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
    
def gen_trunc(tmp,num_steps):
    length = tmp.shape[0]/num_steps
    data = np.zeros((length,num_steps*tmp.shape[1]))
    for i in range(length):
        data[i,:] = tmp[(i*num_steps):((i+1)*num_steps),:].ravel()
    return data
    

xt_real = loadtxt("../xt_real_train.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_train.csv", comments="#", delimiter=",", unpack=False)
td = loadtxt("../td_train.csv", comments="#", delimiter=",", unpack=False)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
capacity_td = td.max(axis=0)
time_data = np.array([td[:xt_real.shape[0]-pred_window]/capacity_td])
train_data_tmp = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
train_data = gen_trunc(train_data_tmp,hist_window)
#train_data = np.concatenate((train_data,time_data[:,hist_window:].transpose()),axis=1)
train_target_tmp = xt_real[pred_window:,:]/capacity_xt
train_target = gen_trunc(train_target_tmp,hist_window)
train_data=np.nan_to_num(train_data)
train_target=np.nan_to_num(train_target)

xt_real = loadtxt("../xt_real_test.csv", comments="#", delimiter=",", unpack=False)
yt = loadtxt("../yt_test.csv", comments="#", delimiter=",", unpack=False)
td = loadtxt("../td_test.csv", comments="#", delimiter=",", unpack=False)
xt_real = np.concatenate((xt_real,xt_real),axis=0)
yt = np.concatenate((yt,yt),axis=0)
td = np.concatenate((td,td),axis=0)
capacity_xt = xt_real.max(axis=0)
capacity_yt = yt.max(axis=0)
capacity_td = td.max(axis=0)
time_data = np.array([td[:xt_real.shape[0]-pred_window]/capacity_td])
test_data_tmp = yt[:xt_real.shape[0]-pred_window,obs_links]/capacity_yt[obs_links]
test_data = gen_trunc(test_data_tmp,hist_window)
#test_data = np.concatenate((test_data,time_data[:,hist_window:].transpose()),axis=1)
test_target_tmp = xt_real[pred_window:,:]/capacity_xt
test_target = gen_trunc(test_target_tmp,hist_window)
test_data=np.nan_to_num(test_data)
test_target=np.nan_to_num(test_target)

#test_data = train_data[:600,:]
#test_target = train_target[:600,:]

# Global config variables
num_steps = hist_window # number of truncated backprop steps ('n' in the discussion above)
batch_size = 1
num_classes = xt_real.shape[1]
state_size = 32
learning_rate = 0.01
training_epochs = 250
beta = 1e-6

"""
Placeholders
"""

n_input = train_data.shape[1] 
n_output = train_target.shape[1] 

# tf Graph input
x = tf.placeholder("float", [1, n_input])
y = tf.placeholder("float", [1, n_output])
init_state = tf.placeholder("float", [1, state_size])

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
    #W = tf.get_variable('W', [num_classes])
    b = tf.get_variable('b', [num_classes], initializer=tf.constant_initializer(0.0))
logits = [tf.matmul(rnn_output, W) + b for rnn_output in rnn_outputs]
#logits = [tf.mul(rnn_output, W) + b for rnn_output in rnn_outputs]
predictions = [tf.sigmoid(logit) for logit in logits]
               
y_as_list = tf.split(1, num_steps, y)

losses = ([tf.reduce_sum(tf.square(logit-label)) for \
          logit, label in zip(predictions, y_as_list)] + beta*tf.reduce_sum(tf.abs(W))) #beta*tf.nn.l2_loss(W)

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
            batch_x = train_data[(i*batch_size):((i+1)*batch_size),:]
            batch_y = train_target[(i*batch_size):((i+1)*batch_size),:]
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
        
        testing_state = training_state
        raw_target = test_target_tmp
        testing_loss = 0
        raw_predict = np.zeros(raw_target.shape)
        for i in range (test_data.shape[0]):
            batch_x = np.array([test_data[i,:]])
            batch_y = np.array([test_target[i,:]])
            te_losses,pred_tmp, testing_state = \
                    sess.run([total_loss,predictions,final_state],
                                feed_dict={x: batch_x, y: batch_y, init_state:testing_state})
            testing_loss += te_losses
            for j in range (num_steps):
                raw_predict[i*num_steps+j,:] = pred_tmp[j]
        var = sess.run(W)
        '''
        variables_names =[v.name for v in tf.trainable_variables()]
        values = sess.run(variables_names)
        for k,v in zip(variables_names, values):
            if (k == 'RNN/BasicRNNCell/Linear/Matrix:0'):
                var_k = v
            if (k == 'RNN/BasicRNNCell/Linear/Bias:0'):
                var_b = v
        '''




Xt_result = raw_predict
for i in range (capacity_xt.shape[0]):
    Xt_result[:,i] = raw_predict[:,i]*capacity_xt[i]

np.savetxt("result/Xt_est_rnn_toy.csv", Xt_result, delimiter=",")
#np.savetxt("result/weight_w.csv", var_k, delimiter=",")
#np.savetxt("result/weight_b.csv", var_b, delimiter=",")

import csv
#----------------------------------------------------------------------
def csv_reader(file_obj):
    """
    Read a csv file
    """
    reader = csv.reader(file_obj)
    for row in reader:
        print(" ".join(row))
        
#----------------------------------------------------------------------
def csv_writer(data, path):
    """
    Write data to a CSV file path
    """
    with open(path, "wb") as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        for line in data:
            writer.writerow(line)
#csv_writer(raw_predict,'xt_est_traffic.csv')

#test plot

#test plot
plt.figure()
plt.plot(raw_predict[:,0])
plt.plot(raw_target[:,0])
plt.savefig('0.png')

plt.figure()
plt.plot(raw_predict[:,3])
plt.plot(raw_target[:,3])
plt.savefig('1.png')











