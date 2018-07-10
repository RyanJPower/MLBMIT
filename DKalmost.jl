#=
This code implements the No Stacking, Type 1, Type 2, Type 3, Type 4, and Type 5 formulations
described in the paper Winning Daily Fantasy Hockey Contests Using Integer Programming by
Hunter, Vielma, and Zaman. We have made an attempt to describe the code in great detail, with the
hope that you will use your expertise to build better formulations.
=#

# To install DataFrames, simply run Pkg.add("DataFrames")
using DataFrames

#=
GLPK is an open-source solver, and additionally Cbc is an open-source solver. This code uses GLPK
because we found that it was slightly faster than Cbc in practice. For those that want to build
very sophisticated models, they can buy Gurobi. To install GLPKMathProgInterface, simply run
Pkg.add("GLPKMathProgInterface")
=#
using GLPKMathProgInterface

# Once again, to install run Pkg.add("JuMP")
using JuMP

#=
Variables for solving the problem (change these)
=#
# num_lineups is the total number of lineups
num_lineups = 1

# num_overlap is the maximum overlap of players between the lineups that you create
num_overlap = 7

# path_hitters is a string that gives the path to the csv file with the hitters information (see example file for suggested format)
path_hitters = "example_hitters2.csv"

# path_pitchers is a string that gives the path to the csv file with the pitchers information (see example file for suggested format)
path_pitchers = "example_pitchers2.csv"

# path_to_output is a string that gives the path to the csv file that will give the outputted results
path_to_output= "output.csv"


