# Solve a zero-sum game using linear programming example
# by Niclas Richter


using JuMP
using HiGHS

# Define the payoff matrix
A = [1 0; -1 2]

dim_player1 = size(A, 1)
dim_player2 = size(A, 2)

# Solve the primary problem +++++++++++++++++++++++++++++++++++++++++++++++++++
## Set up the model using the HiGHS solver
model = Model(HiGHS.Optimizer)

## Define the variables
@variable(model, x[1:dim_player1] >= 0)
@variable(model, v)
e1 = ones(1, dim_player1)

## Define the constraints
@constraint(model, sum(x) == 1)
@constraint(model, transpose(x) * A .>= v .* e1)

## Define the objective function for the primal problem
@objective(model, Max, v)

## Solve the optimization problem
optimize!(model)

# Output of the values for the Nash equilibrium
strategy_player1 = [value(x[i]) for i in 1:dim_player1]
println("Nash equlibrium strategy for player 1:\t $strategy_player1")
println("Value for Player 1:\t $(objective_value(model))")

# Solve the dual problem ++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Set up the model using the HiGHS solver
model = Model(HiGHS.Optimizer)

## Define the variables
@variable(model, y[1:dim_player2] >= 0)
@variable(model, w)
e2 = ones(dim_player1, 1)

## Define the constraints
@constraint(model, sum(y) == 1)
@constraint(model, A * y .<= w .* e2)

## Define the objective function for the primal problem
@objective(model, Min, w)

## Solve the dual optimization problem
optimize!(model)

# Output of the values for the Nash equilibrium
strategy_player2 = [value(y[i]) for i in 1:dim_player2]
println("Nash equlibrium strategy for player 1:\t $strategy_player2")
println("Value for Player 1:\t $(objective_value(model))")