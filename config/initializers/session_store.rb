# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_raki_session',
  :secret      => 'c1cf9dd524dc2c2067f4721a4f0fb9d297de021ef5cd140b451169f0dc1e872312ca7adb946a0d3687c35e238a0be6f4eae8933bb2be14a57be87111fa8d35e3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
