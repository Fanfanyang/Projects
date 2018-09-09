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
import keras.backend as K

import tensorflow as tf

import random
from collections import deque
import sys
import csv

from keras.callbacks import ModelCheckpoint
import matplotlib.pyplot as plt
from scipy import stats
from env_transport_pomdp_10t import *

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

		self.learning_rate_actor = 1e-4
		self.learning_rate_critic = 0.01
		
		#self.grad_scale = 0.01    
        
		self.target_update_rate = 0.01    
		self.epsilon = 0
        
		self.state_scale = 1/(1e1)
		self.action_scale = 1e3
		self.q_scale = 1/(1e5)
		self.gamma = 1
		self.tau   = .125

		# ===================================================================== #
		#                               Actor Model                             #
		# Chain rule: find the gradient of chaging the actor network params in  #
		# getting closest to the final value network predictions, i.e. de/dA    #
		# Calculate de/dA as = de/dC * dC/dA, where e is error, C critic, A act #
		# ===================================================================== #

		self.memory = deque(maxlen=2*(self.env.endtime-self.env.start_time))
		self.actor_state_input, self.actor_model = self.create_actor_model()
		_, self.target_actor_model = self.create_actor_model()

		self.actor_critic_grad = tf.placeholder(tf.float32, 
			[None, self.env.tot_actions]) # where we will feed de/dC (from critic)
		
		actor_model_weights = self.actor_model.trainable_weights
		self.actor_grads = tf.gradients(self.actor_model.output, 
			actor_model_weights, -self.actor_critic_grad) # dC/dA (from actor)
		grads = zip(self.actor_grads, actor_model_weights)
		self.optimize = tf.train.AdamOptimizer(self.learning_rate_actor).apply_gradients(grads)

		# ===================================================================== #
		#                              Critic Model                             #
		# ===================================================================== #		

		self.critic_state_input, self.critic_action_input, \
			self.critic_model = self.create_critic_model()
		_, _, self.target_critic_model = self.create_critic_model()

		self.critic_grads = tf.gradients(self.critic_model.output, 
			self.critic_action_input) # where we calcaulte de/dC for feeding above
		
		self.sess.run(tf.initialize_all_variables())

	# ========================================================================= #
	#                              Model Definitions                            #
	# ========================================================================= #

	def create_actor_model(self):
		state_input = Input(shape=(self.env.tot_observations,))
		h1 = Dense(6, activation='relu')(state_input)
		h2 = Dense(24, activation='relu')(h1)
		output = Dense(self.env.tot_actions, activation='relu')(h2)
		
		model = Model(input=state_input, output=output)
		adam  = Adam(lr=self.learning_rate_actor)
		model.compile(loss="mse", optimizer=adam)
		return state_input, model
    
	def create_critic_model(self):
		state_input = Input(shape=(self.env.tot_observations,))
		state_h1 = Dense(6, activation='relu')(state_input)        
        
		action_input = Input(shape=(self.env.tot_actions,))
		action_h1 = Dense(6, activation='relu')(action_input)
        
		merged = concatenate([state_h1,action_h1], axis=-1)
        
		h1 = Dense(24, activation='relu')(merged)
		h2 = Dense(24, activation='relu')(h1)
		output = Dense(1, activation='linear')(h2)
		model  = Model(input=[state_input,action_input], output=output)
		
		adam  = Adam(lr=self.learning_rate_critic)
		model.compile(loss="mse", optimizer=adam)
		return state_input,action_input, model

	# ========================================================================= #
	#                               Model Training                              #
	# ========================================================================= #

	def remember(self, cur_state, action, reward, new_state, done):
		self.memory.append([cur_state, action, reward, new_state, done])

	def _train_actor(self, samples):
		for sample in samples:
			cur_state, action, reward, new_state, _ = sample
			predicted_action = self.actor_model.predict(cur_state)
			grads = self.sess.run(self.critic_grads, feed_dict={
				self.critic_state_input:  cur_state,
				self.critic_action_input: predicted_action
			})[0]#*self.grad_scale

			self.sess.run(self.optimize, feed_dict={
				self.actor_state_input: cur_state,
				self.actor_critic_grad: grads
			})
            
	def _train_critic(self, samples):
		for sample in samples:
			cur_state, action, reward, new_state, done = sample
			reward_train = reward
			if not done:
				target_action = self.target_actor_model.predict(new_state)
				future_reward = self.target_critic_model.predict(
					[new_state, target_action])[0][0]
				reward_train = reward + self.gamma * future_reward     
			self.critic_model.fit([cur_state, action], reward_train, verbose=0)
		
	def train_actor(self):
		batch_size = 32
		if len(self.memory) < batch_size:
			return

		samples = random.sample(self.memory, batch_size)
		self._train_actor(samples)
        
	def train_critic(self):
		batch_size = 32
		if len(self.memory) < batch_size:
			return

		samples = random.sample(self.memory, batch_size)
		self._train_critic(samples)

	# ========================================================================= #
	#                         Target Model Updating                             #
	# ========================================================================= #

	def _update_actor_target(self):
		actor_model_weights  = self.actor_model.get_weights()
		actor_target_weights = self.target_actor_model.get_weights()
		
		for i in range(len(actor_target_weights)):
			actor_target_weights[i] = (1-self.target_update_rate)*actor_target_weights[i]+self.target_update_rate*actor_model_weights[i]
		self.target_actor_model.set_weights(actor_target_weights)

	def _update_critic_target(self):
		critic_model_weights  = self.critic_model.get_weights()
		critic_target_weights = self.target_critic_model.get_weights()
		
		for i in range(len(critic_target_weights)):
			critic_target_weights[i] = (1-self.target_update_rate)*critic_target_weights[i]+self.target_update_rate*critic_model_weights[i]
		self.target_critic_model.set_weights(critic_target_weights)		

	def update_target(self):
		self._update_actor_target()
		self._update_critic_target()

	# ========================================================================= #
	#                              Model Predictions                            #
	# ========================================================================= #

	def act(self, cur_state):
		if np.random.random() < self.epsilon:
			return self.env.rd_sample_action() * self.action_scale
		return self.actor_model.predict(cur_state)


