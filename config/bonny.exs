import Config

config :bonny,
  # TODO: remove when bonny upgraded to 1.1.2
  operator_name: "kompost"

# Labels to apply to the operator's resources.
# labels: %{
#   "k8s-app" => "<%= assigns[:operator_name] %>"
# },

# Operator deployment resources. These are the defaults.
# resources: <%= inspect(assigns[:resources]) %>,

# manifest_override_callback: &Mix.Tasks.Bonny.Gen.Manifest.<%= assigns[:app_name] %>Customizer.override/1
