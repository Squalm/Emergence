using Plots

steps = 1200
dims = 100
ants = 150
ph = zeros(Float64, dims, dims)
ant = fill(trunc(Int, dims/2), ants, 2)
prev_ant = fill(trunc(Int, dims/2), ants, 2)
holding_food = fill(false, ants)
food = zeros(Float64, dims, dims)
space = fill(true, dims, dims)
hive = [trunc(Int, dims/2), trunc(Int, dims/2)]

food_cache = [zeros(Float64, dims, dims) for _ in 1:steps]
ph_cache = [zeros(Float64, dims, dims) for _ in 1:steps]
ant_cache = [zeros(Float64, dims, dims) for _ in 1:steps]

# Patches of food
food[35:40, 35:40] .= 1.0
food[20:30, 80:90] .= 1.0
food[60:65, 60:65] .= 1.0

for i in 1:steps

    global go = ([0 -1] => -Inf, [0 1] => -Inf, [-1 0] => -Inf, [1 0] => -Inf)
    global prev_ant

    # reduce all pheremone levels
    for x in 1:length(ph)
        if x % 100 == 0
            ph[x] = max(ph[x] - 0.1, 0.0)
        end # if
    end # for

    _ant_alt = deepcopy(ant)

    for a in range(1,length(eachrow(ant)))

        # If next to food and not holding food, pick up food
        found_food = false
        if !holding_food[a]
            for d in go
                if get(food, (ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]), 0.0) > 0.0
                    holding_food[a] = true
                    food[ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]] -= 0.2
                    found_food = true
                    break
                end # if
            end # for
        end # if

        if holding_food[a]
            # If next to hive, drop food
            for d in go
                if [ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]] == hive
                    holding_food[a] = false
                    break
                end # If
                # Lay pheremones around
                if get(space, (ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]), false)
                    ph[ant[a,1] + d[1][1], ant[a,2] + d[1][2]] += 0.1
                end # if
            end # If

            # Lay pheremones on current squiare
            ph[ant[a, 1], ant[a, 2]] = min(ph[ant[a, 1], ant[a, 2]] + 0.1, 1.0)
            # If holding food, move to hive
            #dir_home = ((ant[a, 1] - hive[1])^2 + (ant[a, 2] - hive[2])^2)^(1/2)
            # deeply sad way of getting home
            if ant[a, 1] != hive[1] && 
                    !([ant[a, 1] + sign(hive[1] - ant[a, 1]), ant[a, 2]] in collect(eachrow(ant)))
                ant[a, 1] += sign(hive[1] - ant[a, 1])
            elseif ant[a, 2] != hive[2] && 
                    !([ant[a, 1], ant[a, 2] + sign(hive[2] - ant[a, 2])] in collect(eachrow(ant)))
                ant[a, 2] += sign(hive[2] - ant[a, 2])
            end # if
        else

            # look around at pheremone levels
            go = [d[1] => get(ph, (ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]), -Inf) for d in go]
            # move in that direction
            sorted = all([d[2] <= 0.0 for d in go]) ? sort(go, by=x -> rand()) : sort(go, by=x -> x[2])
            for d in sorted
                global prev_ant
                if ant[a, 1] + d[1][1] < dims && ant[a, 1] + d[1][1] > 0 &&
                        ant[a, 2] + d[1][2] < dims && ant[a, 2] + d[1][2] > 0 && 
                        !([ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]] in collect(eachrow(ant))) &&
                        collect(eachrow(prev_ant))[a] != [ant[a, 1] + d[1][1], ant[a, 2] + d[1][2]]
                    ant[a, 1] += d[1][1]
                    ant[a, 2] += d[1][2]
                    break
                end # if
            end # for
        end # if
    end # for

    prev_ant = deepcopy(_ant_alt)
    food_cache[i] = deepcopy(food)
    ph_cache[i] = deepcopy(ph)
    for a in eachrow(ant)
        ant_cache[i][a[1], a[2]] = true
    end # for

end # for

println("Rendering...")
anim = @animate for i = 1:steps
    heatmap(ant_cache[i], clim=(0,1))
end
 
gif(anim, "ants.gif", fps = 20)

anim1 = @animate for i = 1:steps
    heatmap(ph_cache[i], clim=(0,1))
end

gif(anim1, "ph.gif", fps = 20)

anim2 = @animate for i in 1:steps
    heatmap(food_cache[i], clim=(0,1))
end # for

gif(anim2, "food.gif", fps= 60)