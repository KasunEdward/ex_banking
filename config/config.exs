import Config

config :ex_banking,
       max_ops_count: 10

config :logger,
       :console,
       format: "$date,$time,$message\n",
       level: :debug

