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
num_lineups = 3

# num_overlap is the maximum overlap of players between the lineups that you create
num_overlap = 7

# path_hitters is a string that gives the path to the csv file with the hitters information (see example file for suggested format)
path_hitters = "example_hitters4.csv"

# path_pitchers is a string that gives the path to the csv file with the pitchers information (see example file for suggested format)
path_pitchers = "example_pitchers4.csv"

# path_to_output is a string that gives the path to the csv file that will give the outputted results
path_to_output= "output.csv"

path_to_new_hitters= "output.csv"


# This is a function that creates one lineup using the Type 4 formulation from the paper
function one_lineup_Type_4(hitters, pitchers, lineups, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_line)
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
    @addConstraint(m, sum{catchers[i]*hitters_lineup[i], i=1:num_hitters} >= 1)

    # 1 1B
    @addConstraint(m, sum{firstbasemen[i]*hitters_lineup[i], i=1:num_hitters} >= 1)

    # 1 2B
    @addConstraint(m, sum{secondbasemen[i]*hitters_lineup[i], i=1:num_hitters} >= 1)

    # 1 3B
    @addConstraint(m, sum{thirdbasemen[i]*hitters_lineup[i], i=1:num_hitters} >= 1)

    # 1 SS
    @addConstraint(m, sum{shortstops[i]*hitters_lineup[i], i=1:num_hitters} >= 1)

    # 3 OF
    @addConstraint(m, sum{outfielders[i]*hitters_lineup[i], i=1:num_hitters} >= 3)



    # Financial Constraint
    @addConstraint(m, sum{hitters[i,:Salary]*hitters_lineup[i], i=1:num_hitters} + sum{pitchers[i,:Salary]*pitchers_lineup[i], i=1:num_pitchers} <= 50000)


    # exactly 3 different teams for the 8 hitters constraint
    @defVar(m, used_team[i=1:num_teams], Bin)
    @addConstraint(m, constr[i=1:num_teams], used_team[i] <= sum{hitters_teams[t, i]*hitters_lineup[t], t=1:num_hitters})
    @addConstraint(m, constr[i=1:num_teams], sum{hitters_teams[t, i]*hitters_lineup[t], t=1:num_hitters} <= 8*used_team[i])
    @addConstraint(m, sum{used_team[i], i=1:num_teams} == 2)


    # No pitchers going against hitters
    #@addConstraint(m, constr[i=1:num_pitchers], 8*pitchers_lineup[i] + sum{pitcher_opponents[k, i]*hitters_lineup[k], k=1:num_hitters}<=8)


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
        hitters_positions = Array(Int64, 0)
        for i=1:num_hitters
            if getValue(hitters_lineup[i]) >= 0.9 && getValue(hitters_lineup[i]) <= 1.1
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(1,1))
            else
                hitters_lineup_copy = vcat(hitters_lineup_copy, fill(0,1))
                hitters_positons = vcat(hitters_lineup_copy, fill(0,1))
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
        elseif hitters[i,:Position] == "1B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
        elseif hitters[i,:Position] == "1B/C"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/C"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B/C"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "SS/C"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "C/OF"
            catchers=vcat(catchers,fill(1,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
        elseif hitters[i,:Position] == "1B/2B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "1B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(1,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
        elseif hitters[i,:Position] == "2B/3B"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "2B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(1,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
        elseif hitters[i,:Position] == "3B/SS"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(0,1))
        elseif hitters[i,:Position] == "3B/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(1,1))
            shortstops=vcat(shortstops,fill(0,1))
            outfielders=vcat(outfielders,fill(1,1))
        elseif hitters[i,:Position] == "SS/OF"
            catchers=vcat(catchers,fill(0,1))
            firstbasemen=vcat(firstbasemen,fill(0,1))
            secondbasemen=vcat(secondbasemen,fill(0,1))
            thirdbasemen=vcat(thirdbasemen,fill(0,1))
            shortstops=vcat(shortstops,fill(1,1))
            outfielders=vcat(outfielders,fill(1,1))
        end
    end


    # A forward is either a center or a winger
    forwards = catchers+firstbasemen+secondbasemen+thirdbasemen+shortstops+outfielders

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
        hitters_teams = vcat(hitters_teams, player_info') #identifies which players are on what teams. Array will be as long as there are many teams
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
    lineupsA=hcat(zeros(Int, num_hitters + num_pitchers), zeros(Int, num_hitters + num_pitchers))
    the_lineup= formulation(hitters, pitchers, lineupsA, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
    lineupsB=hcat(the_lineup, zeros(Int, num_hitters + num_pitchers))
    the_lineup1 = formulation(hitters, pitchers, lineupsB, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
    tracer = hcat(the_lineup, the_lineup1)
    for i=1:(num_lineups-2)
        try
            thelineup=formulation(hitters, pitchers, tracer, num_overlap, num_hitters, num_pitchers, catchers, firstbasemen, secondbasemen, thirdbasemen, shortstops, outfielders, num_teams, hitters_teams, pitcher_opponents, team_lines, num_lines)
            tracer = hcat(tracer,thelineup)
        catch
            break
        end
    end


catchers_in_lineup = Array(Int,0)
firstbasemen_in_lineup = Array(Int,0)
secondbasemen_in_lineup = Array(Int,0)
thirdbasemen_in_lineup = Array(Int,0)
shortstops_in_lineup = Array(Int,0)
outfielders_in_lineup = Array(Int,0)
hitter_num_lineup = Array(Int,0)

for j = 1:size(tracer)[2]
    for i =1:num_hitters
        if tracer[i,j] == 1
            hitter_num_lineup=vcat(hitter_num_lineup,fill(i,1))
            if hitters[i,:Position] == "C"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "1B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "2B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "3B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "SS"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            elseif hitters[i,:Position] == "1B/C"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "2B/C"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "3B/C"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "SS/C"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "C/OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(1,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            elseif hitters[i,:Position] == "1B/2B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "1B/3B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "1B/SS"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "1B/OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(1,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            elseif hitters[i,:Position] == "2B/3B"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "2B/SS"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "2B/OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(1,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            elseif hitters[i,:Position] == "3B/SS"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(0,1))
            elseif hitters[i,:Position] == "3B/OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(1,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(0,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            elseif hitters[i,:Position] == "SS/OF"
                catchers_in_lineup=vcat(catchers_in_lineup,fill(0,1))
                firstbasemen_in_lineup=vcat(firstbasemen_in_lineup,fill(0,1))
                secondbasemen_in_lineup=vcat(secondbasemen_in_lineup,fill(0,1))
                thirdbasemen_in_lineup=vcat(thirdbasemen_in_lineup,fill(0,1))
                shortstops_in_lineup=vcat(shortstops_in_lineup,fill(1,1))
                outfielders_in_lineup=vcat(outfielders_in_lineup,fill(1,1))
            end
        end
    end
end

println(tracer)

hitter_matrix = transpose(reshape(hitter_num_lineup, (8,:)))
catchers_matrix = transpose(reshape(catchers_in_lineup, (8,:)))
firstbasemen_matrix = transpose(reshape(firstbasemen_in_lineup, (8,:)))
secondbasemen_matrix = transpose(reshape(secondbasemen_in_lineup, (8,:)))
thirdbasemen_matrix = transpose(reshape(thirdbasemen_in_lineup, (8,:)))
shortstops_matrix = transpose(reshape(shortstops_in_lineup, (8,:)))
outfielders_matrix = transpose(reshape(outfielders_in_lineup, (8,:)))

println(hitter_matrix)
println(catchers_matrix)
println(firstbasemen_matrix)
println(secondbasemen_matrix)
println(thirdbasemen_matrix)
println(shortstops_matrix)
println(outfielders_matrix)

for j = 1:size(tracer)[2]
    catchers_final = ["" "" "" "" "" "" "" ""]
    firstbasmen_final = ["" "" "" "" "" "" "" ""]
    secondbasemen_final = ["" "" "" "" "" "" "" ""]
    thirdbasemen_final = ["" "" "" "" "" "" "" ""]
    shortstops_final = ["" "" "" "" "" "" "" ""]
    outfielders_final = ["" "" "" "" "" "" "" ""]
    for i =1:num_hitters
        if tracer[i,j] == 1
            if catchers[i] == 1 && (hitters[i,:Position] == "C" || sum(catchers_matrix[j,:]) == 1)
                catchers_final[1] = i
            elseif firstbasemen[i] == 1 && (hitters[i,:Position] == "1B" || sum(firstbasemen_matrix[j,:]) == 1)
                firstbasmen_final[2] = "1"
            elseif secondbasemen[i] == 1 && (hitters[i,:Position] == "2B" || sum(secondbasemen_matrix[j,:]) == 1)
                secondbasemen_final[3] = "1"
            elseif thirdbasemen[i] == 1 && (hitters[i,:Position] == "3B" || sum(thirdbasemen_matrix[j,:]) == 1)
                thirdbasemen_final[4] = "1"
            elseif shortstops[i] == 1 && (hitters[i,:Position] == "SS" || sum(shortstops_matrix[j,:]) == 1)
                shortstops_final[5] = "1"
            elseif outfielders[i] == 1 && (hitters[i,:Position] == "OF" || sum(outfielders_matrix[j,:]) == 3)
                if outfielders_final[6] == ""
                    outfielders_final[6] = "1"
                elseif outfielders_final[7] ==""
                    outfielders_final[7] = "1"
                elseif outfielders_final[8] == ""
                    outfielders_final[8] = "1"
                end
            end
        end
    end
    println(catchers_final)
    #println(firstbasmen_final)
    #println(secondbasemen_final)
    #println(thirdbasemen_final)
    #println(shortstops_final)
    #println(outfielders_final)
end



    # Create the output csv file
    lineup2 = ""
    for j = 1:size(tracer)[2]
        lineup = ["" "" "" "" "" "" "" "" "" ""]
        for i =1:num_hitters
            if tracer[i,j] == 1
                if catchers[i] == 1 && (hitters[i,:Position] == "C" || sum(catchers_matrix[j,:]) == 1)
                    lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                elseif firstbasemen[i] == 1 && (hitters[i,:Position] == "1B" || sum(firstbasemen_matrix[j,:]) == 1)
                    lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                elseif secondbasemen[i] == 1 && (hitters[i,:Position] == "2B" || sum(secondbasemen_matrix[j,:]) == 1)
                    lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                elseif thirdbasemen[i] == 1 && (hitters[i,:Position] == "3B" || sum(thirdbasemen_matrix[j,:]) == 1)
                    lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                elseif shortstops[i] == 1 && (hitters[i,:Position] == "SS" || sum(shortstops_matrix[j,:]) == 1)
                    lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                elseif outfielders[i] == 1 && (hitters[i,:Position] == "OF" || sum(outfielders_matrix[j,:]) == 3)
                    if lineup[6] == ""
                        lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                    elseif lineup[7] ==""
                        lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                    elseif lineup[8] == ""
                        lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                    end
                else
                    leftovers = i
                    println(leftovers)
                    println(".")
                    if hitters[i,:Position] == "1B/C"
                        if lineup[1] != ""
                            lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[2] != ""
                            lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "2B/C"
                        if lineup[1] != ""
                            lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[3] != ""
                            lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "3B/C"
                        if lineup[1] != ""
                            lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[4] != ""
                            lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "SS/C"
                        if lineup[1] != ""
                            lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[5] != ""
                            lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "C/OF"
                        if lineup[8] != ""
                            lineup[1] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[1] != ""
                            if lineup[6] == ""
                                lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[7] ==""
                                lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[8] == ""
                                lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                            end
                        end
                    end
                    if hitters[i,:Position] == "1B/2B"
                        if lineup[2]!=""
                            println(true)
                            lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[3] !=""
                            lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                            println(i)
                        end
                    end
                    if hitters[i,:Position] == "1B/3B"
                        if lineup[2] != ""
                            lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[4] != ""
                            lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "1B/SS"
                        if lineup[2] != ""
                            lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[5] != ""
                            lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "1B/OF"
                        if lineup[8] != ""
                            lineup[2] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[2] != ""
                            if lineup[6] == ""
                                lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[7] ==""
                                lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[8] == ""
                                lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                            end
                        end
                    end
                    if hitters[i,:Position] == "2B/3B"
                        if lineup[3] != ""
                            lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[4] != ""
                            lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "2B/SS"
                        if lineup[3] != ""
                            lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[5] != ""
                            lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "2B/OF"
                        if lineup[8] != ""
                            lineup[3] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[3] != ""
                            if lineup[6] == ""
                                lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[7] ==""
                                lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[8] == ""
                                lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                            end
                        end
                    end
                    if hitters[i,:Position] == "3B/SS"
                        if lineup[4] != ""
                            lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[5] != ""
                            lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                        end
                    end
                    if hitters[i,:Position] == "3B/OF"
                        if lineup[8] != ""
                            lineup[4] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[4] != ""
                            if lineup[6] == ""
                                lineup[6] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[7] ==""
                                lineup[7] = string(hitters[i,1], " ", hitters[i,2])
                            elseif lineup[8] == ""
                                lineup[8] = string(hitters[i,1], " ", hitters[i,2])
                            end
                        end
                    end
                    if hitters[i,:Position] == "SS/OF"
                        if lineup[8] != ""
                            lineup[5] = string(hitters[i,1], " ", hitters[i,2])
                        elseif lineup[5] != ""
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
