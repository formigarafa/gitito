desc 'cruise control continuous integration'
task cruise: [:spec, 'metrics:all']

# MetricFu::Configuration.run do |config|
#   # config.rcov[:test_files] = ['spec/**/*_spec.rb']
#   # config.rcov[:rcov_opts] << "-Ispec" # Needed to find spec_helper
#
#   config.metrics  = [:stats, :flay, :reek, :roodi, :hotspots]
#   # config.metrics -= [:rcov]
#   # config.metrics  = [:saikuro, :stats, :flay, :reek, :roodi, :rcov, :hotspots]
#   # :saikuro, :churn, :flog : failing
#
#   # config.graphs   = [:flay, :reek, :roodi, :rcov, :rails_best_practices]
#
#     # AVAILABLE_GRAPHS = [:flog, :flay, :reek, :roodi, :rcov, :rails_best_practices]
#
#
#   # config.rcov = {
#   #   :environment => 'test',
#   #   :test_files => [
#   #     'test/**/*_test.rb',
#   #     'spec/**/*_spec.rb'
#   #   ],
#   #   :rcov_opts => [
#   #     "--sort coverage",
#   #     "--no-html",
#   #     "--text-coverage",
#   #     "--no-color",
#   #     "--profile",
#   #     "--rails",
#   #     "--exclude /gems/,/Library/,/usr/,spec"
#   #   ],
#   #   :external => nil
#   # }
# end
