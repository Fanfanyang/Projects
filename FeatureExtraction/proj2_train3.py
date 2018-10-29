

from __future__ import print_function
import numpy as np
import tensorflow as tf
from keras.callbacks import TensorBoard
import random
import os,sys,pickle
from PIL import Image

# Parameters
learning_rate = 0.001
batch_size = 20
display_step = 3
img_length = 800
n_input = img_length*img_length
n_classes = 2
dropout = 0.75
upper_times = 100
pixel_normalization = 255

print("Read input")

#Import
file_data1 = np.load('train_data.npz')
file_target1 = np.load('train_target.npz')
train_data = file_data1['arr_0']
train_target = file_target1['arr_0']
train_data = train_data.astype(float)
train_target = train_target.astype(float)
train_tmp = 1-train_target
train_target = np.concatenate((train_target,train_tmp),axis=0)
train_target = np.reshape(train_target, (n_classes, len(train_data)))
train_target = train_target.transpose()
train_data = np.concatenate((train_data,train_data[1:batch_size,]),axis=0)
train_data /= pixel_normalization
train_target = np.concatenate((train_target,train_target[1:batch_size,]),axis=0)

file_data2 = np.load('test_data.npz')
file_target2 = np.load('test_target.npz')
test_data = file_data2['arr_0']
test_target = file_target2['arr_0']
test_data = test_data.astype(float)
test_target = test_target.astype(float)
test_tmp = 1-test_target
test_target = np.concatenate((test_target,test_tmp),axis=0)
test_target = np.reshape(test_target, (n_classes, len(test_data)))
test_target = test_target.transpose()
test_data = np.concatenate((test_data,test_data[1:batch_size,]),axis=0)
test_data /= pixel_normalization
test_target = np.concatenate((test_target,test_target[1:batch_size,]),axis=0)


print("Model Initialization")

training_iters = len(train_target)
acc_th = 0.85
loss_th = 5e5
neurons_first_layer = 16
squares_first_layer = 10
pooling_first_layer = 4
neurons_second_layer = 32
squares_second_layer = 10
pooling_second_layer = 4
neurons_third_layer = 64
squares_third_layer = 10
pooling_third_layer = 5
neurons_forth_layer = 128
squares_forth_layer = 5
pooling_forth_layer = 2
neurons_last_layer = neurons_forth_layer
squares_last_layer = 5

# tf Graph input
x = tf.placeholder(tf.float32, [None, n_input])
y = tf.placeholder(tf.float32, [None, n_classes])
keep_prob = tf.placeholder(tf.float32) #dropout (keep probability)

# Create some wrappers for simplicity
def conv2d(x, W, b, strides=1):
    # Conv2D wrapper, with bias and relu activation
    x = tf.nn.conv2d(x, W, strides=[1, strides, strides, 1], padding='SAME')
    x = tf.nn.bias_add(x, b)
    return tf.nn.relu(x)


def maxpool2d(x, k=2):
    # MaxPool2D wrapper
    return tf.nn.max_pool(x, ksize=[1, k, k, 1], strides=[1, k, k, 1],
                          padding='SAME')

# Create model
def conv_net(x, weights, biases, dropout):
    # Reshape input picture
    x = tf.reshape(x, shape=[-1, img_length, img_length, 1])
    
    # Convolution Layer
    conv1 = conv2d(x, weights['wc1'], biases['bc1'])
    # Max Pooling (down-sampling)
    conv1 = maxpool2d(conv1, k=pooling_first_layer)
    
    # Convolution Layer
    conv2 = conv2d(conv1, weights['wc2'], biases['bc2'])
    # Max Pooling (down-sampling)
    conv2 = maxpool2d(conv2, k=pooling_second_layer)
    
    # Convolution Layer
    conv3 = conv2d(conv2, weights['wc3'], biases['bc3'])
    # Max Pooling (down-sampling)
    conv3 = maxpool2d(conv3, k=pooling_third_layer)
    
    # Convolution Layer
    conv4 = conv2d(conv3, weights['wc4'], biases['bc4'])
    # Max Pooling (down-sampling)
    conv4 = maxpool2d(conv4, k=pooling_forth_layer)
    
    # Fully connected layer
    # architecture modify
    # Reshape conv2 output to fit fully connected layer input
    fc1 = tf.reshape(conv4, [-1, weights['wd1'].get_shape().as_list()[0]])
    fc1 = tf.add(tf.matmul(fc1, weights['wd1']), biases['bd1'])
    fc1 = tf.nn.relu(fc1)
    # Apply Dropout
    fc1 = tf.nn.dropout(fc1, dropout)
    
    # Output, class prediction
    out = tf.add(tf.matmul(fc1, weights['out']), biases['out'])
    
    return out

