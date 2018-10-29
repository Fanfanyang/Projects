from __future__ import division, print_function, absolute_import

import tensorflow as tf
import numpy as np
import os,sys,pickle
from PIL import Image

# Import data
# constructing training data

os.chdir('type your file path')
file_data = np.load('data_auto_first.npz')
train_data = file_data['arr_0']
file_data = np.load('test.npz')
test_data = file_data['arr_0']
train_data = train_data.reshape((len(train_data), np.prod(train_data.shape[1:])))

test_data = test_data.reshape((len(test_data), np.prod(test_data.shape[1:])))

total_train_size = train_data.shape[0]

total_test_size = test_data.shape[0]



file_names = os.listdir("/Users/fanyang/Desktop/tensor/test/")
file_names.remove('.DS_Store')

#For Neural Regression
neural = []
num_of_neural_data = 1000

# Parameters
learning_rate = 0.01
training_epochs = 50
batch_size = 20
display_step = 1
examples_to_show = 10

# Network Parameters
n_hidden_1 = 160000 # 1st layer
n_hidden_2 = 50000 # 2nd layer
n_hidden_3 = 4096 #3rd layer
n_input = 320000 #  data input (img shape: 100*50)

# tf Graph input (only pictures)
X = tf.placeholder("float", [None, n_input])

weights = {
    'encoder_h1': tf.Variable(tf.random_normal([n_input, n_hidden_1])),
    'encoder_h2': tf.Variable(tf.random_normal([n_hidden_1, n_hidden_2])),
    'encoder_h3': tf.Variable(tf.random_normal([n_hidden_2, n_hidden_3])),
    'decoder_h1': tf.Variable(tf.random_normal([n_hidden_3, n_hidden_2])),
    'decoder_h2': tf.Variable(tf.random_normal([n_hidden_2, n_hidden_1])),
    'decoder_h3': tf.Variable(tf.random_normal([n_hidden_1, n_input])),
}
biases = {
    'encoder_b1': tf.Variable(tf.random_normal([n_hidden_1])),
    'encoder_b2': tf.Variable(tf.random_normal([n_hidden_2])),
    'encoder_b3': tf.Variable(tf.random_normal([n_hidden_3])),
    'decoder_b1': tf.Variable(tf.random_normal([n_hidden_2])),
    'decoder_b2': tf.Variable(tf.random_normal([n_hidden_1])),
    'decoder_b3': tf.Variable(tf.random_normal([n_input])),
}


# Building the encoder
def encoder(x):
    # Encoder Hidden layer with sigmoid activation #1
    layer_1 = tf.nn.sigmoid(tf.add(tf.matmul(x, weights['encoder_h1']),biases['encoder_b1']))
# Decoder Hidden layer with sigmoid activation #2
    layer_2 = tf.nn.sigmoid(tf.add(tf.matmul(layer_1, weights['encoder_h2']),biases['encoder_b2']))
    layer_3 = tf.nn.sigmoid(tf.add(tf.matmul(layer_2, weights['encoder_h3']),biases['encoder_b3']))

    return layer_3


# Building the decoder
def decoder(x):
    # Encoder Hidden layer with sigmoid activation #1
    layer_1 = tf.nn.sigmoid(tf.add(tf.matmul(x, weights['decoder_h1']),biases['decoder_b1']))
    # Decoder Hidden layer with sigmoid activation #2
    layer_2 = tf.nn.sigmoid(tf.add(tf.matmul(layer_1, weights['decoder_h2']),biases['decoder_b2']))
    layer_3 = tf.nn.sigmoid(tf.add(tf.matmul(layer_2, weights['decoder_h3']),biases['decoder_b3']))
    return layer_3

# Construct model
encoder_op = encoder(X)
decoder_op = decoder(encoder_op)

# Prediction
y_pred = decoder_op
# Targets (Labels) are the input data.
y_true = X

y_encode = encoder(X)

# Define loss and optimizer, minimize the squared error
cost = tf.reduce_mean(tf.pow(y_true - y_pred, 2))
optimizer = tf.train.RMSPropOptimizer(learning_rate).minimize(cost)

# Initializing the variables
init = tf.initialize_all_variables()

# Launch the graph
with tf.Session() as sess:
    sess.run(init)
    total_batch = int(total_train_size/batch_size)
    # Training cycle
    for epoch in range(training_epochs):
        # Loop over all batches
        for i in range(total_batch):
            batch_xs = train_data[(i * batch_size):((i + 1) * batch_size)]
            # Run optimization op (backprop) and cost op (to get loss value)
            _, c = sess.run([optimizer, cost], feed_dict={X: batch_xs})
        # Display logs per epoch step
        if epoch % display_step == 0:
            print("Epoch:", '%04d' % (epoch+1),
                  "cost=", "{:.9f}".format(c))
    writer = tf.train.SummaryWriter('/tmp/autoencoder',sess.graph)
    print("Optimization Finished!")
    
    # Applying encode over test set
    encode = sess.run(
                             y_encode, feed_dict={X: test_data})

    for i in range(total_test_size):
        log = encode[i]
        neural.append(log)

input = np.asarray(neural, dtype =np.float32)
iterator_1 = np.random.randint(0,total_test_size,num_of_neural_data)
neural_temp_data=[]
neural_temp_target =[]
for i in iterator_1:
    img1 = file_names[i][4:8]
    temp1 = input[i]
    j = np.random.randint(0,total_test_size)
    img2 = file_names[j][4:8]
    temp2 = input[j]
    tmp_data = np.concatenate((temp1,temp2),axis=0)
    if img1 == img2:
        tmp_target = 1
    else:
        tmp_target = 0
    neural_temp_data.append(tmp_data)
    neural_temp_target.append(tmp_target)

neural_data = np.asarray(neural_temp_data, dtype =np.float32)
neural_target = np.asarray(neural_temp_target, dtype =np.float32)
print(neural_data.shape)
print(neural_target.shape)
os.chdir('path to save the file')
np.savez("neural_data",neural_data)
np.savez("neural_target",neural_target)
