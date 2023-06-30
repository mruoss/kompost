import Config

config :bonny,
  # TODO: remove when bonny upgraded to 1.1.2
  operator_name: "kompost",
  service_account_name: "kompost",
  manifest_override_callback: &Mix.Tasks.Bonny.Gen.Manifest.KompostCustomizer.override/1

# Labels to apply to the operator's resources.
# labels: %{
#   "k8s-app" => "<%= assigns[:operator_name] %>"
# },

# Operator deployment resources. These are the defaults.
# resources: <%= inspect(assigns[:resources]) %>,
