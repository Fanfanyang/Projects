use a 3-step trace to run:
prep1 -> prep2 -> prep3

For example,
# location latent states
prep1 -> prep2_1 -> prep3_1 (normal, train once 0, train once 1)*2
or
# individual vehicle latent states
prep1 -> prep2_2 -> prep3_2 (one state, multi state)
or
# action conditioned on xt, location latent states
prep1 -> prep2_1 -> prep3_1_2
or
# other mastsim iterations
prep1_2 -> prep2_1 -> prep3_1
