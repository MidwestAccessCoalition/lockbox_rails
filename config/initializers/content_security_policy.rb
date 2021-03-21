# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Headers that are not set below:
# * upgrade-insecure-requests, because it is not useful if block_all_mixed_content
#   is set (see https://developers.google.com/web/fundamentals/security/prevent-mixed-content/fixing-mixed-content)
# * media_src and manifest_src, because they will default to default_src, and
#   the intended values are`the same

Rails.application.config.content_security_policy do |policy|
  policy.base_uri        :self
  policy.default_src     :self
  policy.font_src        :self, 'https://fonts.gstatic.com', 'https://demo-lockbox.herokuapp.com'
  policy.form_action     :self
  policy.frame_ancestors :none
  policy.img_src         :self, 'https://*.amazonaws.com', 'https://i.pinimg.com/'
  policy.object_src      :none
  policy.script_src      :self
  policy.style_src       :self, :unsafe_inline, 'https://fonts.googleapis.com'
  policy.worker_src      :self
  # If you are using webpack-dev-server then specify webpack-dev-server host
  policy.connect_src     :self, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

  policy.block_all_mixed_content true
  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
Rails.application.config.content_security_policy_report_only = false
