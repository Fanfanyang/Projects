"""

@author: fanyang

solving transportation optimal control problems using actor-critic

"""

# In[1]:

import gym
import numpy as np 
from keras.models import Sequential, Model
from keras.layers import Dense, Dropout, Input, concatenate
from keras.layers.merge import Add, Multiply
from keras.optimizers import Adam
import keras.backend as K
from keras.layers.advanced_activations import LeakyReLU

import tensorflow as tf
import keras

import random
from collections import deque
import sys
import csv

from keras.callbacks import ModelCheckpoint
import matplotlib.pyplot as plt
from scipy import stats
from env_transport_mdp_10t import *

# In[1]:
# model and helper functions
#----------------------------------------------------------------------
def csv_writer(data, path):
    """
    Write data to a CSV file path
    """
    with open(path, "wb") as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        for line in data:
            writer.writerow(line)
            
class ActorCritic:
	def __init__(self, env, sess):
		self.env  = env
		self.sess = sess

		self.learning_rate_actor = 0.001
		self.target_update_rate = 1
		self.epsilon = 0 #.001
        
		self.state_scale = 1/1e2
		self.q_scale = 1/1e4
		self.gamma = 1
		self.tau   = .125

		# ===================================================================== #
		#                               Actor Model                             #
		# Chain rule: find the gradient of chaging the actor network params in  #
		# getting closest to the final value network predictions, i.e. de/dA    #
		# Calculate de/dA as = de/dC * dC/dA, where e is error, C critic, A act #
		# ===================================================================== #
        
		self.actor_state_input, self.actor_model = self.create_actor_model()
		
		# ===================================================================== #
		#                              Critic Model                             #
		# ===================================================================== #		

		self.sess.run(tf.initialize_all_variables())

	# ========================================================================= #
	#                              Model Definitions                            #
	# ========================================================================= #

	def create_actor_model(self):
		state_input = Input(shape=(self.env.tot_observations,))
		h1 = Dense(6, activation='relu')(state_input)
		h2 = Dense(24, activation='relu')(h1)
		output1 = Dense(10, activation='softmax')(h2)
		output2 = Dense(10, activation='softmax')(h2)
		
		model = Model(input=state_input, output=[output1,output2])
		adam  = Adam(lr=self.learning_rate_actor)
		model.compile(loss="categorical_crossentropy", optimizer=adam)
		return state_input, model

	# ========================================================================= #
	#                              Model Predictions                            #
	# ========================================================================= #

	def act(self, cur_state):
		if np.random.random() < self.epsilon:
			return self.env.rd_sample_action() #* self.action_scale
		return self.actor_model.predict(cur_state)


# In[1]:
# prior training
        
sess = tf.Session()
K.set_session(sess)
env = transport_env(1,info_road,possible_actions,policy_init)
actor_critic = ActorCritic(env, sess)
figList = []
axList = []
num_episodes = 1000
total_steps = 0
rList = []
action_scale = 1000.

days = 5
tot_len = days*(env.endtime-env.start_time)
pre_train_data_actor = np.zeros(shape=(tot_len,env.tot_observations))
pre_train_label_actor1 = np.zeros(shape=(tot_len,10))
pre_train_label_actor2 = np.zeros(shape=(tot_len,10))
ne = 0
total_steps = 0
while ne < days:
    print(ne)
    cur_state = env.reset()
    action = env.rd_sample_action()
    r_env = np.zeros(env.endtime+1)
    q_env = np.zeros(env.endtime+1)
    while True:
        cur_state = cur_state.reshape((1, env.tot_observations))
        
        policy_tmp = np.zeros(2)
        policy_tmp[0] = sum(policy_init[env.cur_time*env.time_scale,env.homeout])
        policy_tmp[1] = policy_init[env.cur_time*env.time_scale,env.workout]
        action = policy_tmp
        action = action.reshape((1, env.tot_actions))
        
        obs, time, reward, done = env.step(action)
        
        new_state = np.zeros(cur_state.shape[1])
        new_state[env.timeidx] = time
        new_state[0:2] = obs
        new_state = new_state.reshape((1, env.tot_observations))
        
        r_env[env.cur_time-1] = sum(env.rt_est[env.cur_time-1,])
        
        pre_train_data_actor[total_steps,] = cur_state * actor_critic.state_scale
        pre_train_label_actor1[total_steps,int(action[0][0]*action_scale)] = 1
        pre_train_label_actor2[total_steps,int(action[0][1]*action_scale)] = 1
        
        cur_state = new_state
        total_steps += 1
        
        if done == True:
            break
           
    ne += 1

# prior training
print('prior training')
actor_hist = actor_critic.actor_model.fit(pre_train_data_actor,
                                          [pre_train_label_actor1,pre_train_label_actor2], epochs=400, batch_size = 32) #, validation_split = 0.2)

