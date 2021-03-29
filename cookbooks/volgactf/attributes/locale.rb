default['locale']['lang'] = 'en_US.UTF-8'
default['locale']['lc_env'] = %w(
  LC_ADDRESS
  LC_COLLATE
  LC_CTYPE
  LC_IDENTIFICATION
  LC_MEASUREMENT
  LC_MESSAGES
  LC_MONETARY
  LC_NAME
  LC_NUMERIC
  LC_PAPER
  LC_TELEPHONE
  LC_TIME
).to_h { |x| [x, 'en_US.UTF-8'] }