# In[1]:
# prior training
        
sess = tf.Session()
K.set_session(sess)
env = transport_env(1,info_road,possible_actions,policy_init)
actor_critic = ActorCritic(env, sess)
prior_train_episodes = 10000
figList = []
axList = []
update_actor_freq = 200
update_critic_freq = 20
num_episodes = 101
pre_train_steps = 200
total_steps = 0
rList = []

days = 10
tot_len = days*(env.endtime-env.start_time)
pre_train_data_actor = np.zeros(shape=(tot_len,env.tot_observations))
pre_train_label_actor = np.zeros(shape=(tot_len,env.tot_actions))
pre_train_label_critic = np.zeros(tot_len)
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
        new_state[0:4] = obs
        new_state = new_state.reshape((1, env.tot_observations))
        
        r_env[env.cur_time-1] = reward
        
        pre_train_data_actor[total_steps,] = cur_state * actor_critic.state_scale
        pre_train_label_actor[total_steps,] = action * actor_critic.action_scale
        
        cur_state = new_state
        total_steps += 1
        
        if done == True:
            q_env[env.endtime] = r_env[env.endtime]
            tt = env.endtime-1
            r_accum = r_env[env.endtime]
            while tt >= env.start_time:
                r_accum = actor_critic.gamma*r_accum + r_env[tt]
                q_env[tt] = r_accum
                tt = tt-1
            pre_train_label_critic[tot_len/days*ne : env.endtime - env.start_time + tot_len/days*ne] \
                = q_env[env.start_time : env.endtime] * actor_critic.q_scale
            break
           
    ne += 1

# prior training
print('prior training')
lr_tmp = K.get_value(actor_critic.actor_model.optimizer.lr)
K.set_value(actor_critic.actor_model.optimizer.lr, 1e-3)
actor_hist = actor_critic.actor_model.fit(pre_train_data_actor,
                                          pre_train_label_actor, epochs=300, batch_size = 32) #, validation_split = 0.2)