# This is a function that creates one lineup using the Type 4 formulation from the paper
function one_lineup_Type_4(hitters, pitchers, lineups, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, firstbasemencatchers, secondbasemencatchers, thirdbasemencatchers, shortstopcatchers, catcheroutfielders, firstsecondbasemen, firstthirdbasemen, firstbasemenshortstops, firstbasemenoutfielders, secondthirdbasemen, secondbasemenshortstops, secondbasemenoutfielders, thirdbasemenshortstops, thirdbasemenoutfielders, shortstopoutfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
    m = Model(solver=GLPKSolverMIP())


    # Variable for hitters in lineup
    @defVar(m, hitters_lineup[i=1:num_hitters], Bin)

    # Variable for pitcher in lineup
    @defVar(m, pitchers_lineup[i=1:num_pitchers], Bin)

    # Two pitcher constraint
    @addConstraint(m, sum{pitchers_lineup[i], i=1:num_pitchers} == 2)

    # Eight hitters constraint
    @addConstraint(m, sum{hitters_lineup[i], i=1:num_hitters} == 8)

    # 1 C
    @addConstraint(m, sum{catchers[i]*hitters_lineup[i], i=1:num_hitters} == 1)

    # 1 1B
    @addConstraint(m, sum{firstbasemen[i]*hitters_lineup[i], i=1:num_hitters} == 1)

    # 1 2B
    @addConstraint(m, sum{secondbasemen[i]*hitters_lineup[i], i=1:num_hitters} == 1)

    # 1 3B
    @addConstraint(m, sum{thirdbasemen[i]*hitters_lineup[i], i=1:num_hitters} == 1)

    # 1 SS
    @addConstraint(m, sum{shortstops[i]*hitters_lineup[i], i=1:num_hitters} == 1)

    # 3 OF
    @addConstraint(m, sum{outfielders[i]*hitters_lineup[i], i=1:num_hitters} == 3)

    # Financial Constraint
    @addConstraint(m, sum{hitters[i,:Salary]*hitters_lineup[i], i=1:num_hitters} + sum{pitchers[i,:Salary]*pitchers_lineup[i], i=1:num_pitchers} <= 50000)


    # exactly 3 different teams for the 8 hitters constraint
    @defVar(m, used_team[i=1:num_teams], Bin)
    @addConstraint(m, constr[i=1:num_teams], used_team[i] <= sum{hitters_teams[t, i]*hitters_lineup[t], t=1:num_hitters})
    @addConstraint(m, constr[i=1:num_teams], sum{hitters_teams[t, i]*hitters_lineup[t], t=1:num_hitters} <= 8*used_team[i])
    @addConstraint(m, sum{used_team[i], i=1:num_teams} == 3)

    catchersarray = Array(catchers+firstbasemencatchers)
    firstbasearray = Array(firstbasemen+firstsecondbasemen+firstthirdbasemen+firstbasemenshortstops+firstbasemenoutfielders)
    secondbasearray = Array(secondbasemen+firstsecondbasemen+secondthirdbasemen+secondbasemenshortstops+secondbasemenoutfielders)
    thirdbasearray = Array(thirdbasemen+thirdbasemencatchers+firstthirdbasemen+secondthirdbasemen+thirdbasemenshortstops+thirdbasemenoutfielders)
    shortstoparray = Array(shortstops+shortstopcatchers+firstbasemenshortstops+secondbasemenshortstops+thirdbasemenshortstops+shortstopoutfielders)
    outfieldarray = Array(outfielders+catcheroutfielders+firstbasemenoutfielders+secondbasemenoutfielders+thirdbasemenoutfielders+shortstopoutfielders)


    # No pitchers going against hitters
    @addConstraint(m, constr[i=1:num_pitchers], 8*pitchers_lineup[i] + sum{pitcher_opponents[k, i]*hitters_lineup[k], k=1:num_hitters}<=8)


    # Must have at least one complete line in each lineup
    # @defVar(m, line_stack[i=1:num_lines], Bin)
    # @addConstraint(m, constr[i=1:num_lines], 3*line_stack[i] <= sum{team_lines[k,i]*hitters_lineup[k], k=1:num_hitters})
    # @addConstraint(m, sum{line_stack[i], i=1:num_lines} >= 1)


    # Must have at least 2 lines with at least two people
    # @defVar(m, line_stack2[i=1:num_lines], Bin)
    # @addConstraint(m, constr[i=1:num_lines], 2*line_stack2[i] <= sum{team_lines[k,i]*hitters_lineup[k], k=1:num_hitters})
    # @addConstraint(m, sum{line_stack2[i], i=1:num_lines} >= 2)

    # Overlap Constraint
    @addConstraint(m, constr[i=1:size(lineups)[2]], sum{lineups[j,i]*hitters_lineup[j], j=1:num_hitters} + sum{lineups[num_hitters+j,i]*pitchers_lineup[j], j=1:num_pitchers} <= num_overlap)



    # Objective
    @setObjective(m, Max, sum{hitters[i,:Projection]*hitters_lineup[i], i=1:num_hitters} + sum{pitchers[i,:Projection]*pitchers_lineup[i], i=1:num_pitchers} )


    # Solve the integer programming problem
    println("Solving Problem...")
    @printf("\n")
    status = solve(m);



    # Puts the output of one lineup into a format that will be used later
    if status==:Optimal
        hitters_lineup_copy = Array(Int64, 0)
        for i=1:num_hitters
            if getValue(hitters_lineup[i]) >= 0.9 && getValue(hitters_lineup[i]) <= 1.1
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(1,1))
            else
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(0,1))
            end
        end
        for i=1:num_pitchers
            if getValue(pitchers_lineup[i]) >= 0.9 && getValue(pitchers_lineup[i]) <= 1.1
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(1,1))
            else
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(0,1))
            end
        end
        return(hitters_lineup_copy)
    end
end


#=
formulation is the type of formulation that you would like to use. Feel free to customize the formulations. In our paper we considered
the Type 4 formulation in great detail, but we have included the code for all of the formulations dicussed in the paper here. For instance,
if you would like to create lineups without stacking, change one_lineup_Type_4 below to one_lineup_no_stacking
=#
formulation = one_lineup_Type_4


