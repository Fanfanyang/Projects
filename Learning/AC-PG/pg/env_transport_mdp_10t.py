"""

@author: fanyang

Transportation optimal control problems environment

"""

# In[1]:

from __future__ import division

import numpy as np
from numpy import loadtxt
import random

info_road = loadtxt("fromR_inputs/info_road.csv", comments="#", delimiter=",", unpack=False)
possible_actions = loadtxt("fromR_inputs/possible_actions.csv", comments="#", delimiter=",", unpack=False)
policy_init = loadtxt("fromR_inputs/policy_init.csv", comments="#", delimiter=",", unpack=False)
person_state_d = loadtxt("fromR_inputs/person_state_d.csv", comments="#", delimiter=",", unpack=False)
xt_real = loadtxt("fromR_inputs/xt_real.csv", comments="#", delimiter=",", unpack=False)
       
# In[2]:

class transport_env():
    def __init__(self,gamma,info_road,possible_actions,policy_init):
        self.obs_hist = 60
        self.states = 25
        self.totvehicles = 50
        self.roadload = info_road[:,0]
        self.timemoveout = info_road[:,1]
        self.BETA_late_ar = -18.
        self.BETA_dur = 6. #6.
        self.BETA_trav_modeq = 0.
        self.Rmin = self.totvehicles*(-24.)
        self.Rmax = self.totvehicles*(6.)
        
        self.time_scale = 30
        self.worktime = int(480/self.time_scale)
        self.hometime = int(960/self.time_scale)
        self.gamma = gamma
        self.learnable_theta = np.array([1,2,3,4,5,6,7,8,9,10])-1
        self.homeout = np.array([1,2,3,4,5,6,7,8,9])-1
        self.workout = np.array([10])-1
        self.policy_init = policy_init
        
        self.start_time = 0
        self.endtime = int(1400/self.time_scale)
        
        self.action_space = []
        self.action_idx = []
        self.action_len = []
        action_idx_tmp = 0
        possible_actions = possible_actions[self.states:,]
        for i in range(self.states):
            self.action_space.append(possible_actions[possible_actions[:,0]==(i+1),1].astype(int)-1)
            self.action_idx.append(range(len(self.action_space[i]))+np.array(action_idx_tmp))
            self.action_len.append(len(self.action_idx[i]))
            action_idx_tmp += len(self.action_space[i])
        self.action_space = np.asanyarray(self.action_space)
        self.st_est = np.full((self.endtime+2,self.totvehicles),0)
        self.rt_est = np.full((self.endtime+2,self.totvehicles),0)
        self.at_est = np.full((self.endtime+2,self.totvehicles),0)
        self.xt_est = np.full((self.endtime+2,self.states),0)
        self.xt_est[0,0] = self.totvehicles
        self.obs_locations = np.array([2,21])
        self.obs_vehicles = np.linspace(0,49,50).astype(int)
        self.tot_observations = 3
        self.timeidx = 2
        
        self.tot_actions = 2
        self.vehicle_action = np.zeros(shape=(50,2))
        self.cur_time = self.start_time
        self.train_data_actor = np.zeros(shape=(self.endtime-self.start_time,self.tot_observations))
        self.train_label_actor = np.zeros(shape=(self.endtime-self.start_time,self.tot_actions))
        self.train_label_critic = np.zeros(self.endtime-self.start_time)
        self.prior_training_data(policy_init)
        
    def prior_training_data(self,policy_init):
        for t in range(self.start_time,self.endtime):
            self.train_data_actor[t-self.start_time,0:2] = xt_real[t,0:2]
            self.train_data_actor[t-self.start_time,2] = t
            
            policy_tmp = np.zeros(2)
            policy_tmp[0] = sum(policy_init[t,self.homeout])
            policy_tmp[1] = policy_init[t,self.workout]
            self.train_label_actor[t-self.start_time,] = policy_tmp
            
        r_accum = 0
        for t in range(self.endtime-1,self.start_time-1,-1):
            r_tmp = 0
            for i in range(self.states):
                r_tmp += self.reward(i,t)*xt_real[t,i]
            r_accum = self.gamma*r_accum + r_tmp
            self.train_label_critic[t-self.start_time] = r_accum
        
    def reward(self,location,time):
        r_dur = 0
        r_late_ar = self.BETA_late_ar
        
        if (time < self.hometime and time >= self.worktime and location == 1):
            r_dur = self.BETA_dur*3
            r_late_ar = 0
        if ((time >= self.hometime or time < self.worktime) and location == 0):
            r_dur = self.BETA_dur/3
            r_late_ar = 0
        if location > 1:
            r_onroad = self.BETA_trav_modeq
        else:
            r_onroad = 0
        tot_reward = r_dur + r_late_ar + r_onroad
        return tot_reward
        
            
    def transition(self,state_p,state_l):
        if state_p > 1:
            tmp_a = state_p-2
            tmo = max(state_l*self.timemoveout[tmp_a]/self.roadload[tmp_a],self.timemoveout[tmp_a])
            pmo = 1/tmo
        else:
            pmo = 1
        return pmo
        
    def step_one_vehicle(self,state_p,action_p,state_l):
        p_tran = 1
        p_ref = random.random()
        if sum(action_p)>=1:
            action_p=action_p/sum(action_p)  
            action_sampled = np.random.choice(self.action_space[state_p], 1, p=action_p)
        else:
            action_p=np.concatenate((np.array([1-sum(action_p)]),action_p))  
            action_sampled = np.random.choice(np.append(-1,self.action_space[state_p]), 1, p=action_p)
        if (p_tran > p_ref) and (action_sampled >= 0) and (action_sampled != state_p):
            next_state = action_sampled
            self.xt_est[self.cur_time+1,state_p] -= 1 
            self.xt_est[self.cur_time+1,next_state] += 1 
        else:
            next_state = state_p    
        r = self.reward(state_p,self.cur_time)
        return (next_state,action_sampled,r)
    
    def step(self,action):
        action = np.squeeze(np.asarray(action))
        action_all = self.policy_init[self.cur_time,]
        action_all[self.homeout] = action[0]/len(self.homeout)
        action_all[self.workout] = action[1]
        next_rp = 0.
        
        for t in range(self.time_scale):
        
            self.xt_est[self.cur_time+1,] = self.xt_est[self.cur_time,]
            for k in range(self.totvehicles):
                state_p = self.st_est[self.cur_time,k]
                action_p = action_all[self.action_idx[state_p]]
                state_l = self.xt_est[self.cur_time,state_p]
                n_sp,a_sp,n_rp = self.step_one_vehicle(state_p,action_p,state_l)
                self.st_est[self.cur_time+1,k] = n_sp
                self.at_est[self.cur_time,k] = a_sp
                self.rt_est[self.cur_time,k] = n_rp
                next_rp += n_rp
            self.st_est[self.cur_time,] = self.st_est[self.cur_time+1,]
            self.xt_est[self.cur_time,] = self.xt_est[self.cur_time+1,]
        self.cur_time += 1 
        if self.cur_time >= self.endtime:
            done = 1
        else:
            done = 0

        next_rp = np.array([next_rp])
        return (self.xt_est[self.cur_time,0:2],self.cur_time,next_rp,done)
    
    def rd_sample_action(self):
        a_tmp = list()
        for k in range(self.tot_actions):
            a_tmp.append(random.uniform(0, 1))
        a = np.array(a_tmp)
        return a
    
    def reset(self):
        self.st_est = np.full((self.endtime+2,self.totvehicles),0)
        self.rt_est = np.full((self.endtime+2,self.totvehicles),0)
        self.at_est = np.full((self.endtime+2,self.totvehicles),0)
        self.xt_est = np.full((self.endtime+2,self.states),0)
        self.xt_est[self.start_time,] = xt_real[self.start_time,]
        self.st_est[self.start_time,] = person_state_d[self.start_time,]-1
        init_reset = np.zeros(3)
        init_reset[0:2] = xt_real[self.start_time,0:2]
        init_reset[self.timeidx] = self.start_time
        self.cur_time = self.start_time
        return (init_reset)








