# In[1]:

# reinforcement learning
ne = 0
total_steps = 0
particles = 10

while ne < num_episodes:
    rAll = 0
    mem_state = np.zeros(shape=((env.endtime-env.start_time)*particles,env.tot_observations))
    mem_action1 = np.zeros(shape=((env.endtime-env.start_time)*particles,10))
    mem_action2 = np.zeros(shape=((env.endtime-env.start_time)*particles,10))
    mem_reward = np.zeros(shape=(particles,env.endtime-env.start_time,10))
    all_reward = np.zeros(shape=particles)
    
    time_idx = np.zeros(env.endtime-env.start_time)
    for i in np.arange(env.endtime-env.start_time):
        if i < env.worktime:
            time_idx[i] = 0
        elif i < env.hometime:
            time_idx[i] = 1
        else:
            time_idx[i] = 2

    for particle in range(particles):
        print(particle)
        steps = 0
        reward_tmp = np.zeros(3)
        cur_state = env.reset()
        cur_state = cur_state * actor_critic.state_scale
        while True:

            cur_state = cur_state.reshape((1, env.tot_observations))
            policy = actor_critic.act(cur_state)
            
            action = np.zeros(env.tot_actions)
            for a in range(env.tot_actions):
                tmp_p = policy[a]
                action[a] = np.random.choice(10,1,p=tmp_p.reshape(10))    
            action = action.reshape((1, env.tot_actions))
            obs, time, reward, done = env.step(action/action_scale) #/actor_critic.action_scale)
            reward = reward * actor_critic.q_scale
            
            new_state = np.zeros(cur_state.shape[1])
            new_state[env.timeidx] = time
            new_state[0:2] = obs
            new_state = new_state.reshape((1, env.tot_observations))
            new_state = new_state * actor_critic.state_scale
            
            mem_state[(env.endtime-env.start_time)*particle+steps,] = cur_state
            mem_action1[(env.endtime-env.start_time)*particle+steps,int(action[0][0])] = 1
            mem_action2[(env.endtime-env.start_time)*particle+steps,int(action[0][1])] = 1
            reward_tmp[int(time_idx[steps])] += reward
            
            steps += 1
            cur_state = new_state
            
            if done == True:
                all_reward[particle] = sum(reward_tmp)
                
                reward_tmp = reward_tmp+3
                reward_accum = np.zeros(len(reward_tmp))
                r_sum = 0
                for i in np.arange(len(reward_tmp))[::-1]:
                    reward_accum[i] = reward_tmp[i] + actor_critic.gamma*r_sum
                    r_sum = reward_accum[i]
                
                for i in np.arange(env.endtime-env.start_time):
                    mem_reward[particle,i,] = reward_accum[int(time_idx[i])]
                break
        
    rAll = np.mean(all_reward)
    rList.append(all_reward)
    
    print('rl training')
    print(all_reward)
    mem_reward = mem_reward/100.
    #mem_reward = mem_reward - np.mean(mem_reward)
    for particle in range (particles):
        mem_action1[(env.endtime-env.start_time)*particle : (env.endtime-env.start_time)*(particle+1),] \
        = mem_action1[(env.endtime-env.start_time)*particle : (env.endtime-env.start_time)*(particle+1),]*mem_reward[particle,]
        mem_action2[(env.endtime-env.start_time)*particle : (env.endtime-env.start_time)*(particle+1),] \
        = mem_action2[(env.endtime-env.start_time)*particle : (env.endtime-env.start_time)*(particle+1),]*mem_reward[particle,]
   
    actor_hist = actor_critic.actor_model.fit(mem_state,
                                          [mem_action1,mem_action2], epochs=20, batch_size = 32) #, validation_split = 0.2)
    
    if ne % 1 == 0 and actor_critic.epsilon > 1e-4:
        actor_critic.epsilon = max(actor_critic.epsilon-1e-4, 1e-4)
        
    if ne % 1 == 0:
        print(ne,np.mean(rList[ne:]))
            
    if ne % 1 == 0:
        xt_est = np.zeros([env.st_est.shape[0],env.states])
        for i in range(env.st_est.shape[0]):
            for j in range(env.st_est.shape[1]):
                xt_est[i,int(env.st_est[i,j])] += 1 
        fig_name = 'result/'+'fig'+str(ne)+'.png'       
        figList.append(plt.figure())
        axList.append(figList[-1].add_subplot(111))        
        axList[-1].plot(xt_est[:,0])
        axList[-1].plot(xt_est[:,1])
        axList[-1].plot(xt_est.sum(axis=1)-xt_est[:,0]-xt_est[:,1])
        figList[-1].savefig(fig_name)
        
    if ne % 1 == 0:
        csv_writer(xt_est,'result_pg.csv')
        csv_writer(rList,'rList_pg.csv')
            
    ne+=1






    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
