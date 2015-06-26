using Simulator
using Base.Test
using Distributions
using PyCall

@pyimport pyconsensus

sim = Simulation()
include("defaults_liar.jl")

sim.VERBOSE = false

sim.TESTING = true
sim.TEST_REPORTERS = ["true", "liar", "true", "liar", "liar", "liar"]
sim.TEST_INIT_REP = ones(length(sim.TEST_REPORTERS))
sim.TEST_CORRECT_ANSWERS = [ 2.0; 2.0; 1.0; 1.0 ]
sim.TEST_REPORTS = [ 2.0 2.0 1.0 1.0 ;
                     2.0 1.0 1.0 1.0 ;
                     2.0 2.0 1.0 1.0 ;
                     2.0 2.0 2.0 1.0 ;
                     1.0 1.0 2.0 2.0 ;
                     1.0 1.0 2.0 2.0 ]
sim.ITERMAX = 1
sim.TIMESTEPS = 1
sim.LIAR_THRESHOLD = 0.7
sim.VARIANCE_THRESHOLD = 0.9
sim.EVENTS = 4
sim.REPORTERS = 6
sim.SCALARS = 0.0
sim.REP_RAND = false
sim.REP_DIST = Pareto(3.0)
sim.BRIDGE = false
sim.ALPHA = 0.1
sim.MAX_COMPONENTS = 5
sim.CONSPIRACY = false
sim.LABELSORT = false
sim.ALGOS = [ "PCA" ]

function test_process_raw_data(sim::Simulation)
    println("  - process_raw_data")
    process_raw_data(sim)
end

function test_reptrack_sums(sim::Simulation)
    println("  - reptrack_sums")
    reptrack_sums(sim)
end

function test_calculate_trajectories(sim::Simulation)
    println("  - calculate_trajectories")
    calculate_trajectories(sim)
end

function test_save_raw_data(sim::Simulation)
    println("  - save_raw_data")
    save_raw_data(sim)
end

function test_init_repbox(sim::Simulation)
    println("  - init_repbox")
    (repbox, repdelta) = init_repbox(sim)
end

function test_init_raw_data(sim::Simulation)
    println("  - init_raw_data")
    raw_data = init_raw_data(sim)
    @test raw_data["sim"] == sim
    for algo in sim.ALGOS
        @test haskey(raw_data, algo)
        for m in sim.METRICS
            @test haskey(raw_data[algo], m)
            @test haskey(raw_data[algo][m], sim.TIMESTEPS)
            @test isa(raw_data[algo][m][sim.TIMESTEPS], Vector{Float64})
        end
    end
end

function test_compute_metrics(sim::Simulation)
    println("  - compute_metrics")
    trues = find(sim.TEST_REPORTERS .== "true")
    distorts = find(sim.TEST_REPORTERS .== "distort")
    liars = find(sim.TEST_REPORTERS .== "liar")
    num_trues = length(trues)
    num_distorts = length(distorts)
    num_liars = length(liars)
    reporters = (Symbol => Any)[
        :reporters => sim.TEST_REPORTERS,
        :trues => trues,
        :distorts => distorts,
        :liars => liars,
        :num_trues => num_trues,
        :num_distorts => num_distorts,
        :num_liars => num_liars,
        :honesty => nothing,
        :aux => nothing,
    ]
    data = (Symbol => Any)[
        :reporters => reporters[:reporters],
        :honesty => reporters[:honesty],
        :correct_answers => sim.TEST_CORRECT_ANSWERS,
        :distorts => reporters[:distorts],
        :reports => sim.TEST_REPORTS,
        :aux => nothing,
        :num_distorts => reporters[:num_distorts],
        :num_trues => reporters[:num_trues],
        :num_liars => reporters[:num_liars],
        :trues => reporters[:trues],
        :liars => reporters[:liars],
    ]
    results = pyconsensus.Oracle(
        reports=sim.TEST_REPORTS,
        reputation=sim.TEST_INIT_REP,
        alpha=sim.ALPHA,
        variance_threshold=sim.VARIANCE_THRESHOLD,
        max_components=sim.MAX_COMPONENTS,
        algorithm="PCA",
    )[:consensus]()
    updated_rep = convert(Vector{Float64}, results["agents"]["reporter_bonus"])
    metrics = compute_metrics(sim, data, results["events"]["outcomes_final"], sim.TEST_INIT_REP, updated_rep)
    @test metrics == (Symbol => Float64)[
        :spearman    => 1.0,
        :true_rep    => 0.35647513922553575,
        :MCC         => 0.0,
        :correct     => 0.5,
        :precision   => 0.6666666666666666,
        :fallout     => 1.0,
        :gap         => -0.2870497215489285,
        :beats       => 0.0,
        :gini        => 0.037650092817023584,
        :liars_bonus => -0.06942541767660715,
        :liar_rep    => 0.6435248607744642,
        :sensitivity => 1.0,
    ]
end

function test_consensus(sim::Simulation)
    println("  - consensus")
    results = pyconsensus.Oracle(
        reports=sim.TEST_REPORTS,
        reputation=sim.TEST_INIT_REP,
        alpha=sim.ALPHA,
        variance_threshold=sim.VARIANCE_THRESHOLD,
        max_components=sim.MAX_COMPONENTS,
        algorithm="PCA",
    )[:consensus]()
    @test round(results["agents"]["reporter_bonus"], 6) == [ 0.178238 ;
                                                             0.171762 ;
                                                             0.178238 ;
                                                             0.171762 ;
                                                             0.15     ;
                                                             0.15     ]

end

function test_simulate(sim::Simulation)
    simulate(sim)
end

function test_exclude(sim::Simulation)
    exclude(sim, (:MCC, :sensitivity, :fallout, :precision))
end

function test_preprocess(sim::Simulation)
    sim = preprocess(sim)
end

function test_run_simulations(sim::Simulation)
    run_simulations(sim)
end

# test_run_simulations(sim)
# test_preprocess(sim)
# test_exclude(sim)
# test_simulate(sim)
test_consensus(sim)
test_compute_metrics(sim)
test_init_raw_data(sim)
# test_init_repbox(sim)
# test_save_raw_data(sim)
# test_calculate_trajectories(sim)
# test_reptrack_sums(sim)
# test_process_raw_data(sim)