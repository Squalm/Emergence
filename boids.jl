using Plots
using ProgressBars

"""
Returns an array of all the boids within a radius r about centre c.
"""
function nearby(c, boids, r)
    return [(b, sqrt((c[1] - b[1])^2 + (c[2] - b[2])^2 )) for b in boids if sqrt((b[1] % w - c[1])^2 + (b[2] - c[2])^2) <= r]
end

function keepin(boid, w, h, edgeforce = 0.05)    
    margin = 20

    if boid[1] < margin
        boid[3] += edgeforce * exp(-boid[1])
    elseif boid[1] > w-margin
        boid[3] -= edgeforce * exp(boid[1] - w)
    end # if

    if boid[2] < margin
        boid[4] += edgeforce * exp(-boid[2])
    elseif boid[2] > h-margin
        boid[4] -= edgeforce * exp(boid[2] - w)
    end # if

    return boid

end

function limit(boid)

    speedlimit = 10
    
    speed = sqrt(boid[3]^2 + boid[4]^2)

    if speed > speedlimit
        boid[3] = boid[3] * speedlimit/speed
        boid[4] = boid[4] * speedlimit/speed
    end # if

    return boid
    
end

function separation(boid::Vector{Float64}, boidpush = 3.0)
    force = [0.0, 0.0]

    near = [x[1] for x in nearby(boid[1:2], boids, vision) if x[2] <= vision]
    for b in near
        if b != boid
            # 1/x
            #force[1] += 1/(b[1] - boid[1])
            #force[2] += 1/(b[2] - boid[2])
            # sigmoid derivative
            force[1] += 1/(1 + exp(-b[1]+boid[1])) * 
                (1 - 1/(1 + exp(-b[1]+boid[1]))) * 
                (boid[1] - b[1]) * sign(b[1] - boid[1])
            force[2] += 1/(1 + exp(-b[2]+boid[2])) * 
                (1 - 1/(1 + exp(-b[2]+boid[2]))) * 
                (boid[2] - b[2]) * sign(b[2] - boid[2])
        end # if
    end # for

    boid[3] += force[1] * boidpush
    boid[4] += force[2] * boidpush

    return boid

end

function cohesion(boid::Vector{Float64}, centerpull = 0.05)

    center = Float64[0.0, 0.0]
    near = [x[1] for x in nearby(boid[1:2], boids, vision) if x[2] <= vision]
    for b in near
        center[1] += b[1]
        center[2] += b[2]
    end # for

    if length(near) > 0
        center ./= length(near)
        boid[3] += (center[1] - boid[1]) * centerpull
        boid[4] += (center[2] - boid[2]) * centerpull
    end # if

    return boid

end

function alignment(boid::Vector{Float64}, turnFactor = 0.05)

    avg = [0.0, 0.0]

    near = [x[1] for x in nearby(boid[1:2], boids, vision) if x[2] <= vision]
    for b in near

        avg[1] += b[3]
        avg[2] += b[4]

    end # for

    if length(near) > 0

        avg ./= length(near)

        boid[3] += (avg[1] - boid[3]) * turnFactor
        boid[4] += (avg[2] - boid[4]) * turnFactor

    end # if

    return boid

end

function update(boid::Vector{Float64}, delta)
    return [boid[1] + boid[3] * delta, boid[2] + boid[4] * delta, boid[3], boid[4]]
end

w = 200
h = 200
steps = 300
vision = 10
delta = 1.0
n = 100

boids = Vector{Float64}[[(rand()-0.5)*w*2+w/2, (rand()-0.5)*h*2+h/2, (rand()-0.5) * 5, (rand()-0.5) * 5] for i in 1:n] # x,y,dx,dy 

anim = @animate for _ in ProgressBar(1:steps)

    global boids

    # Separation, alignment, cohesion

    boids = cohesion.(boids)
    boids = separation.(boids)
    boids = alignment.(boids)
    boids = keepin.(boids, w, h)
    boids = limit.(boids)
        
    boids = update.(boids, delta)

    x = [boid[1] for boid in boids]
    y = [boid[2] for boid in boids]

    scatter(x, y, xlims=(-w/2, w * 3/2), ylims=(-h/2, h * 3/2))

end # for

gif(anim, "boids.gif", fps = 20)