# Store layers weight & bias
weights = {
    # 5x5 conv, 1 input, 32 outputs
    'wc1': tf.Variable(tf.random_normal([squares_first_layer, squares_first_layer, 1, neurons_first_layer])),
    # 5x5 conv, 32 inputs, 64 outputs
    'wc2': tf.Variable(tf.random_normal([squares_second_layer, squares_second_layer, neurons_first_layer, neurons_second_layer])),
    'wc3': tf.Variable(tf.random_normal([squares_third_layer, squares_third_layer, neurons_second_layer, neurons_third_layer])),
    'wc4': tf.Variable(tf.random_normal([squares_forth_layer, squares_forth_layer, neurons_third_layer, neurons_forth_layer])),
    # fully connected, 7*7*64 inputs, 1024 outputs
    'wd1': tf.Variable(tf.random_normal([squares_last_layer*squares_last_layer*neurons_last_layer, 1024])),
    # 1024 inputs, 2 outputs (class prediction)
    'out': tf.Variable(tf.random_normal([1024, n_classes]))
}

biases = {
    'bc1': tf.Variable(tf.random_normal([neurons_first_layer])),
    'bc2': tf.Variable(tf.random_normal([neurons_second_layer])),
    'bc3': tf.Variable(tf.random_normal([neurons_third_layer])),
    'bc4': tf.Variable(tf.random_normal([neurons_forth_layer])),
    'bd1': tf.Variable(tf.random_normal([1024])),
    'out': tf.Variable(tf.random_normal([n_classes]))
}

# Construct model
pred = conv_net(x, weights, biases, keep_prob)

# Define loss and optimizer
cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(pred, y))
#tf.scalar_summary('cost', cost)

optimizer = tf.train.AdamOptimizer(learning_rate=learning_rate).minimize(cost)
#tf.scalar_summary('optimizer', optimizer)


# Evaluate model
correct_pred = tf.equal(tf.argmax(pred, 1), tf.argmax(y, 1))
accuracy = tf.reduce_mean(tf.cast(correct_pred, tf.float32))

# Initializing the variables
init = tf.initialize_all_variables()

print("Training")

# Launch the graph
with tf.Session() as sess:
    sess.run(init)
    # Keep training until reach max iterations
    yy = 0
    while yy < upper_times:
        print ("Iteration run " + str(yy))
        tot_loss = 0
        tot_acc = 0
        count = 0
        step = 1
        while step * batch_size < training_iters:
            #print ("Process: " + "{:.3f}".format(batch_size*step/float(training_iters)))
            batch_x = train_data[((step-1)*batch_size):(step*batch_size-1)]
            batch_y = train_target[((step-1)*batch_size):(step*batch_size-1)]
            #batch_y = np.reshape(batch_y, (batch_size, n_classes))
            #print ("Target: " + str(batch_y))
            sess.run(optimizer, feed_dict={x: batch_x, y: batch_y, keep_prob: dropout})
            # Calculate batch loss and accuracy
            if step % display_step == 0:
                loss, acc = sess.run([cost, accuracy], feed_dict={x: batch_x,y: batch_y,keep_prob: 1.})
                print("Process: " + "{:.3f}".format(batch_size*step/float(training_iters)) + ", Batch Loss= " + \
                    "{:.4f}".format(loss) + ", Acc= " + \
                    "{:.4f}".format(acc))
                tot_loss += float(loss)
                tot_acc += float(acc)
                count += 1
            step += 1
        avg_loss = tot_loss/count
        avg_acc = tot_acc/count
        print("Iteration " + str(yy) + ", Average Loss= " + "{:.4f}".format(avg_loss) + ", Average Training Accuracy= " + "{:.4f}".format(avg_acc))
        #if avg_acc > acc_th and yy > 0:
        if avg_loss < loss_th and yy > 0:
            yy = upper_times
        yy += 1
    print("Optimization Finished!")
    
    # Calculate accuracy for 256 mnist test images
    test_x = test_data
    test_y = test_target
    #test_y = np.reshape(test_y,(batch_size, n_classes))
    print("Testing Accuracy:", \
          sess.run(accuracy, feed_dict={x: test_x,
                   y: test_y,
                   keep_prob: 1.}))


#merged = tf.summary.merge_all()


writer = tf.train.SummaryWriter('tensorboard',sess.graph)




