K.set_value(actor_critic.actor_model.optimizer.lr, lr_tmp)

lr_tmp = K.get_value(actor_critic.critic_model.optimizer.lr)
K.set_value(actor_critic.critic_model.optimizer.lr, 1e-3)
critic_hist = actor_critic.critic_model.fit([pre_train_data_actor, 
                             pre_train_label_actor], 
                             pre_train_label_critic, epochs=300, batch_size = 32) #, validation_split = 0.01)
K.set_value(actor_critic.critic_model.optimizer.lr, lr_tmp)

for i in np.arange(1000):
    actor_critic.update_target()

actor_predicted = actor_critic.actor_model.predict(pre_train_data_actor[-tot_len/days:,], batch_size=128)
critic_predicted = actor_critic.critic_model.predict([pre_train_data_actor[-tot_len/days:,], 
                             pre_train_label_actor[-tot_len/days:,]], batch_size=128)

plt.plot(critic_predicted)
plt.plot(pre_train_label_critic[-tot_len/days:,])

plt.plot(actor_predicted[:,0])
plt.plot(pre_train_label_actor[-tot_len/days:,0])

plt.plot(actor_predicted[:,1])
plt.plot(pre_train_label_actor[-tot_len/days:,1])


# In[1]:

# reinforcement learning

ne = 0
total_steps = 0
while ne < num_episodes:
    cur_state = env.reset()
    cur_state = cur_state * actor_critic.state_scale
    action = env.rd_sample_action()
    rAll = 0
        
    q_critic = np.zeros(env.endtime+1)
    q_env = np.zeros(env.endtime+1)
    r_env = np.zeros(env.endtime+1)
    
    print(ne)
    while True:
        cur_state = cur_state.reshape((1, env.tot_observations))
        action = actor_critic.act(cur_state)
        action = action.reshape((1, env.tot_actions))
        
        obs, time, reward, done = env.step(action/actor_critic.action_scale)
        reward = reward * actor_critic.q_scale
        
        new_state = np.zeros(cur_state.shape[1])
        new_state[env.timeidx] = time
        new_state[0:4] = obs
        new_state = new_state.reshape((1, env.tot_observations))
        new_state = new_state * actor_critic.state_scale
        
        q_critic[env.cur_time-1] = actor_critic.critic_model.predict([cur_state, action])[0][0]
        r_env[env.cur_time-1] = reward
        
        actor_critic.remember(cur_state, action, reward, new_state, done)
        
        if total_steps % update_actor_freq == 0 and total_steps > pre_train_steps:
            actor_critic.train_actor()
            
        if total_steps % update_critic_freq == 0 and total_steps > pre_train_steps:
            actor_critic.train_critic()
            actor_critic.update_target()
        
        rAll += reward
        cur_state = new_state
        total_steps += 1
        if done == True:
            break
            
    rList.append(rAll)
    
    if ne % 10 == 0 and actor_critic.epsilon > 1e-4:
        actor_critic.epsilon = max(actor_critic.epsilon-1e-4, 1e-4)
        
    if ne % 5 == 0:
        q_env[env.endtime] = r_env[env.endtime]
        tt = env.endtime-1
        r_accum = r_env[env.endtime]
        while tt >= env.start_time:
            r_accum = actor_critic.gamma*r_accum + r_env[tt]
            q_env[tt] = r_accum
            tt = tt-1
        q_diff = q_critic - q_env
        print(ne,sum(abs(q_diff)))
        fig_name = 'result/'+'q-fig'+str(ne)+'.png'       
        figList.append(plt.figure())
        axList.append(figList[-1].add_subplot(111))  
        axList[-1].plot(q_env)
        #axList[-1].plot(r_env)
        axList[-1].plot(q_critic)
        figList[-1].savefig(fig_name)
    
    if ne % 5 == 0:
        print(ne,np.mean(rList[-5:]))
            
    if ne % 5 == 0:
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
        
    if ne % 10 == 0:
        csv_writer(xt_est,'result_ac.csv')
        csv_writer(rList,'rList_ac.csv')
            
    ne+=1
















    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