function create_lineups(num_lineups, num_overlap, path_hitters, path_pitchers, formulation, path_to_output)
    #=
    num_lineups is an integer that is the number of lineups
    num_overlap is an integer that gives the overlap between each lineup
    path_hitters is a string that gives the path to the hitters csv file
    path_pitchers is a string that gives the path to the pitchers csv file
    formulation is the type of formulation you would like to use (for instance one_lineup_Type_1, one_lineup_Type_2, etc.)
    path_to_output is a string where the final csv file with your lineups will be
    =#


    # Load information for hitters table
    hitters = readtable(path_hitters)

    # Load information for pitchers table
    pitchers = readtable(path_pitchers)

    # Number of hitters
    num_hitters = size(hitters)[1]

    # Number of pitchers
    num_pitchers = size(pitchers)[1]

    # catchers stores the information on which players are catchers
    catchers = Array(Int64, 0)

    # firstbasemen stores the information on which players are firstbasemen
    firstbasemen = Array(Int64, 0)

    # secondbasemen stores the information on which players are secondbasemen
    secondbasemen = Array(Int64, 0)

    # thirdbasemen stores the information on which players are thirdbasemen
    thirdbasemen = Array(Int64, 0)

    # shortstops stores the information on which players are shortstops
    shortstops = Array(Int64, 0)

    # outfielders stores the information on which players are outfielders
    outfielders = Array(Int64, 0)

    # firstbasemencatchers stores the information on which players are outfielders
    firstbasemencatchers = Array(Int64, 0)

    # secondbasemencatchers stores the information on which players are outfielders
    secondbasemencatchers = Array(Int64, 0)

    # thirdbasemencatchers stores the information on which players are outfielders
    thirdbasemencatchers = Array(Int64, 0)

    # shortstopcatchers stores the information on which players are outfielders
    shortstopcatchers = Array(Int64, 0)

    # catcheroutfielders stores the information on which players are outfielders
    catcheroutfielders = Array(Int64, 0)

    # firstsecondbasemen stores the information on which players are outfielders
    firstsecondbasemen = Array(Int64, 0)

    # firstthirdbasemen stores the information on which players are outfielders
    firstthirdbasemen = Array(Int64, 0)

    # firstbasemenshortstops stores the information on which players are outfielders
    firstbasemenshortstops = Array(Int64, 0)

    # firstbasemenoutfielders stores the information on which players are outfielders
    firstbasemenoutfielders = Array(Int64, 0)

    # secondthirdbasemen stores the information on which players are outfielders
    secondthirdbasemen = Array(Int64, 0)

    # secondbasemenshortstops stores the information on which players are outfielders
    secondbasemenshortstops = Array(Int64, 0)

    # secondbasemenoutfielders stores the information on which players are outfielders
    secondbasemenoutfielders = Array(Int64, 0)

    # thirdbasemenshortstops stores the information on which players are outfielders
    thirdbasemenshortstops = Array(Int64, 0)

    # thirdbasemenoutfielders stores the information on which players are outfielders
    thirdbasemenoutfielders = Array(Int64, 0)

    # shortstopoutfielders stores the information on which players are outfielders
    shortstopoutfielders = Array(Int64, 0)

    #=
    Process the position information in the hitters file to populate the wingers,
    centers, and defenders with the corresponding correct information
    =#
    for i =1:num_hitters
        if hitters[i,:Position] == "C"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/C"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(1,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/C"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(1,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B/C"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(1,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "SS/C"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(1,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "C/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(1,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/2B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(1,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(1,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(1,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(1,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(1,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(1,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(1,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(1,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(1,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(0,1))
        elseif hitters[i,:Position] == "SS/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
            firstbasemencatchers=vcat(firstbasemencatchers,fill(0,1))
            secondbasemencatchers=vcat(secondbasemencatchers,fill(0,1))
            thirdbasemencatchers=vcat(thirdbasemencatchers,fill(0,1))
            shortstopcatchers=vcat(shortstopcatchers,fill(0,1))
            catcheroutfielders=vcat(catcheroutfielders,fill(0,1))
            firstsecondbasemen=vcat(firstsecondbasemen,fill(0,1))
            firstthirdbasemen=vcat(firstthirdbasemen,fill(0,1))
            firstbasemenshortstops=vcat(firstbasemenshortstops,fill(0,1))
            firstbasemenoutfielders=vcat(firstbasemenoutfielders,fill(0,1))
            secondthirdbasemen=vcat(secondthirdbasemen,fill(0,1))
            secondbasemenshortstops=vcat(secondbasemenshortstops,fill(0,1))
            secondbasemenoutfielders=vcat(secondbasemenoutfielders,fill(0,1))
            thirdbasemenshortstops=vcat(thirdbasemenshortstops,fill(0,1))
            thirdbasemenoutfielders=vcat(thirdbasemenoutfielders,fill(0,1))
            shortstopoutfielders=vcat(shortstopoutfielders,fill(1,1))
        end
    end


    # A forward is either a center or a winger
    forwards = catchers+firstbasemen+secondbasemen+thirdbasemen+shortstops+outfielders+firstbasemencatchers+secondbasemencatchers+thirdbasemencatchers+shortstopcatchers+catcheroutfielders+firstsecondbasemen+firstthirdbasemen+firstbasemenshortstops+firstbasemenoutfielders+secondthirdbasemen+secondbasemenshortstops+secondbasemenoutfielders+thirdbasemenshortstops+thirdbasemenoutfielders+shortstopoutfielders



    # Create team indicators from the information in the hitters file
    teams = unique(hitters[:Team])

    # Total number of teams
    num_teams = size(teams)[1]

    # player_info stores information on which team each player is on
    player_info = zeros(Int, size(teams)[1])

    # Populate player_info with the corresponding information
    for j=1:size(teams)[1]
        if hitters[1, :Team] == teams[j]
            player_info[j] =1
        end
    end
    hitters_teams = player_info'


    for i=2:num_hitters
        player_info = zeros(Int, size(teams)[1])
        for j=1:size(teams)[1]
            if hitters[i, :Team] == teams[j]
                player_info[j] =1
            end
        end
        hitters_teams = vcat(hitters_teams, player_info')
    end



    # Create pitcher identifiers so you know who they are playing
    opponents = pitchers[:Opponent]
    pitcher_teams = pitchers[:Team]
    pitcher_opponents=[]
    for num = 1:size(teams)[1]
        if opponents[1] == teams[num]
            pitcher_opponents = hitters_teams[:, num]
        end
    end
    for num = 2:size(opponents)[1]
        for num_2 = 1:size(teams)[1]
            if opponents[num] == teams[num_2]
                pitcher_opponents = hcat(pitcher_opponents, hitters_teams[:,num_2])
            end
        end
    end




    # Create line indicators so you know which players are on which lines
    L1_info = zeros(Int, num_hitters)
    L2_info = zeros(Int, num_hitters)
    L3_info = zeros(Int, num_hitters)
    L4_info = zeros(Int, num_hitters)
    for num=1:size(hitters)[1]
        if hitters[:Team][num] == teams[1]
            if hitters[:Line][num] == "1"
                L1_info[num] = 1
            elseif hitters[:Line][num] == "2"
                L2_info[num] = 1
            elseif hitters[:Line][num] == "3"
                L3_info[num] = 1
            elseif hitters[:Line][num] == "4"
                L4_info[num] = 1
            end
        end
    end
    team_lines = hcat(L1_info, L2_info, L3_info, L4_info)


    for num2 = 2:size(teams)[1]
        L1_info = zeros(Int, num_hitters)
        L2_info = zeros(Int, num_hitters)
        L3_info = zeros(Int, num_hitters)
        L4_info = zeros(Int, num_hitters)
        for num=1:size(hitters)[1]
            if hitters[:Team][num] == teams[num2]
                if hitters[:Line][num] == "1"
                    L1_info[num] = 1
                elseif hitters[:Line][num] == "2"
                    L2_info[num] = 1
                elseif hitters[:Line][num] == "3"
                    L3_info[num] = 1
                elseif hitters[:Line][num] == "4"
                    L4_info[num] = 1
                end
            end
        end
        team_lines = hcat(team_lines, L1_info, L2_info, L3_info, L4_info)
    end
    num_lines = size(team_lines)[2]


    # Lineups using formulation as the stacking type
    the_lineup= formulation(hitters, pitchers, hcat(zeros(Int, num_hitters + num_pitchers), zeros(Int, num_hitters + num_pitchers)), num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, firstbasemencatchers, secondbasemencatchers, thirdbasemencatchers, shortstopcatchers, catcheroutfielders, firstsecondbasemen, firstthirdbasemen, firstbasemenshortstops, firstbasemenoutfielders, secondthirdbasemen, secondbasemenshortstops, secondbasemenoutfielders, thirdbasemenshortstops, thirdbasemenoutfielders, shortstopoutfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
    the_lineup2 = formulation(hitters, pitchers, hcat(the_lineup, zeros(Int, num_hitters + num_pitchers)), num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, firstbasemencatchers, secondbasemencatchers, thirdbasemencatchers, shortstopcatchers, catcheroutfielders, firstsecondbasemen, firstthirdbasemen, firstbasemenshortstops, firstbasemenoutfielders, secondthirdbasemen, secondbasemenshortstops, secondbasemenoutfielders, thirdbasemenshortstops, thirdbasemenoutfielders, shortstopoutfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
    tracer = hcat(the_lineup, the_lineup2)
    for i=1:(num_lineups-2)
        try
            thelineup=formulation(hitters, pitchers, tracer, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, firstbasemencatchers, secondbasemencatchers, thirdbasemencatchers, shortstopcatchers, catcheroutfielders, firstsecondbasemen, firstthirdbasemen, firstbasemenshortstops, firstbasemenoutfielders, secondthirdbasemen, secondbasemenshortstops, secondbasemenoutfielders, thirdbasemenshortstops, thirdbasemenoutfielders, shortstopoutfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
            tracer = hcat(tracer,thelineup)
        catch
            break
        end
    end


    # Create the output csv file
    lineup2 = ""
    for j = 1:size(tracer)[2]
        lineup = ["" "" "" "" "" "" "" "" "" ""]
        for i =1:num_hitters
            if tracer[i,j] == 1
                if catchers[i]==1
                    lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                elseif firstbasemen[i] == 1
                    lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                elseif secondbasemen[i] == 1
                    lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                elseif thirdbasemen[i] == 1
                    lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                elseif shortstops[i] == 1
                    lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                elseif outfielders[i] == 1
                    if lineup[6] == ""
                        lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                    elseif lineup[7] ==""
                        lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                    elseif lineup[8] == ""
                        lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                    end
                end
            end
        end
        for i =1:num_pitchers
            if tracer[num_hitters+i,j] == 1
                if lineup[9] ==""
                    lineup[9] = string(pitchers[i,1], " ", pitchers[i,2])
                elseif lineup[10] == ""
                    lineup[10] = string(pitchers[i,1], " ", pitchers[i,2])
                end
            end
        end
        for name in lineup
            lineup2 = string(lineup2, name, ",")
        end
        lineup2 = chop(lineup2)
        lineup2 = string(lineup2, """

        """)
    end
    outfile = open(path_to_output, "w")
    write(outfile, lineup2)
    close(outfile)
end




# Running the code
create_lineups(num_lineups, num_overlap, path_hitters, path_pitchers, formulation, path_to_output)
